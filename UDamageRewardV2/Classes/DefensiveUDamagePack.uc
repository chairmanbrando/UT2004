//==============================================================================
//  UDamage pickup for chargers when UDamage is defensive: the same pickup, with
//  a message that says what it does now. A class of its own because clients
//  show the message from the pickup's class defaults (PlayerController.HandlePickup).
//  Drawn teal (DefensiveUDamageMaterials), on each client.
//==============================================================================

class DefensiveUDamagePack extends UDamageV2Pack
    notplaceable;

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
