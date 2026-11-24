//==============================================================================
//  The instagib rifle, firing IBSuperShockBeamFire. Swapped in by
//  InstagibBeamsMutator; instagib keeps it, being a SuperShockRifle.
//==============================================================================

class IBSuperShockRifle extends SuperShockRifle
    HideDropDown
    CacheExempt;

defaultproperties
{
    FireModeClass(0)=Class'InstagibBeams.IBSuperShockBeamFire'
    FireModeClass(1)=Class'InstagibBeams.IBSuperShockBeamFire'
}
