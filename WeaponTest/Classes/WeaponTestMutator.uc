//==============================================================================
//  Weapon Test: every weapon base and weapon pickup in the map holds the
//  weapon picked in the mutator's settings, and every ammo pickup is that
//  weapon's ammo pickup (one per weapon: the Assault Rifle's gives bullets and
//  grenades both). Weapon lockers are switched off, as the
//  stock Arena mutator does. Spawn inventory is left alone. For testing a
//  weapon without playing through a map's others.
//
//  Works with UT2026 in either mutator order:
//  - Weapon bases get the stock class picked, which UT2026 swaps for its own
//    version if it comes later in the chain; if it came earlier (it already
//    swapped the map's weapon), it's handed the base again (CheckReplacement)
//    to swap the new one.
//  - Pickups are replaced with ReplaceWith, whose new pickup goes through the
//    whole chain, UT2026 included. Ours are let through untouched
//    (ReplaceDepth), as are pickups of the picked weapon or ammo or a
//    subclass, such as a base's UT2026 weapon or UT2026's shotgun ammo.
//
//  "mutate idlebots" (offline, the listen server's host, or an admin) toggles
//  idle bots: they stay alive, animated and aware of you, turning to face you,
//  but can't move, jump, dodge, fire or start combos, so they make test
//  targets. Their speeds are zeroed (kept per pawn and put back when toggled
//  off), their weapons' next shot is held off, and their adrenaline is kept
//  below a combo. Bots don't need subclassing for it (UT2026Bots has its own).
//  Knockback still moves them. Bots in vehicles are left alone.
//==============================================================================

class WeaponTestMutator extends Mutator
    config;

var config string WeaponClassName;

var bool bInitialized;
var class<Weapon> WeaponClass;
var class<Pickup> WeaponPickupClass;
var class<Pickup> AmmoPickupClass;
var int ReplaceDepth;       // > 0 while our own replacement pickup is spawning

var localized string WeaponDisplayText, WeaponDescText;

// an idled bot's pawn's own movement values, to put back
struct HeldPawn
{
    var Pawn P;
    var float GroundSpeed, WaterSpeed, LadderSpeed, AirControl, JumpZ, DodgeSpeedZ, MultiJumpBoost;
};

var bool bIdleBots;
var array<HeldPawn> Held;
var localized string IdleBotsOnText, IdleBotsOffText;

function Mutate(string MutateString, PlayerController Sender)
{
    if ( MutateString ~= "idlebots" && Sender != None
        && (Level.NetMode == NM_Standalone || Viewport(Sender.Player) != None
            || (Sender.PlayerReplicationInfo != None && Sender.PlayerReplicationInfo.bAdmin)) )
    {
        bIdleBots = !bIdleBots;
        if ( bIdleBots )
            Sender.ClientMessage(IdleBotsOnText);
        else
        {
            ReleaseBots();
            Sender.ClientMessage(IdleBotsOffText);
        }
    }
    Super.Mutate(MutateString, Sender);
}

// Every frame, so new spawns are caught and nothing (a combo ending, UT2026's
// adrenaline speed) gets a held bot's speed back
event Tick(float DeltaTime)
{
    local Controller C;
    local Weapon W;
    local WeaponFire F;
    local int i;

    if ( !bIdleBots )
        return;

    for ( i = Held.Length - 1; i >= 0; i-- )
        if ( Held[i].P == None || Held[i].P.bDeleteMe )
            Held.Remove(i, 1);

    for ( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if ( Bot(C) == None || C.Pawn == None || Vehicle(C.Pawn) != None || C.Pawn.Health <= 0 )
            continue;

        if ( FindHeld(C.Pawn) < 0 )
            HoldPawn(C.Pawn);
        StopPawn(C.Pawn);

        // no combos: bots start one at AdrenalineMax
        if ( C.Adrenaline >= C.AdrenalineMax )
            C.Adrenaline = C.AdrenalineMax - 1;

        // Weapon.ReadyToFire and the fire loop both wait for NextFireTime
        W = C.Pawn.Weapon;
        if ( W != None )
            for ( i = 0; i < 2; i++ )
            {
                F = W.GetFireMode(i);
                if ( F != None )
                    F.NextFireTime = Level.TimeSeconds + 1.0;
            }
    }
}

function int FindHeld(Pawn P)
{
    local int i;

    for ( i = 0; i < Held.Length; i++ )
        if ( Held[i].P == P )
            return i;
    return -1;
}

function HoldPawn(Pawn P)
{
    local int i;

    i = Held.Length;
    Held.Length = i + 1;
    Held[i].P = P;
    Held[i].GroundSpeed = P.GroundSpeed;
    Held[i].WaterSpeed = P.WaterSpeed;
    Held[i].LadderSpeed = P.LadderSpeed;
    Held[i].AirControl = P.AirControl;
    Held[i].JumpZ = P.JumpZ;
    if ( xPawn(P) != None )
    {
        Held[i].DodgeSpeedZ = xPawn(P).DodgeSpeedZ;
        Held[i].MultiJumpBoost = xPawn(P).MultiJumpBoost;
    }
}

