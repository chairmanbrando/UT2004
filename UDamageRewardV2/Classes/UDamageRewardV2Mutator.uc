//==============================================================================
//  UDamage Reward v2: the stock "UDamage Reward" mutator with additions and
//  fixes. Use it instead of the stock one, not alongside it.
//  - Remaining UDamage is dropped when its holder is fragged (stock behaviour).
//  - Kills made with UDamage add to its time, up to a cap.
//  - Dropped UDamage can be caught mid-air, and respects the cap
//    (UDamageRewardV2Pickup).
//  - The "UDamage ending" warning restarts properly after an extension
//    (UDamageUtil).
//  - UDamage chargers use UDamageV2Pack for a longer-range respawn sound.
//  - Optionally defensive: UDamage protects its holder (UDamageRewardV2Rules.NetDamage)
//    instead of doubling damage dealt, with its own pickup message (DefensiveUDamagePack,
//    DefensiveUDamageReward).
//  - Wildcard bases' UDamage is the v2 one too.
//  - Optionally Ruckus Mode: every armor charger, big keg and wildcard base
//    spawns UDamage instead, with all of the above; all UDamage, the stock
//    chargers' too, respawns every RuckusRespawnTime; armor lying loose in
//    the map is removed; UDamage time isn't capped at 30s and charger pickups
//    add to it (UDamageV2Pack.bStackTime).
//  Kill and damage handling is in the game rules class 'UDamageRewardV2Rules'.
//==============================================================================

class UDamageRewardV2Mutator extends Mutator
    config;

var config float KillBonusTime;		// seconds of UDamage added per kill
var config bool bCapUDamageTime;	// cap at 30s like a stock pickup; otherwise 999s
var config float SpawnSoundRadius;	// range of the UDamage respawn sound; 0 keeps the stock sound
var config string SpawnSound;
var config bool bDefensiveUDamage;	// UDamage protects its holder instead of doubling damage dealt
var config bool bRuckusMode;        // armor chargers, big kegs and wildcard bases spawn UDamage
var config float RuckusRespawnTime; // seconds between UDamage respawns in Ruckus Mode (stock 90)
var byte DefensiveLightHue;		// teal

var localized string KillBonusDisplayText, CapDisplayText, KillBonusDescText, CapDescText;
var localized string DefensiveDisplayText, DefensiveDescText;
var localized string RuckusDisplayText, RuckusDescText, RuckusRespawnDisplayText, RuckusRespawnDescText;
var localized string SoundRadiusDisplayText, SoundDisplayText, SoundRadiusDescText, SoundDescText;

event PostBeginPlay()
{
    local UDamageRewardV2Rules G;

    Super.PostBeginPlay();

    if ( bDeleteMe )
        return;

    // Onslaught and Assault objectives double UDamage damage themselves, so
    // defensive UDamage would still do double damage there: stock UDamage
    // instead. (By name, to avoid depending on those packages; only this
    // game's copy changes, not the saved setting.)
    if ( bDefensiveUDamage && (Level.Game.IsA('ONSOnslaughtGame') || Level.Game.IsA('ASGameInfo')) )
        bDefensiveUDamage = false;

    // holders' characters glow on every client (teal when defensive)
    Spawn(class'UDamageGlowFX').bDefensive = bDefensiveUDamage;

    G = Spawn(class'UDamageRewardV2Rules');
    G.KillBonusTime = KillBonusTime;
    G.bDefensive = bDefensiveUDamage;
    // Ruckus Mode never caps
    if ( bCapUDamageTime && !bRuckusMode )
        G.MaxUDamageTime = 30;
    else
        G.MaxUDamageTime = 999;
    Level.Game.AddGameModifier(G);
}

// Called from each actor's PreBeginPlay: before UDamage chargers spawn their
// pickups (PostBeginPlay)
function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local int i;

    if ( WildcardBase(Other) != None )
    {
        // picks one of these each respawn (WildcardBase.TurnOn)
        for ( i = 0; i < ArrayCount(WildcardBase(Other).PickupClasses); i++ )
            if ( WildcardBase(Other).PickupClasses[i] == class'UDamagePack'
                || (bRuckusMode && WildcardBase(Other).PickupClasses[i] != None) )
                WildcardBase(Other).PickupClasses[i] = UDamageClass();
    }
    else if ( xPickupBase(Other) != None && (xPickupBase(Other).PowerUp == class'UDamagePack'
        || (bRuckusMode && IsRuckusBase(xPickupBase(Other)))) )
        xPickupBase(Other).PowerUp = UDamageClass();
    else if ( UDamageV2Pack(Other) != None )
    {
        UDamageV2Pack(Other).SpawnSoundName = SpawnSound;
        UDamageV2Pack(Other).SpawnSoundRadius = SpawnSoundRadius;
        if ( bRuckusMode )
        {
            UDamageV2Pack(Other).RespawnTime = FMax(1, RuckusRespawnTime);
            UDamageV2Pack(Other).bStackTime = true;
        }
    }
    // the chargers spawn UDamage instead, so this is only armor placed loose
    // in the map
    else if ( bRuckusMode && ShieldPickup(Other) != None )
        return false;
    // the light around a UDamage holder (xPawn.EnableUDamage), teal for
    // defensive UDamage; stock is purple (204)
    else if ( bDefensiveUDamage && xPawn(Other) != None )
        xPawn(Other).LightHue = DefensiveLightHue;

    return true;
}

