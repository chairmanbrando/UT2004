//==============================================================================
//  CoD Mode: go RegenDelay seconds without taking damage and your health
//  starts coming back, RegenPerSecond a second, up to RegenMaxHealth. Any hit
//  (CoDModeRules) stops it and starts the wait over. Each life starts fresh.
//  Health chargers (bases holding a health pack) hold a big mini health vial
//  instead, +15 and overhealing (CoDHealthVial). Every other pickup, mini
//  vials included, is left alone.
//  With bLoadoutProvided, everyone also spawns with LoadoutWeapons, and every
//  weapon full, but the Assault Rifle:
//  no bullets (or shells), 2 grenades. Weapon bases (super weapons' aside)
//  are hidden and spawn nothing, lockers are disabled, and the map's weapon
//  and ammo pickups are removed, as InstaGib does: bots, finding nothing at
//  their inventory spots, stop looking. Bases and lockers are hidden on
//  clients by CoDLoadoutInfo. Dropped weapons stay, but give no more of each
//  ammo than its ammo pickup would (CapDroppedAmmo, from CoDModeRules).
//==============================================================================

class CoDModeMutator extends Mutator
    config;

var config float RegenDelay;        // seconds without damage before regen starts
var config float RegenPerSecond;    // health regained a second
var config int RegenMaxHealth;      // regen stops here (ini only, not in the settings)
var config bool bLoadoutProvided;   // spawn with LoadoutWeapons, full ammo, no weapon or ammo pickups

var array<string> LoadoutWeapons;   // given on spawn with bLoadoutProvided
var int SpawnGrenades;              // Assault Rifle grenades on spawn (and no bullets)

// a living pawn's regen state; dropped when it dies
struct RegenRecord
{
    var Pawn P;
    var float LastHit;      // Level.TimeSeconds of its last hit (or first sighting)
    var float Partial;      // regen not yet a whole point of health
};
var array<RegenRecord> Records;

var localized string DelayDisplayText, DelayDescText;
var localized string RateDisplayText, RateDescText;
var localized string LoadoutDisplayText, LoadoutDescText;

function PostBeginPlay()
{
    local CoDModeRules Rules;

    Super.PostBeginPlay();
    Rules = Spawn(class'CoDModeRules');
    Rules.Mut = self;
    if ( Level.Game.GameRulesModifiers == None )
        Level.Game.GameRulesModifiers = Rules;
    else
        Level.Game.GameRulesModifiers.AddGameRules(Rules);

    if ( bLoadoutProvided )
        Spawn(class'CoDLoadoutInfo');
}

// Redeemer and Ion Painter (inventory group 0)
static function bool IsSuperWeapon(class<Inventory> W)
{
    return ( class<Weapon>(W) != None && W.default.InventoryGroup == 0 );
}

// A weapon base's look, and its spiral effect, gone
static function HideWeaponBase(xWeaponBase B)
{
    B.bHidden = true;
    if ( B.myEmitter != None )
    {
        B.myEmitter.Destroy();
        B.myEmitter = None;
    }
}

// Clients' copies of the map's weapon bases and lockers (CoDLoadoutInfo)
static function HideWeaponSpawners(Actor A)
{
    local xWeaponBase B;
    local WeaponLocker L;

    foreach A.AllActors(class'xWeaponBase', B)
        if ( !IsSuperWeapon(B.WeaponType) )
            HideWeaponBase(B);
    foreach A.AllActors(class'WeaponLocker', L)
        L.GotoState('Disabled');
}

// any health pack on a base (other mutators' subclasses too) becomes the big
// vial; with bLoadoutProvided, weapons and ammo are cleared off the map
function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local xPickupBase B;

    B = xPickupBase(Other);
    if ( B != None && B.PowerUp != None && ClassIsChildOf(B.PowerUp, class'HealthPack') )
        B.PowerUp = class'CoDHealthVial';

    if ( !bLoadoutProvided )
        return true;

    if ( xWeaponBase(Other) != None )
    {
        if ( !IsSuperWeapon(xWeaponBase(Other).WeaponType) )
        {
            // no WeaponType, no pickup (xWeaponBase.PostBeginPlay)
            xWeaponBase(Other).WeaponType = None;
            HideWeaponBase(xWeaponBase(Other));
        }
    }
    else if ( WeaponLocker(Other) != None )
        Other.GotoState('Disabled');
    // dropped weapons appear once play has begun; the map's are there before
    else if ( (WeaponPickup(Other) != None && !Level.bBegunPlay && !IsSuperWeapon(WeaponPickup(Other).InventoryType)) || Ammo(Other) != None )
    {
        if ( Other.bStatic || Other.bNoDelete )
        {
            Other.GotoState('Disabled');
            return true;
        }
        return false;
    }
    return true;
}

// After the rest of the chain (other mutators may change spawn ammo there), so
// the ammo set here is what everyone starts with
function ModifyPlayer(Pawn Other)
{
    local int i;
    local Inventory Inv;

    Super.ModifyPlayer(Other);
    if ( !bLoadoutProvided || Other == None )
        return;

    for ( i = 0; i < LoadoutWeapons.Length; i++ )
        GiveLoadoutWeapon(Other, LoadoutWeapons[i]);

    for ( Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory )
    {
        if ( AssaultRifle(Inv) != None )
        {
            SetAmmo(Weapon(Inv), 0, 0);
            SetAmmo(Weapon(Inv), 1, SpawnGrenades);
        }
        else if ( Weapon(Inv) != None )
            Weapon(Inv).MaxOutAmmo();
    }
}

