//==============================================================================
//  The second, local-only layer of the tinted instagib beam (IBTintedBeam), as
//  stock's ExtraRedBeam is for the red one.
//==============================================================================

class IBExtraTintedBeam extends IBTintedBeam;

simulated function SpawnEffects()
{
    ApplyBeamSkin();
}

defaultproperties
{
    RemoteRole=ROLE_None
}
