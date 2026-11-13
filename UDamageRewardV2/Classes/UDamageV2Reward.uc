//==============================================================================
//  Dropped UDamage pickup that caps the combined time it gives a player.
//  The stock UDamageReward adds its time to the player's with no limit.
//
//  Also fixes catching it mid-air: a dropped pickup is in state FallingPickup
//  until it lands, and Pickup's FallingPickup extends the base Pickup state, so
//  a touch there ran the generic Pickup.Touch instead of UDamageReward's. That
//  spawns an inventory copy (none for UDamage), announces the pickup and
//  removes it, so the catcher heard and saw the pickup but got no UDamage.
//==============================================================================

class UDamageV2Reward extends UDamageReward;

var float MaxUDamageTime;

function GiveUDamageTo(Pawn P)
{
    local float NewTime;

    NewTime = FadeTime - Level.TimeSeconds;

    // Add this pickup's remaining time to any UDamage time the pawn already had
    if ( xPawn(P) != None )
        NewTime += FMax( xPawn(P).UDamageTime - Level.TimeSeconds, 0 );

    P.EnableUDamage(FMin(NewTime, MaxUDamageTime));
    class'UDamageUtil'.static.ResetWarningIfExtended(P);
    AnnouncePickup(P);
    SetRespawn();
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
