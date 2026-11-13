//==============================================================================
//  The stock pickup respawn effect without its sound; UDamageV2Pack plays
//  its own sound instead.
//==============================================================================

class UDamageRespawnEffect extends PlayerSpawnEffect;

simulated function PostBeginPlay()
{
    Super(Emitter).PostBeginPlay();
    if ( Level.NetMode == NM_DedicatedServer )
        LifeSpan = 0.15;
    else if ( Level.GetLocalPlayerController().BeyondViewDistance(Location, CullDistance) )
        LifeSpan = 0.01;
}

defaultproperties
{
}