// Dodges are DodgeSpeedFactor * GroundSpeed across, DodgeSpeedZ up
function StopPawn(Pawn P)
{
    P.GroundSpeed = 0;
    P.WaterSpeed = 0;
    P.LadderSpeed = 0;
    P.AirControl = 0;
    P.JumpZ = 0;
    if ( xPawn(P) != None )
    {
        xPawn(P).DodgeSpeedZ = 0;
        xPawn(P).MultiJumpBoost = 0;
    }
}

function ReleaseBots()
{
    local int i;
    local Pawn P;

    for ( i = 0; i < Held.Length; i++ )
    {
        P = Held[i].P;
        if ( P == None || P.bDeleteMe )
            continue;
        P.GroundSpeed = Held[i].GroundSpeed;
        P.WaterSpeed = Held[i].WaterSpeed;
        P.LadderSpeed = Held[i].LadderSpeed;
        P.AirControl = Held[i].AirControl;
        P.JumpZ = Held[i].JumpZ;
        if ( xPawn(P) != None )
        {
            xPawn(P).DodgeSpeedZ = Held[i].DodgeSpeedZ;
            xPawn(P).MultiJumpBoost = Held[i].MultiJumpBoost;
        }
    }
    Held.Length = 0;
}

// on clients too (the mutator replicates), so their lockers hide as well
simulated function BeginPlay()
{
    local WeaponLocker L;

    foreach AllActors(class'WeaponLocker', L)
        L.GotoState('Disabled');

    Super.BeginPlay();
}

function Initialize()
{
    local int m;
    local class<Ammunition> A;

    bInitialized = true;
    WeaponClass = class<Weapon>(DynamicLoadObject(WeaponClassName, class'Class', true));
    if ( WeaponClass == None )
    {
        log(self$" no such weapon:"@WeaponClassName$"; map left as is");
        return;
    }
    WeaponPickupClass = WeaponClass.default.PickupClass;

    // the first fire mode's ammo that has a pickup
    for ( m = 0; m < 2 && AmmoPickupClass == None; m++ )
    {
        if ( WeaponClass.default.FireModeClass[m] == None )
            continue;
        A = WeaponClass.default.FireModeClass[m].default.AmmoClass;
        if ( A != None )
            AmmoPickupClass = A.default.PickupClass;
    }
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local Mutator M;

    if ( !bInitialized )
        Initialize();
    if ( WeaponClass == None || ReplaceDepth > 0 )
        return true;

    if ( xWeaponBase(Other) != None )
    {
        xWeaponBase(Other).WeaponType = WeaponClass;
        for ( M = Level.Game.BaseMutator; M != None && M != self; M = M.NextMutator )
            if ( M.IsA('UT2026Mutator') )
                M.CheckReplacement(Other, bSuperRelevant);
        return true;
    }

    if ( WeaponLocker(Other) != None )
    {
        Other.GotoState('Disabled');
        return true;
    }

    // weapon pickups placed in the map, not ones dropped in play
    if ( WeaponPickup(Other) != None && Level.bStartup )
    {
        if ( WeaponPickupClass == None )
            return false;
        if ( ClassIsChildOf(WeaponPickup(Other).InventoryType, WeaponClass) )
            return true;
        return ReplacePickup(Other, WeaponPickupClass);
    }

    if ( Ammo(Other) != None )
    {
        if ( AmmoPickupClass == None )
            return false;
        if ( ClassIsChildOf(Other.Class, AmmoPickupClass) )
            return true;
        return ReplacePickup(Other, AmmoPickupClass);
    }

    return true;
}

// The new pickup passes through every mutator, this one waving it through
function bool ReplacePickup(Actor Other, class<Pickup> NewClass)
{
    ReplaceDepth++;
    ReplaceWith(Other, string(NewClass));
    ReplaceDepth--;
    return false;
}

// the weapon list the stock Arena mutator offers
static function FillPlayInfo(PlayInfo PlayInfo)
{
    local array<CacheManager.WeaponRecord> Recs;
    local string WeaponOptions;
    local int i;

    Super.FillPlayInfo(PlayInfo);

    class'CacheManager'.static.GetWeaponList(Recs);
    for ( i = 0; i < Recs.Length; i++ )
    {
        if ( WeaponOptions != "" )
            WeaponOptions $= ";";
        WeaponOptions $= Recs[i].ClassName $ ";" $ Recs[i].FriendlyName;
    }

    PlayInfo.AddSetting(default.RulesGroup, "WeaponClassName", default.WeaponDisplayText, 0, 1, "Select", WeaponOptions);
}

static event string GetDescriptionText(string PropName)
{
    if ( PropName == "WeaponClassName" )
        return default.WeaponDescText;
    return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    WeaponClassName="XWeapons.ShockRifle"
    WeaponDisplayText="Test Weapon"
    WeaponDescText="The weapon every weapon base and weapon pickup in the map holds; every ammo pickup becomes its ammo. Weapon lockers are switched off. With UT2026, its version of the weapon."
    IdleBotsOnText="Idle bots: on. They can't move or fire."
    IdleBotsOffText="Idle bots: off."
    GroupName="Arena"
    FriendlyName="Weapon Test"
    Description="Every weapon base and pickup in the map holds one weapon, picked in the settings, and every ammo pickup is its ammo. Lockers are off; spawn weapons are unchanged. Works with UT2026."
    bAddToServerPackages=True
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
}
