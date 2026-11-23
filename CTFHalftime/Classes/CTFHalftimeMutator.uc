//==============================================================================
//  CTF Halftime: at half the time limit, play stops for a countdown, then the
//  teams switch sides and the second half starts from a fresh level, as at the
//  start of the match, so neither side starts it ahead.
//  - The freeze is Assault's end-of-round state: each player and bot's
//    RoundHasEnded (Controller state RoundEnded) turns its pawn off where it
//    stands (no movement, firing or respawning), the view behind it. Drivers
//    are put out of their vehicles (and turrets) first, and vehicles stop.
//    Projectiles in flight are removed, nobody takes damage (CTFHalftimeRules)
//    and the match clock holds (HoldClock).
//  - The switch moves every player to the other team, the team scores with
//    them, rather than handing each team the other base: bases, flags and map
//    lighting are coloured by team, and the bots' team AI belongs to its base.
//    So each squad keeps its score and attacks what was its own base, in the
//    other colour.
//  - The reset is Assault's between rounds (ASGameInfo.ResetLevel): flags go
//    home, controllers reset (adrenaline too), then every actor but the game's
//    bookkeeping resets: pawns and corpses are removed, projectiles too, movers
//    close, pickups respawn and super pickups (UDamage, the big shield, the
//    keg, super weapons) start their 30 second match-start delay over, dropped
//    weapons vanish. Vehicles are removed too, and their factories build new
//    ones as at the start of the match (ResetVehicles). Then everyone
//    respawns at once.
//  - With bKeepLoadouts, as Bombing Run does between rounds, players keep
//    what they had: each living player's weapons, ammo, health (at least a
//    fresh spawn's), armor and adrenaline are noted at the freeze (SaveKit)
//    and given back on respawn (RestoreKit). Nothing timed carries over:
//    UDamage, and a running combo, which also costs its adrenaline.
//  Only in CTF (vehicle CTF too), and only with a time limit; once a match,
//  not in overtime.
//==============================================================================

class CTFHalftimeMutator extends Mutator
    config;

var config int CountdownSeconds;    // the freeze before the second half, 5-30
var config int WarningSeconds;      // the heads-up this long before halftime, 10-60
var config bool bKeepLoadouts;      // players respawn with what they had at halftime
var config string HalftimeText;     // shown at the freeze (CTFHalftimeMessage)

// a player's kit at the freeze (bKeepLoadouts), and its weapons, flat
struct Kit
{
    var Controller C;
    var int Health;
    var float Shield, SmallShield;
    var float Adrenaline;
    var class<Weapon> Current;
};
struct SavedWeapon
{
    var Controller C;
    var class<Weapon> WeaponClass;
    var int Ammo[2];
    var bool bDual;
};
var array<Kit> Kits;
var array<SavedWeapon> SavedWeapons;

var CTFHalftimeRules Rules;
var CTFHalftimeTextInfo TextInfo;
var bool bWarned;       // the heads-up has been shown
var bool bDone;         // halftime has happened
var bool bInHalftime;   // the freeze is on
var int Countdown;      // seconds left in it
var int HeldTime;       // the match clock while frozen

var localized string CountdownDisplayText, CountdownDescText, WarningDisplayText, WarningDescText;
var localized string KeepDisplayText, KeepDescText, TextDisplayText, TextDescText;

function bool MutatorIsAllowed()
{
    if ( CTFGame(Level.Game) == None )
    {
        log(self$" not running: game type"@Level.Game.Class@"isn't CTF");
        return false;
    }
    return Super.MutatorIsAllowed();
}

event PostBeginPlay()
{
    Super.PostBeginPlay();
    if ( bDeleteMe )
        return;

    Rules = Spawn(class'CTFHalftimeRules');
    Level.Game.AddGameModifier(Rules);
    SetTimer(1.0, true);

    // the halftime text, for clients to show
    TextInfo = Spawn(class'CTFHalftimeTextInfo');
    TextInfo.HalftimeText = HalftimeText;

    // time callouts by the half (CTFHalftimeHud); players log in after this,
    // getting their HUD class then. Only in place of the stock one.
    if ( Level.Game.HUDType ~= "XInterface.HudCCaptureTheFlag" )
        Level.Game.HUDType = string(class'CTFHalftimeHud');
    else
        log(self$" time callouts left as they are: game uses HUD"@Level.Game.HUDType);
}

