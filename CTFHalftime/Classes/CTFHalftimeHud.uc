//==============================================================================
//  The stock CTF HUD, with the announcer's time callouts counted down to the
//  end of the current half rather than of the match, and fewer of them: 5 and
//  2 minutes, 30 seconds, then 5 to 1 (stock adds 3 minutes, 1 minute and 20
//  seconds, and counts from 10). A callout as long as the half or longer isn't played, nor is
//  anything at a half's start or during the halftime freeze, when the clock
//  holds at the full second half.
//  Halftime is at half the time limit (CTFHalftimeMutator), so in the first
//  half the time to it is the time left less a half's length; in the second
//  half, it's just the time left. Set as the game's HUD by the mutator, only
//  in place of the stock one.
//==============================================================================

class CTFHalftimeHud extends HudCCaptureTheFlag;

function CheckCountdown(GameReplicationInfo GRI)
{
    local int Half, Left;

    if ( GRI == None || GRI.RemainingTime == 0 || GRI.RemainingTime == OldRemainingTime || GRI.Winner != None )
        return;
    OldRemainingTime = GRI.RemainingTime;

    Half = GRI.TimeLimit * 30;
    if ( Half <= 0 )
        return;
    Left = OldRemainingTime;
    if ( Left > Half )
        Left -= Half;
    if ( Left >= Half )
        return;

    if ( Left == 300 )
        PlayerOwner.PlayStatusAnnouncement(LongCountName[0], 1, true);     // 5 minute warning
    else if ( Left == 120 )
        PlayerOwner.PlayStatusAnnouncement(LongCountName[2], 1, true);     // 2 minutes remain
    else if ( Left == 30 )
        PlayerOwner.PlayStatusAnnouncement(LongCountName[4], 1, true);     // 30 seconds remain
    else if ( Left <= 5 && Left > 0 )
        PlayerOwner.PlayStatusAnnouncement(CountDownName[Left - 1], 1, true);
}

defaultproperties
{
}
