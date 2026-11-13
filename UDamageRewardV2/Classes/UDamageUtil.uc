//==============================================================================
//  The "UDamage ending" warning is played by xPawn's UDamageTimer: its timer
//  fires 3 seconds before UDamage runs out and plays the sound 4 times,
//  counting in SoundCount. EnableUDamage reschedules the timer when UDamage is
//  extended but never resets that count, so after an extension out of the
//  warning period, the next warning resumed where the last one stopped.
//  Call this after EnableUDamage to make the next warning start fresh.
//==============================================================================

class UDamageUtil extends Object;

static function ResetWarningIfExtended(Pawn P)
{
    local xPawn X;

    X = xPawn(P);
    if ( X != None && X.UDamageTimer != None
        && X.UDamageTime - X.Level.TimeSeconds > 3 )
        X.UDamageTimer.SoundCount = 0;
}