function Timer()
{
    local DeathMatch G;

    G = DeathMatch(Level.Game);
    if ( G == None )
        return;

    if ( bInHalftime )
    {
        Countdown--;
        if ( Countdown > 0 )
        {
            FreezeLatecomers();
            BroadcastLocalizedMessage(class'CTFHalftimeCountdown', Countdown);
        }
        else
            SecondHalf();
        return;
    }

    if ( bDone || G.TimeLimit <= 0 || G.bGameEnded || G.bOverTime || !G.IsInState('MatchInProgress') )
        return;
    if ( G.RemainingTime <= G.TimeLimit * 30 )
        StartHalftime();
    else if ( !bWarned && G.RemainingTime - G.TimeLimit * 30 <= Clamp(WarningSeconds, 10, 60) )
    {
        // once, with the seconds actually left (right too if the match
        // started inside the warning time)
        bWarned = true;
        BroadcastLocalizedMessage(class'CTFHalftimeMessage', 100 + G.RemainingTime - G.TimeLimit * 30);
    }
}

// the game's own Timer counts the clock down every second; put it back
function Tick(float DeltaTime)
{
    if ( bInHalftime )
        HoldClock();
}

function HoldClock()
{
    local DeathMatch G;

    G = DeathMatch(Level.Game);
    G.RemainingTime = HeldTime;
    G.GameReplicationInfo.RemainingTime = HeldTime;
    G.GameReplicationInfo.bStopCountDown = true;
}

function StartHalftime()
{
    local Projectile P;
    local Controller C;
    local Vehicle V;

    bDone = true;
    bInHalftime = true;
    // shown all the way, voiced from 5 (CTFHalftimeCountdown)
    Countdown = Clamp(CountdownSeconds, 5, 30);
    HeldTime = DeathMatch(Level.Game).RemainingTime;
    HoldClock();
    Rules.bFrozen = true;

    foreach DynamicActors(class'Projectile', P)
        P.Destroy();

    Kits.Length = 0;
    SavedWeapons.Length = 0;
    for ( C = Level.ControllerList; C != None; C = C.NextController )
        if ( IsPlaying(C) )
        {
            if ( bKeepLoadouts )
                SaveKit(C);
            Freeze(C);
        }

    // the emptied vehicles stop where they are too
    foreach DynamicActors(class'Vehicle', V)
        if ( V.Physics == PHYS_Karma )
        {
            V.Velocity = vect(0,0,0);
            V.SetPhysics(PHYS_None);
        }

    BroadcastLocalizedMessage(class'CTFHalftimeMessage', 0,,, TextInfo);
    BroadcastLocalizedMessage(class'CTFHalftimeCountdown', Countdown);
}

function bool IsPlaying(Controller C)
{
    return ( C.bIsPlayer && C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bOnlySpectator );
}

// stops C and its pawn where they are, out of any vehicle or turret first; a
// player watches theirs from behind
function Freeze(Controller C)
{
    local PlayerController PC;
    local Pawn P;

    if ( Vehicle(C.Pawn) != None )
        Vehicle(C.Pawn).KDriverLeave(true);
    P = C.Pawn;
    C.RoundHasEnded();
    PC = PlayerController(C);
    if ( PC == None )
        return;
    PC.ClientRoundEnded();
    if ( P != None )
    {
        PC.SetViewTarget(P);
        PC.ClientSetViewTarget(P);
        PC.bBehindView = true;
        PC.ClientSetBehindView(true);
    }
}

// anyone who spawned since (joined, or a bot added) stops too
function FreezeLatecomers()
{
    local Controller C;

    for ( C = Level.ControllerList; C != None; C = C.NextController )
        if ( IsPlaying(C) && C.Pawn != None && !C.IsInState('RoundEnded') )
            Freeze(C);
}

function SecondHalf()
{
    local DeathMatch G;
    local Controller C;
    local Actor A;

    G = DeathMatch(Level.Game);
    bInHalftime = false;

    SendFlagsHome();
    SwapTeams();

    for ( C = Level.ControllerList; C != None; C = C.NextController )
        if ( IsPlaying(C) )
        {
            if ( PlayerController(C) != None )
                PlayerController(C).ClientReset();
            C.Reset();
        }

    foreach AllActors(class'Actor', A)
        if ( ShouldReset(A) )
            A.Reset();
    ResetVehicles();

    Rules.bFrozen = false;
    G.RemainingTime = HeldTime;
    G.GameReplicationInfo.RemainingTime = HeldTime;
    G.GameReplicationInfo.RemainingMinute = HeldTime;  // clients take the clock from this
    G.GameReplicationInfo.bStopCountDown = false;
    G.GameReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;

    for ( C = Level.ControllerList; C != None; C = C.NextController )
        if ( IsPlaying(C) && C.PlayerReplicationInfo.Team != None )
        {
            G.RestartPlayer(C);
            if ( bKeepLoadouts )
                RestoreKit(C);
            // by team, as the new team may not have reached the client yet
            if ( PlayerController(C) != None )
                PlayerController(C).ReceiveLocalizedMessage(class'CTFHalftimeMessage', 1 + C.PlayerReplicationInfo.Team.TeamIndex);
        }
}

