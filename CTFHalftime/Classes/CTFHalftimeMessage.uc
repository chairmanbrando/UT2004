//==============================================================================
//  Halftime announcements (CTFHalftimeMutator): switch 0, halftime (the
//  server's HalftimeText, carried by a CTFHalftimeTextInfo); 1 + a
//  team index, the second half, naming the team the player is now on (by
//  switch, since their new team may not have reached them yet); 100 + N, the
//  warning, once, N seconds before halftime. The countdown itself is
//  CTFHalftimeCountdown.
//==============================================================================

class CTFHalftimeMessage extends CriticalEventPlus;

var localized string HalftimeText, SecondHalfText, SecondHalfTrailer, WarningText, WarningTrailer;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    if ( Switch >= 100 )
        return default.WarningText @ (Switch - 100) @ default.WarningTrailer;
    if ( Switch == 0 )
    {
        // the server's text, if set (CTFHalftimeMutator.HalftimeText)
        if ( CTFHalftimeTextInfo(OptionalObject) != None && CTFHalftimeTextInfo(OptionalObject).HalftimeText != "" )
            return CTFHalftimeTextInfo(OptionalObject).HalftimeText;
        return default.HalftimeText;
    }
    return default.SecondHalfText @ class'TeamInfo'.default.ColorNames[Clamp(Switch - 1, 0, 3)] $ default.SecondHalfTrailer;
}

defaultproperties
{
    WarningText="Halftime approaches! Teams are switching sides in"
    WarningTrailer="seconds."
    // where CTF's own messages go (CTFMessage), as does the stock countdown;
    // none of those come up during halftime
    StackMode=SM_Down
    PosY=0.100000
    HalftimeText="HALFTIME"
    SecondHalfText="Second half! You're"
    SecondHalfTrailer=" now."
    Lifetime=4
    DrawColor=(B=0,G=255,R=255,A=255)
}