function class<UDamageV2Pack> UDamageClass()
{
    if ( bDefensiveUDamage )
        return class'DefensiveUDamagePack';
    return class'UDamageV2Pack';
}

// armor chargers and big kegs, by the base's class, so they spawn UDamage
// whatever pickup another mutator (UT2026's armor, say) gave them
function bool IsRuckusBase(xPickupBase B)
{
    return ShieldCharger(B) != None || SuperShieldCharger(B) != None || SuperHealthCharger(B) != None;
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);

    PlayInfo.AddSetting(default.RulesGroup, "KillBonusTime", default.KillBonusDisplayText, 0, 1, "Text", "3;0:999");
    PlayInfo.AddSetting(default.RulesGroup, "bCapUDamageTime", default.CapDisplayText, 0, 1, "Check");
    PlayInfo.AddSetting(default.RulesGroup, "SpawnSoundRadius", default.SoundRadiusDisplayText, 0, 1, "Text", "6;0:100000");
    PlayInfo.AddSetting(default.RulesGroup, "SpawnSound", default.SoundDisplayText, 0, 1, "Text", "64");
    PlayInfo.AddSetting(default.RulesGroup, "bDefensiveUDamage", default.DefensiveDisplayText, 0, 1, "Check");
    PlayInfo.AddSetting(default.RulesGroup, "bRuckusMode", default.RuckusDisplayText, 0, 1, "Check");
    PlayInfo.AddSetting(default.RulesGroup, "RuckusRespawnTime", default.RuckusRespawnDisplayText, 0, 1, "Text", "3;1:999");
}

static event string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "KillBonusTime":		return default.KillBonusDescText;
        case "bCapUDamageTime":		return default.CapDescText;
        case "SpawnSoundRadius":	return default.SoundRadiusDescText;
        case "SpawnSound":		return default.SoundDescText;
        case "bDefensiveUDamage":	return default.DefensiveDescText;
        case "bRuckusMode":         return default.RuckusDescText;
        case "RuckusRespawnTime":   return default.RuckusRespawnDescText;
    }

    return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    KillBonusTime=5.000000
    bCapUDamageTime=True
    SpawnSoundRadius=1000.000000
    SpawnSound="AssaultSounds.AssaultRifle.Ceiling_Open_Close" // "WeaponSounds.item_respawn"
    bDefensiveUDamage=False
    DefensiveLightHue=128
    bRuckusMode=False
    RuckusRespawnTime=30.000000
    RuckusDisplayText="Ruckus Mode"
    RuckusDescText="Every armor charger, big health keg and wildcard base spawns UDamage instead, and armor lying loose in the map is removed. All UDamage respawns on the Ruckus respawn time, and UDamage time stacks without the 30-second cap. Everything else in this mutator applies to them."
    RuckusRespawnDisplayText="Ruckus UDamage Respawn Time"
    RuckusRespawnDescText="In Ruckus Mode, seconds before a taken UDamage respawns, stock UDamage chargers' included. The stock time is 90; small armor's is 30."
    DefensiveDisplayText="Defensive UDamage"
    DefensiveDescText="Instead of doubling the damage its holder deals, UDamage cuts the damage they take to a third, halves knockback from others, and stops self and fall damage. Off in Onslaught and Assault, where objectives would still take double damage."
    KillBonusDisplayText="UDamage Seconds Per Kill"
    CapDisplayText="Cap UDamage At 30 Seconds"
    SoundRadiusDisplayText="UDamage Respawn Sound Range"
    SoundDisplayText="UDamage Respawn Sound"
    KillBonusDescText="Seconds of UDamage time added when a player with UDamage gets a kill."
    CapDescText="Limit UDamage time gained from kills and dropped pickups to 30 seconds. When off, or in Ruckus Mode, the limit is 999 seconds."
    SoundRadiusDescText="How far away (in Unreal units) players can hear a UDamage respawn; the stock range is 300. 0 keeps the stock sound."
    SoundDescText="Sound played from the UDamage charger when UDamage respawns, as Package.Group.Name. The default is the stock pickup respawn sound."
    GroupName="UDamageReward"
    FriendlyName="UDamage Reward v2"
    Description="Remaining UDamage is dropped when its holder is fragged, and can be caught mid-air; kills made with UDamage add to its time, up to a cap; its respawn can be heard from farther away. Use instead of the stock UDamage Reward."
    bAddToServerPackages=True
}