// The reset removed every vehicle (Pawn.Reset destroys any without a
// controller), each telling its factory, which would rebuild it after its
// RespawnTime. Instead they all start building now, as when the factories
// were activated at the start of the match. A factory stays with its base's
// team, so the teams' vehicles change sides with them.
function ResetVehicles()
{
    local ONSVehicleFactory F;

    foreach AllActors(class'ONSVehicleFactory', F)
        if ( F.bActive && F.VehicleCount < F.MaxVehicleCount )
        {
            F.bPreSpawn = true;
            F.Timer();
        }
}

// notes C's living pawn's kit (its driver's, in a vehicle) for RestoreKit
function SaveKit(Controller C)
{
    local Pawn P;
    local Inventory Inv;
    local Weapon W;
    local int i, j;

    P = C.Pawn;
    if ( Vehicle(P) != None )
        P = Vehicle(P).Driver;
    if ( P == None || P.Health <= 0 )
        return;

    i = Kits.Length;
    Kits.Length = i + 1;
    Kits[i].C = C;
    Kits[i].Health = P.Health;
    Kits[i].Shield = P.ShieldStrength;
    if ( xPawn(P) != None )
        Kits[i].SmallShield = xPawn(P).SmallShieldStrength;
    // as Bombing Run: a running combo is lost, and the adrenaline it cost
    Kits[i].Adrenaline = C.Adrenaline;
    if ( xPawn(P) != None && xPawn(P).CurrentCombo != None )
        Kits[i].Adrenaline = 0;
    if ( P.Weapon != None )
        Kits[i].Current = P.Weapon.Class;

    for ( Inv = P.Inventory; Inv != None; Inv = Inv.Inventory )
    {
        W = Weapon(Inv);
        if ( W == None )
            continue;
        j = SavedWeapons.Length;
        SavedWeapons.Length = j + 1;
        SavedWeapons[j].C = C;
        SavedWeapons[j].WeaponClass = W.Class;
        SavedWeapons[j].Ammo[0] = W.AmmoAmount(0);
        SavedWeapons[j].Ammo[1] = W.AmmoAmount(1);
        SavedWeapons[j].bDual = ( AssaultRifle(W) != None && AssaultRifle(W).bDualMode );
    }
}

// gives C's new pawn back its kit from SaveKit, over its fresh spawn's
function RestoreKit(Controller C)
{
    local Pawn P;
    local Weapon W;
    local Pickup Second;
    local int i, k;

    P = C.Pawn;
    if ( P == None )
        return;
    for ( k = 0; k < Kits.Length; k++ )
        if ( Kits[k].C == C )
            break;
    if ( k == Kits.Length )
        return;

    for ( i = 0; i < SavedWeapons.Length; i++ )
    {
        if ( SavedWeapons[i].C != C || SavedWeapons[i].WeaponClass == None )
            continue;
        W = Weapon(P.FindInventoryType(SavedWeapons[i].WeaponClass));
        if ( W == None )
        {
            W = Spawn(SavedWeapons[i].WeaponClass,,, P.Location);
            if ( W == None )
                continue;
            W.GiveTo(P);
        }
        // a second Assault Rifle, as picking one up does
        if ( SavedWeapons[i].bDual && AssaultRifle(W) != None && !AssaultRifle(W).bDualMode
            && W.PickupClass != None )
        {
            Second = Spawn(W.PickupClass,,, P.Location);
            if ( Second != None )
            {
                W.HandlePickupQuery(Second);
                Second.Destroy();
            }
        }
        SetAmmo(W, 0, SavedWeapons[i].Ammo[0]);
        if ( W.GetAmmoClass(1) != None && W.GetAmmoClass(1) != W.GetAmmoClass(0) )
            SetAmmo(W, 1, SavedWeapons[i].Ammo[1]);
    }

    P.Health = Max(P.Health, Kits[k].Health);
    P.ShieldStrength = Kits[k].Shield;
    if ( xPawn(P) != None )
        xPawn(P).SmallShieldStrength = Kits[k].SmallShield;
    C.Adrenaline = Kits[k].Adrenaline;
    if ( Kits[k].Current != None )
        C.ClientSetWeapon(Kits[k].Current);
}