function SetAmmo(Weapon W, int Mode, int Amount)
{
    local int Have;

    Have = W.AmmoAmount(Mode);
    if ( Have > Amount )
        W.ConsumeAmmo(Mode, Have - Amount, true);
    else if ( Have < Amount )
        W.AddAmmo(Amount - Have, Mode);
}

// By class name through the mutators' overrides, as spawn inventory is, so
// weapon-replacing mutators hand out their versions
function GiveLoadoutWeapon(Pawn P, string ClassName)
{
    local class<Weapon> WeaponClass;
    local Weapon W;

    ClassName = Level.Game.BaseMutator.GetInventoryClassOverride(ClassName);
    WeaponClass = class<Weapon>(DynamicLoadObject(ClassName, class'Class', true));
    if ( WeaponClass == None || P.FindInventoryType(WeaponClass) != None )
        return;
    W = Spawn(WeaponClass,,, P.Location);
    if ( W != None )
        W.GiveTo(P);
}

// From CoDModeRules, as a dropped weapon is about to be picked up: each of
// its ammo down to what that ammo's pickup holds (9 rockets, 10 lightning
// rounds, 4 grenades). Ammo no pickup gives is left as it was.
function CapDroppedAmmo(WeaponPickup WP)
{
    local class<Weapon> W;
    local class<Ammunition> AmmoClass;
    local class<Ammo> AmmoPickup;
    local int m;

    W = class<Weapon>(WP.InventoryType);
    if ( W == None || IsSuperWeapon(W) )
        return;
    for ( m = 0; m < 2; m++ )
    {
        if ( W.default.FireModeClass[m] == None )
            continue;
        AmmoClass = W.default.FireModeClass[m].default.AmmoClass;
        if ( AmmoClass == None )
            continue;
        AmmoPickup = class<Ammo>(AmmoClass.default.PickupClass);
        if ( AmmoPickup != None && AmmoPickup.default.InventoryType == AmmoClass )
            WP.AmmoAmount[m] = Min(WP.AmmoAmount[m], AmmoPickup.default.AmmoAmount);
    }
}


function int FindRecord(Pawn P)
{
    local int i;

    for ( i = 0; i < Records.Length; i++ )
        if ( Records[i].P == P )
            return i;
    i = Records.Length;
    Records.Length = i + 1;
    Records[i].P = P;
    Records[i].LastHit = Level.TimeSeconds;
    return i;
}

// from CoDModeRules: P took damage, so its regen stops and the wait starts over
function NotifyHit(Pawn P)
{
    local int i;

    i = FindRecord(P);
    Records[i].LastHit = Level.TimeSeconds;
    Records[i].Partial = 0;
}

function Tick(float DeltaTime)
{
    local Controller C;
    local Pawn P;
    local int i, Gain;

    // forget the dead and gone
    for ( i = Records.Length - 1; i >= 0; i-- )
        if ( Records[i].P == None || Records[i].P.bDeleteMe || Records[i].P.Health <= 0 )
            Records.Remove(i, 1);

    for ( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if ( !C.bIsPlayer )
            continue;
        P = C.Pawn;
        if ( Vehicle(P) != None )
            P = Vehicle(P).Driver;
        if ( P == None || P.bDeleteMe || P.Health <= 0 )
            continue;

        i = FindRecord(P);
        if ( P.Health >= RegenMaxHealth )
        {
            Records[i].Partial = 0;
            continue;
        }
        if ( Level.TimeSeconds - Records[i].LastHit < RegenDelay )
            continue;

        Records[i].Partial += RegenPerSecond * DeltaTime;
        Gain = int(Records[i].Partial);
        if ( Gain > 0 )
        {
            Records[i].Partial -= Gain;
            P.Health = Min(P.Health + Gain, RegenMaxHealth);
        }
    }
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);
    PlayInfo.AddSetting(default.RulesGroup, "RegenDelay", default.DelayDisplayText, 0, 1, "Text", "4;0.0:60.0");
    PlayInfo.AddSetting(default.RulesGroup, "RegenPerSecond", default.RateDisplayText, 0, 1, "Text", "5;0.0:999.0");
    PlayInfo.AddSetting(default.RulesGroup, "bLoadoutProvided", default.LoadoutDisplayText, 0, 1, "Check");
}

static event string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "RegenDelay":      return default.DelayDescText;
        case "RegenPerSecond":  return default.RateDescText;
        case "bLoadoutProvided": return default.LoadoutDescText;
    }
    return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    RegenDelay=4.0
    DelayDisplayText="Regen Delay (s)"
    DelayDescText="Seconds without taking damage before health starts coming back."
    RegenPerSecond=25.0
    RateDisplayText="Regen Per Second"
    RateDescText="Health regained each second once regen starts."
    RegenMaxHealth=100
    bLoadoutProvided=False
    LoadoutWeapons(0)="XWeapons.RocketLauncher"
    LoadoutWeapons(1)="XWeapons.SniperRifle"
    SpawnGrenades=2
    LoadoutDisplayText="Loadout Provided"
    LoadoutDescText="Everyone spawns with a full Rocket Launcher and Lightning Gun too, and an Assault Rifle with only 2 grenades. Weapon bases (super weapons' aside), lockers and ammo pickups are removed. Dropped weapons give at most an ammo pickup's worth."
    GroupName="CoDMode"
    FriendlyName="CoD Mode"
    Description="Avoid damage for a few seconds and your health comes back. Health chargers hold a big +15 vial instead. Details: https://github.com/chairmanbrando/UT2004/blob/main/CoDMode/README.md"
    bAddToServerPackages=True
}
