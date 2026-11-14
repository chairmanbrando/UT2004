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
//  Kill and damage handling is in the game rules class 'UDamageRewardV2Rules'.
//==============================================================================

class UDamageRewardV2Mutator extends Mutator
    config;

var config float KillBonusTime;		// seconds of UDamage added per kill
var config bool bCapUDamageTime;	// cap at 30s like a stock pickup; otherwise 999s
var config float SpawnSoundRadius;	// range of the UDamage respawn sound; 0 keeps the stock sound
var config string SpawnSound;
var config bool bDefensiveUDamage;	// UDamage protects its holder instead of doubling damage dealt
var byte DefensiveLightHue;		// teal

var localized string KillBonusDisplayText, CapDisplayText, KillBonusDescText, CapDescText;
var localized string DefensiveDisplayText, DefensiveDescText;
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
    if ( bCapUDamageTime )
        G.MaxUDamageTime = 30;
    else
        G.MaxUDamageTime = 999;
    Level.Game.AddGameModifier(G);
}

// Called from each actor's PreBeginPlay: before UDamage chargers spawn their
// pickups (PostBeginPlay)
function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    if ( xPickupBase(Other) != None && xPickupBase(Other).PowerUp == class'UDamagePack' )
    {
        if ( bDefensiveUDamage )
            xPickupBase(Other).PowerUp = class'DefensiveUDamagePack';
        else
            xPickupBase(Other).PowerUp = class'UDamageV2Pack';
    }
    else if ( UDamageV2Pack(Other) != None )
    {
        UDamageV2Pack(Other).SpawnSoundName = SpawnSound;
        UDamageV2Pack(Other).SpawnSoundRadius = SpawnSoundRadius;
    }
    // the light around a UDamage holder (xPawn.EnableUDamage), teal for
    // defensive UDamage; stock is purple (204)
    else if ( bDefensiveUDamage && xPawn(Other) != None )
        xPawn(Other).LightHue = DefensiveLightHue;

    return true;
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);

    PlayInfo.AddSetting(default.RulesGroup, "KillBonusTime", default.KillBonusDisplayText, 0, 1, "Text", "3;0:999");
    PlayInfo.AddSetting(default.RulesGroup, "bCapUDamageTime", default.CapDisplayText, 0, 1, "Check");
    PlayInfo.AddSetting(default.RulesGroup, "SpawnSoundRadius", default.SoundRadiusDisplayText, 0, 1, "Text", "6;0:100000");
    PlayInfo.AddSetting(default.RulesGroup, "SpawnSound", default.SoundDisplayText, 0, 1, "Text", "64");
    PlayInfo.AddSetting(default.RulesGroup, "bDefensiveUDamage", default.DefensiveDisplayText, 0, 1, "Check");
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
    DefensiveDisplayText="Defensive UDamage"
    DefensiveDescText="Instead of doubling the damage its holder deals, UDamage cuts the damage they take to a third, halves knockback from others, and stops self and fall damage. Off in Onslaught and Assault, where objectives would still take double damage."
    KillBonusDisplayText="UDamage Seconds Per Kill"
    CapDisplayText="Cap UDamage At 30 Seconds"
    SoundRadiusDisplayText="UDamage Respawn Sound Range"
    SoundDisplayText="UDamage Respawn Sound"
    KillBonusDescText="Seconds of UDamage time added when a player with UDamage gets a kill."
    CapDescText="Limit UDamage time gained from kills and dropped pickups to 30 seconds. When off, the limit is 999 seconds."
    SoundRadiusDescText="How far away (in Unreal units) players can hear a UDamage respawn; the stock range is 300. 0 keeps the stock sound."
    SoundDescText="Sound played from the UDamage charger when UDamage respawns, as Package.Group.Name. The default is the stock pickup respawn sound."
    GroupName="UDamageReward"
    FriendlyName="UDamage Reward v2"
    Description="Remaining UDamage is dropped when its holder is fragged, and can be caught mid-air; kills made with UDamage add to its time, up to a cap; its respawn can be heard from farther away. Use instead of the stock UDamage Reward."
    bAddToServerPackages=True
}
