//==============================================================================
//  Tells CoDModeMutator when a player is hit, after every other rule has had
//  its say on the damage, so its regen stops and the wait starts over.
//==============================================================================

class CoDModeRules extends GameRules;

var CoDModeMutator Mut;

function int NetDamage(int OriginalDamage, int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    if ( NextGameRules != None )
        Damage = NextGameRules.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
    if ( Damage > 0 && Mut != None && Injured != None && Vehicle(Injured) == None )
        Mut.NotifyHit(Injured);
    return Damage;
}
