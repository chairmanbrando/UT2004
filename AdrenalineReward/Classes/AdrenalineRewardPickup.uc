//==============================================================================
//  An adrenaline pickup thrown from a body: dropped like a weapon (as
//  Pickup.InitDroppedPickupFor), it stays StayTime seconds after landing
//  (the timer starts on the throw and restarts on landing), then fades out
//  (Pickup's FadeOut state, a second). Taken, it's gone (bDropped), not
//  respawned. LifeSpan, twice StayTime, is a backstop for ones that never land.
//
//  Pickup's FallingPickup and FadeOut states extend its base Pickup state, not
//  AdrenalinePickup's, so a touch while falling or fading ran the generic
//  Pickup.Touch: pickup sound and gone, but no adrenaline. Both get
//  AdrenalinePickup's Touch here.
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

// as AdrenalinePickup's Touch
function GiveAdrenalineTo(Pawn P)
{
    if ( P.Controller != None )
        P.Controller.AwardAdrenaline(AdrenalineAmount);
    AnnouncePickup(P);
    SetRespawn();
}

state FallingPickup
{
    function Touch( actor Other )
    {
        if ( ValidTouch(Other) )
            GiveAdrenalineTo(Pawn(Other));
    }

    function BeginState()
    {
        Super.BeginState();
        SetTimer(StayTime, false);
    }
}

state FadeOut
{
    function Touch( actor Other )
    {
        if ( ValidTouch(Other) )
            GiveAdrenalineTo(Pawn(Other));
    }
}

defaultproperties
{
    StayTime=8.000000
    RespawnTime=0.000000
}
