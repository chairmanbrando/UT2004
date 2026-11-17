//==============================================================================
//  Adrenaline Reward's game rules: a player killed by another (not a suicide)
//  throws ThrowPercent of their adrenaline from their body as one pickup per
//  PickupAmount (any remainder is lost), and loses the rest too unless
//  bKeepUnthrown.
//==============================================================================

class AdrenalineRewardRules extends GameRules;

var MutAdrenalineReward Mut;

function ScoreKill(Controller Killer, Controller Killed)
{
    local int Amount, Thrown, n;

    if ( Killer != None && Killed != None && Killer != Killed && Killed.Adrenaline > 0 )
    {
        Amount = Mut.GetPickupAmount();
        Thrown = int(Killed.Adrenaline) * Mut.GetThrowPercent() / 100;
        n = Thrown / Amount;
        if ( Mut.bKeepUnthrown )
            Killed.Adrenaline -= Thrown;
        else
            Killed.Adrenaline -= int(Killed.Adrenaline);
        if ( n > 0 )
            ThrowAdrenaline(xPawn(Killed.Pawn), n, Amount);
    }
    Super.ScoreKill(Killer, Killed);
}

// n pickups from P's middle, each tossed its own way
function ThrowAdrenaline(xPawn P, int n, int Amount)
{
    local AdrenalineRewardPickup A;
    local int i;

    if ( P == None )
        return;
    for ( i = 0; i < n; i++ )
    {
        A = Spawn(class'AdrenalineRewardPickup',,, P.Location);
        if ( A == None )
            continue;
        A.AdrenalineAmount = Amount;
        A.Velocity = ThrowVelocity(P);
        A.InitDrop(Mut.MyLifeSpan);
    }
}

// A random direction across the ground, 50-399 out (plus the body's own speed
// that way) and 50-699 up
function vector ThrowVelocity(Pawn P)
{
    local rotator R;
    local vector V;

    R.Yaw = Rand(65536);
    V = vector(R);
    V *= (P.Velocity dot V) + Rand(350) + 50;
    V.Z = Rand(650) + 50;
    return V;
}

defaultproperties
{
}
