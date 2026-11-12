//==============================================================================
//  An adrenaline pickup thrown from a body: dropped like a weapon (as
//  Pickup.InitDroppedPickupFor), it stays StayTime seconds after landing
//  (the timer starts on the throw and restarts on landing), then fades out
//  (Pickup's FadeOut state, a second). Taken, it's gone (bDropped), not
//  respawned. LifeSpan, twice StayTime, is a backstop for ones that never land.
//==============================================================================

class AdrenalineRewardPickup extends AdrenalinePickup;

var float StayTime;

function InitDrop(float Seconds)
{
    StayTime = Seconds;                 // before FallingPickup's BeginState sets its timer
    SetPhysics(PHYS_Falling);
    GotoState('FallingPickup');
    bDropped = true;
    bAlwaysRelevant = false;
    bOnlyReplicateHidden = false;
    bUpdateSimulatedPosition = true;
    bIgnoreEncroachers = false;         // lands on lifts
    bIgnoreVehicles = true;
    LifeSpan = 2 * Seconds;
}

auto state Pickup
{
    function BeginState()
    {
        Super.BeginState();
        if ( bDropped )
            SetTimer(StayTime, false);
    }
}

state FallingPickup
{
    function BeginState()
    {
        Super.BeginState();
        SetTimer(StayTime, false);
    }
}

defaultproperties
{
    StayTime=8.000000
    RespawnTime=0.000000
}
