//==============================================================================
//  Carries the server's halftime text (CTFHalftimeMutator.HalftimeText) to
//  clients, passed along with the halftime message (CTFHalftimeMessage), which
//  is drawn client-side from static text otherwise. Spawned by the mutator at
//  the start, so it's on every client well before halftime.
//==============================================================================

class CTFHalftimeTextInfo extends ReplicationInfo;

var string HalftimeText;

replication
{
    reliable if ( bNetInitial && Role == ROLE_Authority )
        HalftimeText;
}

defaultproperties
{
    bAlwaysRelevant=True
}