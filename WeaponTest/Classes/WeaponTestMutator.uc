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
    GroupName="Arena"
    FriendlyName="Weapon Test"
    Description="Every weapon base and pickup in the map holds one weapon, picked in the settings, and every ammo pickup is its ammo. Lockers are off; spawn weapons are unchanged. Works with UT2026."
    bAddToServerPackages=True
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
}
