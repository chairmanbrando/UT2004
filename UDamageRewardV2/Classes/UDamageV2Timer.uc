//==============================================================================
//  The "UDamage ending" warning, as stock's UDamageTimer plays it (4 times,
//  0.75s apart, from 3 seconds before UDamage runs out, then ends it), but
//  through UDamageUtil.PlayUDamageSound: the sound and volumes are this
//  mutator's settings. Swapped in for the stock one by
//  UDamageUtil.AfterEnableUDamage.
//==============================================================================

class UDamageV2Timer extends UDamageTimer;

function Timer()
{
    if ( Pawn(Owner) == None )
    {
        Destroy();
        return;
    }
    if ( SoundCount < 4 )
    {
        SoundCount++;
        class'UDamageUtil'.static.PlayUDamageSound(Pawn(Owner), class'UDamageUtil'.static.UDamageSound(), 1000);
        SetTimer(0.75, false);
        return;
    }
    Pawn(Owner).DisableUDamage();
    Destroy();
}
