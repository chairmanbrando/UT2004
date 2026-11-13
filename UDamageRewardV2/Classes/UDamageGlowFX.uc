//==============================================================================
//  Spawned by UDamageV2Mutator; replicated to every client, where it adds
//  UDamageGlowInteraction to the local player's viewport so UDamage holders'
//  characters glow: purple, or teal when UDamage is defensive.
//==============================================================================

class UDamageGlowFX extends ReplicationInfo;

var bool bDefensive;

replication
{
    reliable if ( bNetInitial && Role == ROLE_Authority )
        bDefensive;
}

simulated function Tick(float DeltaTime)
{
    local PlayerController PC;
    local UDamageGlowInteraction I;

    if ( Level.NetMode == NM_DedicatedServer )
    {
        Disable('Tick');
        return;
    }

    PC = Level.GetLocalPlayerController();
    if ( PC == None || PC.Player == None || PC.Player.InteractionMaster == None )
        return;

    I = UDamageGlowInteraction(PC.Player.InteractionMaster.AddInteraction("UDamageRewardV2.UDamageGlowInteraction", PC.Player));
    if ( I != None )
        I.Init(bDefensive);
    Disable('Tick');
}

defaultproperties
{
}
