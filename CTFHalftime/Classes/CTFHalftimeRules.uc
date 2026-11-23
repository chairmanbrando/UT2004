//==============================================================================
//  Nobody takes damage during the halftime freeze (CTFHalftimeMutator): the
//  frozen pawns can't dodge whatever's still around them (lava, a closing
//  door), and a death then would score.
//==============================================================================

class CTFHalftimeRules extends GameRules;

var bool bFrozen;

function int NetDamage(int OriginalDamage, int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    if ( bFrozen )
    {
        Momentum = vect(0,0,0);
        return 0;
    }
    return Super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
}

defaultproperties
{
}
