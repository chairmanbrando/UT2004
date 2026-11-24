//==============================================================================
//  Zoom instagib rifle fire through IBUtil.FireBeam: piercing players (with
//  bPierce, whatever the stock bAllowMultiHit says), drawn as one beam in the
//  team's or the set colour. Stock pierces too, but spawns a beam per victim.
//==============================================================================

class IBZoomSuperShockBeamFire extends ZoomSuperShockBeamFire;

// players one shot can pierce, a safety cap
var int MaxPierces;

function DoTrace(vector Start, rotator Dir)
{
    class'IBUtil'.static.FireBeam(self, Start, Dir, MaxPierces);
}

defaultproperties
{
    MaxPierces=16
}
