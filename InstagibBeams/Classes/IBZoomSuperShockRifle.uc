//==============================================================================
//  The zoom instagib rifle, firing IBZoomSuperShockBeamFire. Swapped in by
//  InstagibBeamsMutator; instagib keeps it, being a ZoomSuperShockRifle.
//==============================================================================

class IBZoomSuperShockRifle extends ZoomSuperShockRifle
    HideDropDown
    CacheExempt;

defaultproperties
{
    FireModeClass(0)=Class'InstagibBeams.IBZoomSuperShockBeamFire'
}
