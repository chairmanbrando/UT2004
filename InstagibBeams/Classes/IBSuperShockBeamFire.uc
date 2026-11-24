//==============================================================================
//  Instagib rifle fire through IBUtil.FireBeam: piercing players (with
//  bPierce), drawn as one beam in the team's or the set colour.
//==============================================================================

class IBSuperShockBeamFire extends SuperShockBeamFire;

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
