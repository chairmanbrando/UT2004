//==============================================================================
//  Game rules for Damage Numbers: works out what each hit by a human player
//  took from its target and, once the frame's hits are done, sends them the
//  total through their DamageNumbersInfo.
//  The damage isn't final in NetDamage (the game type still scales it, e.g.
//  UDamage, and armor takes its share after), so a hit's damage is what the
//  target's health plus armor lost between it and the next hit on the target
//  (by anyone, or anything: bots and lava too, which aren't shown) or the end
//  of the frame. Measuring from a player's first hit to the end of the frame
//  instead would count others' hits in between as theirs. Overkill is
//  included: health goes below 0.
//==============================================================================

class DamageNumbersRules extends GameRules;

// the last hit on a target this frame, still taking effect
struct LastHit
{
    var Pawn Victim;
    var PlayerController PC;    // None if not a human player's
    var int Before;             // health plus armor before it
    var int Dealt;              // its damage as known here, if the target's gone (gibbed)
    var vector Loc;             // above its head
    var byte Kind;              // DamageNumbersOverlay's colour: 1 UDamage, 2 defensive UDamage
};
var array<LastHit> LastHits;

// a player's damage to a target this frame
struct HitTotal
{
    var Pawn Victim;
    var PlayerController PC;
    var int Amount;
    var vector Loc;
    var byte Kind;
};
var array<HitTotal> Totals;

var array<DamageNumbersInfo> DamageNumbersInfos;

// UDamage Reward v2's defensive UDamage: its holder takes less damage instead of
// dealing double. Read from its game rules by name, so as not to need its
// package; checked once, at the first hit.
var bool bCheckedDefensiveUDamage, bDefensiveUDamage;

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    if ( NextGameRules != None )
        Damage = NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );

    NoteHit(injured, instigatedBy, Damage);
    return Damage;
}

// Settles the target's previous hit this frame (now taken effect), then
// notes this one's starting point
function NoteHit(Pawn Injured, Pawn InstigatedBy, int Damage)
{
    local PlayerController PC;
    local int i;

    if ( Injured == None || Injured.Health <= 0 )
        return;

    for ( i = 0; i < LastHits.Length; i++ )
        if ( LastHits[i].Victim == Injured )
            break;
    if ( i < LastHits.Length )
        Settle(i);
    else
    {
        LastHits.Length = i + 1;
        LastHits[i].Victim = Injured;
    }

    if ( InstigatedBy != None && InstigatedBy != Injured )
        PC = PlayerController(InstigatedBy.Controller);
    if ( PC == Injured.Controller )
        PC = None;
    LastHits[i].PC = PC;
    LastHits[i].Before = Injured.Health + Injured.ShieldStrength;
    if ( PC != None )
    {
        LastHits[i].Dealt = Damage * InstigatedBy.DamageScaling;
        LastHits[i].Kind = DamageKind(Injured, InstigatedBy);
        LastHits[i].Loc = Injured.Location + (Injured.CollisionHeight + 16) * vect(0,0,1);
    }
    Enable('Tick');
}

// what LastHits[i] took, added to its player's total
function Settle(int i)
{
    local PlayerController PC;
    local Pawn V;
    local int Amount, t;

    PC = LastHits[i].PC;
    if ( PC == None )
        return;
    LastHits[i].PC = None;      // settled
    V = LastHits[i].Victim;
    if ( V != None && !V.bDeleteMe )
        Amount = LastHits[i].Before - (V.Health + V.ShieldStrength);
    else
        Amount = LastHits[i].Dealt;
    if ( Amount <= 0 )
        return;

    for ( t = 0; t < Totals.Length; t++ )
        if ( Totals[t].Victim == LastHits[i].Victim && Totals[t].PC == PC )
            break;
    if ( t == Totals.Length )
    {
        Totals.Length = t + 1;
        Totals[t].Victim = LastHits[i].Victim;
        Totals[t].PC = PC;
    }
    Totals[t].Amount += Amount;
    Totals[t].Loc = LastHits[i].Loc;
    Totals[t].Kind = LastHits[i].Kind;
}

// the colour of a damage number: UDamage purple when the attacker's damage is
// doubled by it, defensive UDamage teal when the target's is cut by it
function byte DamageKind(Pawn Injured, Pawn InstigatedBy)
{
    local GameRules G;

    if ( !bCheckedDefensiveUDamage )
    {
        bCheckedDefensiveUDamage = true;
        for ( G = Level.Game.GameRulesModifiers; G != None; G = G.NextGameRules )
            if ( G.IsA('UDamageRewardV2Rules') && G.GetPropertyText("bDefensive") ~= "True" )
                bDefensiveUDamage = true;
    }

    if ( bDefensiveUDamage )
    {
        if ( Injured.HasUDamage() )
            return 2;
    }
    else if ( InstigatedBy.HasUDamage() )
        return 1;
    return 0;
}

// the frame's hits are done: settle the last on each target, send the totals
function Tick(float DeltaTime)
{
    local Pawn V;
    local int i;

    for ( i = 0; i < LastHits.Length; i++ )
        Settle(i);
    for ( i = 0; i < Totals.Length; i++ )
    {
        if ( Totals[i].PC == None )
            continue;
        V = Totals[i].Victim;
        if ( V != None && V.bDeleteMe )
            V = None;
        GetDamageNumbersInfo(Totals[i].PC).ClientShowDamage(V, Totals[i].Loc, Totals[i].Amount, Totals[i].Kind);
    }
    LastHits.Length = 0;
    Totals.Length = 0;
    Disable('Tick');
}

// PC's DamageNumbersInfo, spawned the first time it's needed
function DamageNumbersInfo GetDamageNumbersInfo(PlayerController PC)
{
    local int i;

    for ( i = DamageNumbersInfos.Length - 1; i >= 0; i-- )
    {
        if ( DamageNumbersInfos[i] == None || DamageNumbersInfos[i].Owner == None )
        {
            if ( DamageNumbersInfos[i] != None )
                DamageNumbersInfos[i].Destroy();
            DamageNumbersInfos.Remove(i, 1);
        }
        else if ( DamageNumbersInfos[i].Owner == PC )
            return DamageNumbersInfos[i];
    }
    i = DamageNumbersInfos.Length;
    DamageNumbersInfos[i] = Spawn(class'DamageNumbersInfo', PC);
    return DamageNumbersInfos[i];
}

defaultproperties
{
}