function SetAmmo(Weapon W, int Mode, int Amount)
{
    local int Have;

    Have = W.AmmoAmount(Mode);
    if ( Amount > Have )
        W.AddAmmo(Amount - Have, Mode);
    else if ( Amount < Have )
        W.ConsumeAmmo(Mode, Have - Amount, true);
}

// held flags are let go of (the Held state ignores SendHome), then all go home
function SendFlagsHome()
{
    local CTFFlag F;

    foreach DynamicActors(class'CTFFlag', F)
    {
        if ( F.bHeld )
            F.GotoState('Dropped');
        F.SendHome();
    }
}

// everyone to the other team, the team scores with them
function SwapTeams()
{
    local TeamGame G;
    local Controller C;
    local array<Controller> Movers;
    local UnrealTeamInfo OldTeam, NewTeam;
    local float Score;
    local int i;

    G = TeamGame(Level.Game);

    Score = G.Teams[0].Score;
    G.Teams[0].Score = G.Teams[1].Score;
    G.Teams[1].Score = Score;
    G.Teams[0].NetUpdateTime = Level.TimeSeconds - 1;
    G.Teams[1].NetUpdateTime = Level.TimeSeconds - 1;

    for ( C = Level.ControllerList; C != None; C = C.NextController )
        if ( IsPlaying(C) && C.PlayerReplicationInfo.Team != None )
            Movers[Movers.Length] = C;

    for ( i = 0; i < Movers.Length; i++ )
    {
        C = Movers[i];
        OldTeam = UnrealTeamInfo(C.PlayerReplicationInfo.Team);
        NewTeam = G.Teams[1 - OldTeam.TeamIndex];
        OldTeam.RemoveFromTeam(C);
        NewTeam.AddToTeam(C);
        if ( Bot(C) != None )
            NewTeam.SetBotOrders(Bot(C), None);
    }
}

// Everything but the game's bookkeeping (Info: the game, team and player
// infos with the scores, mutators, game rules), except the team and squad AI,
// so squads pick their objectives afresh. Controllers are reset before, the
// CTF bases aren't (GameObjective.Reset changes their active state).
function bool ShouldReset(Actor A)
{
    if ( A == None || A.bDeleteMe || Controller(A) != None || HUD(A) != None || GameObjective(A) != None )
        return false;
    if ( Info(A) != None )
        return ( TeamAI(A) != None || SquadAI(A) != None );
    return true;
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);
    PlayInfo.AddSetting(default.RulesGroup, "CountdownSeconds", default.CountdownDisplayText, 0, 1, "Text", "2;5:30");
    PlayInfo.AddSetting(default.RulesGroup, "WarningSeconds", default.WarningDisplayText, 0, 1, "Text", "2;10:60");
    PlayInfo.AddSetting(default.RulesGroup, "bKeepLoadouts", default.KeepDisplayText, 0, 1, "Check");
    PlayInfo.AddSetting(default.RulesGroup, "HalftimeText", default.TextDisplayText, 0, 1, "Text", "40");
}

static event string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "CountdownSeconds":    return default.CountdownDescText;
        case "WarningSeconds":      return default.WarningDescText;
        case "bKeepLoadouts":       return default.KeepDescText;
        case "HalftimeText":        return default.TextDescText;
    }
    return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    CountdownSeconds=10
    CountdownDisplayText="Halftime Pause (s)"
    CountdownDescText="How long play stops at halftime before the second half starts, 5-30 seconds, counted down on screen (the announcer counts the last 5)."
    WarningSeconds=20
    WarningDisplayText="Halftime Warning (s)"
    WarningDescText="How long before halftime everyone is warned that teams are about to switch sides, 10-60 seconds."
    KeepDisplayText="Keep Loadouts At Halftime"
    KeepDescText="Players alive at halftime start the second half with what they had: weapons, ammo, health (at least 100), armor and adrenaline. UDamage and running combos don't carry over. The level still resets. Best on symmetrical maps."
    HalftimeText="HALFTIME"
    TextDisplayText="Halftime Text"
    TextDescText="The message shown when play stops at halftime. Blank for the default."
    GroupName="CTFHalftime"
    FriendlyName="CTF Halftime"
    Description="At half the time limit, CTF teams switch sides: play stops for a countdown, then everyone moves to the other team, scores and all, and the second half starts from a fresh level. Works in vehicle CTF too. Needs a time limit. Details: https://github.com/chairmanbrando/UT2004/blob/main/CTFHalftime/README.md"
    bAddToServerPackages=True
}
