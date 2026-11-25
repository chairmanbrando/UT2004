//==============================================================================
//  Spawned by CoDModeMutator with bLoadoutProvided. Weapon bases and lockers
//  are part of the map on each client, not sent by the server, so this hides
//  clients' copies of them as the server's are.
//==============================================================================

class CoDLoadoutInfo extends Info;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    if ( Level.NetMode == NM_Client )
        class'CoDModeMutator'.static.HideWeaponSpawners(self);
}

defaultproperties
{
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
}
