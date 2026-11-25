//==============================================================================
//  Game rules for UDamage Reward v2. Extends the stock UDamage Reward rules,
//  which drop a fragged player's remaining UDamage: UDamage holders gain time
//  for kills, and dropped UDamage pickups respect the configured time cap.
//==============================================================================

class UDamageRewardV2Rules extends UDamageRules;

var float KillBonusTime;
var float MaxUDamageTime;
var bool bDefensive;		// UDamage protects its holder instead of doubling the damage they deal
var float DefensiveDamageScale;	// damage a defensive UDamage holder takes from others and the world
var float DefensiveMomentumScale;	// knockback they take from others

// The map's one UDamage charger pickup, which a dropped UDamage destroyed
// unclaimed gives its time back to (UDamageRewardV2Pickup.Destroyed). None
// with Ruckus Mode, or with no charger or several.
var bool bRuckusMode;
var bool bChargerChecked;
var UDamageV2Pack SoleCharger;

// Pawn.TakeDamage and Vehicle.TakeDamage double a UDamage holder's damage
// before ReduceDamage, so by here it's already doubled; shields are taken off
// after (xPawn.ShieldAbsorb). Defensive UDamage takes the doubling back, and
// its holder takes no self or fall damage (free rocket and shield jumps), a
// third of other damage, and half the knockback from others.
// Objectives and power cores double it without passing through here, so
// UDamageRewardV2Mutator leaves it off in Onslaught and Assault.
function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    if ( bDefensive )
    {
        if ( instigatedBy != None && instigatedBy.HasUDamage() )
            Damage = Round(Damage * 0.5);
        if ( injured != None && injured.HasUDamage() )
        {
            if ( injured == instigatedBy || DamageType == class'Fell' )
                Damage = 0;
            else
            {
                Damage = Round(Damage * DefensiveDamageScale);
                if ( instigatedBy != None )
                    Momentum *= DefensiveMomentumScale;
            }
        }
    }

    if ( NextGameRules != None )
        return NextGameRules.NetDamage( OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType );
    return Damage;
}

function ScoreKill(Controller Killer, Controller Killed)
{
    local xPawn P;

    if ( Killer != None && Killer != Killed && Killed != None && Killer.Pawn != None
        && !(Level.Game.bTeamGame && Killer.GetTeamNum() == Killed.GetTeamNum()) )
    {
        // UDamage stays on the driver while in a vehicle
        P = xPawn(Killer.Pawn);
        if ( P == None && Vehicle(Killer.Pawn) != None )
            P = xPawn(Vehicle(Killer.Pawn).Driver);

        // EnableUDamage never lowers the time, so holders already over the cap keep it
        if ( P != None && P.HasUDamage() )
        {
            P.EnableUDamage(FMin(P.UDamageTime - Level.TimeSeconds + KillBonusTime, MaxUDamageTime));
            class'UDamageUtil'.static.AfterEnableUDamage(P);
        }
    }

    // stock behaviour: drop the victim's remaining UDamage
    Super.ScoreKill(Killer, Killed);
}

// Same as UDamageRules.ThrowUDamage, but spawns a UDamageRewardV2Pickup that knows the cap
function ThrowUDamage( Controller Killer, xPawn Killed )
{
    local vector tossdir, x, y, z;
    local UDamageRewardV2Pickup Reward;

    if ( Killer == None || Killed == None )
        return;

    if ( bDefensive )
        Reward = Spawn( class'DefensiveUDamageReward', , , Killed.Location );
    else
        Reward = Spawn( class'UDamageRewardV2Pickup', , , Killed.Location );
    if ( Reward == None )
        return;

    tossdir = GetThrowVector(Killer, Killed);

    Killed.GetAxes(Killed.Rotation, X,Y,Z);
    Reward.SetLocation( Killed.Location + 0.8 * Killed.CollisionRadius * X + -0.5 * Killed.CollisionRadius * Y );
    Reward.velocity = tossdir;

    Reward.MaxUDamageTime = MaxUDamageTime;
    Reward.InitDrop(Killed.UDamageTime - Level.TimeSeconds);
}

// Looked for once: chargers' pickups exist from the start of the level,
// sleeping when taken, and stay through resets. Wildcard bases' come and go,
// so don't count.
function UDamageV2Pack GetSoleCharger()
{
    local UDamageV2Pack P;
    local int Count;

    if ( bRuckusMode )
        return None;
    if ( !bChargerChecked )
    {
        bChargerChecked = true;
        foreach DynamicActors(class'UDamageV2Pack', P)
            if ( P.PickupBase != None && WildcardBase(P.PickupBase) == None )
            {
                Count++;
                SoleCharger = P;
            }
        if ( Count != 1 )
            SoleCharger = None;
    }
    if ( SoleCharger != None && SoleCharger.bDeleteMe )
        SoleCharger = None;
    return SoleCharger;
}

defaultproperties
{
    KillBonusTime=5.000000
    MaxUDamageTime=30.000000
    DefensiveDamageScale=0.333333
    DefensiveMomentumScale=0.500000
}
