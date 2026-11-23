//==============================================================================
//  The halftime pause's countdown (CTFHalftimeMutator): the stock TimerMessage
//  ("N..."), but the announcer only counts the last few (MaxVoiced), since
//  with halftime a match has two countdowns more than a normal one.
//==============================================================================

class CTFHalftimeCountdown extends TimerMessage;

var int MaxVoiced;

static function ClientReceive(PlayerController P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
    // TimerMessage's own voices up to 10
    Super(CriticalEventPlus).ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

    if ( Switch > 0 && Switch <= default.MaxVoiced && P.GameReplicationInfo != None && P.GameReplicationInfo.Winner == None )
        P.QueueAnnouncement(default.CountDown[Switch - 1], 1, AP_InstantOrQueueSwitch, 1);
}

defaultproperties
{
    MaxVoiced=5
}
