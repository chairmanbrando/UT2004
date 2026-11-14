//==============================================================================
//  Dropped UDamage pickup when UDamage is defensive: with a message that says
//  what it does now, drawn teal (see DefensiveUDamagePack).
//==============================================================================

class DefensiveUDamageReward extends UDamageRewardV2Pickup;

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();
    if ( Level.NetMode != NM_DedicatedServer )
        Skins[0] = class'DefensiveUDamageMaterials'.static.MakePickupSkin();
}

defaultproperties
{
    PickupMessage="DAMAGE RESISTANCE!"
}
