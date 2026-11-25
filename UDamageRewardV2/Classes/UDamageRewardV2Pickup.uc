//==============================================================================
//  Dropped UDamage pickup that caps the combined time it gives a player.
//  The stock UDamageReward adds its time to the player's with no limit.
//
//  Also fixes catching it mid-air: a dropped pickup is in state FallingPickup
//  until it lands, and Pickup's FallingPickup extends the base Pickup state, so
//  a touch there ran the generic Pickup.Touch instead of UDamageReward's. That
//  spawns an inventory copy (none for UDamage), announces the pickup and
//  removes it, so the catcher heard and saw the pickup but got no UDamage.
//
//  Destroyed without anyone taking it (lava, out of the world), it brings the
//  map's UDamage charger's respawn forward by the time it had left, when the
//  map has just the one and Ruckus Mode is off
//  (UDamageRewardV2Rules.GetSoleCharger).
//==============================================================================

class UDamageRewardV2Pickup extends UDamageReward;

var float MaxUDamageTime;
var bool bTaken;

function GiveUDamageTo(Pawn P)
{
    local float NewTime;

    NewTime = FadeTime - Level.TimeSeconds;

    // Add this pickup's remaining time to any UDamage time the pawn already had
    if ( xPawn(P) != None )
        NewTime += FMax( xPawn(P).UDamageTime - Level.TimeSeconds, 0 );

    P.EnableUDamage(FMin(NewTime, MaxUDamageTime));
    class'UDamageUtil'.static.AfterEnableUDamage(P);
    AnnouncePickup(P);
    SetRespawn();
}

// its sound through UDamageUtil.PlayUDamageSound, at the holder's and
// everyone else's volumes
function AnnouncePickup(Pawn Receiver)
{
    bTaken = true;
    Receiver.HandlePickup(self);
    class'UDamageUtil'.static.PlayUDamageSound(Receiver, PickupSound, TransientSoundRadius);
}

// Picked up, it's destroyed too (StartSleeping), so only an untaken one gives
// its time back. Running out of time, it has none left to give.
function Destroyed()
{
    local UDamageRewardV2Rules Rules;
    local UDamageV2Pack Charger;

    if ( !bTaken && Role == ROLE_Authority && Level.Game != None && !Level.Game.bGameEnded
        && FadeTime > Level.TimeSeconds )
    {
        Rules = class'UDamageUtil'.static.FindRules(self);
        if ( Rules != None )
            Charger = Rules.GetSoleCharger();
        if ( Charger != None )
            Charger.ShortenRespawn(FadeTime - Level.TimeSeconds);
    }
    Super.Destroyed();
}

auto state Pickup
{
    function Touch( actor Other )
    {
        if ( ValidTouch(Other) )
            GiveUDamageTo(Pawn(Other));
    }
}

state FallingPickup
{
    function Touch( actor Other )
    {
        if ( ValidTouch(Other) )
            GiveUDamageTo(Pawn(Other));
    }
}

defaultproperties
{
    MaxUDamageTime=30.000000
}
