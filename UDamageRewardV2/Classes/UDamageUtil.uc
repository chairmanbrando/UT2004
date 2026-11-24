//==============================================================================
//  UDamage helpers.
//  AfterEnableUDamage: call after each EnableUDamage. It swaps xPawn's stock
//  UDamageTimer, which plays the "UDamage ending" warning, for ours
//  (UDamageV2Timer), keeping its count and time left; EnableUDamage reuses
//  whichever timer the pawn has. And it makes the next warning start fresh:
//  the timer fires 3 seconds before UDamage runs out and plays the sound 4
//  times, counting in SoundCount, and EnableUDamage reschedules it when
//  UDamage is extended but never resets that count, so after an extension
//  out of the warning period, the next warning resumed where the last one
//  stopped.
//  PlayUDamageSound: the pickup and warning sounds, at two volumes: the
//  holder's own copy (HolderSoundVolume), which plays right at their ears,
//  and everyone else's (UDamageSoundVolume), from the holder, in 3D.
//==============================================================================

class UDamageUtil extends Object;

static function AfterEnableUDamage(Pawn P)
{
    local xPawn X;
    local UDamageV2Timer T;

    X = xPawn(P);
    if ( X == None || X.UDamageTimer == None )
        return;

    if ( UDamageV2Timer(X.UDamageTimer) == None )
    {
        T = X.Spawn(class'UDamageV2Timer', X);
        if ( T != None )
        {
            T.SoundCount = X.UDamageTimer.SoundCount;
            T.SetTimer(FMax(X.UDamageTimer.TimerRate - X.UDamageTimer.TimerCounter, 0.01), false);
            X.UDamageTimer.Destroy();
            X.UDamageTimer = T;
        }
    }

    if ( X.UDamageTime - X.Level.TimeSeconds > 3 )
        X.UDamageTimer.SoundCount = 0;
}

// the UDamage pickup and warning sound, stock's or ours (Unclipped UDamage
// Sound)
static function Sound UDamageSound()
{
    if ( class'UDamageRewardV2Mutator'.default.bUnclippedUDamageSound )
        return Sound'UDamageRewardV2.UDamagePickup';
    return Sound'PickupSounds.UDamagePickup';
}

// S from Holder, heard by everyone within Radius. A player holder hears their
// own copy instead: sent to their client (ClientPlaySound), the 3D one
// skipping them (PlayOwnedSound). A local one (offline, or hosting) can't be
// skipped, so everyone hears theirs, at the holder's volume.
static function PlayUDamageSound(Pawn Holder, Sound S, float Radius)
{
    local PlayerController PC;
    local float HolderVolume, OthersVolume;

    if ( Holder == None || S == None )
        return;
    HolderVolume = class'UDamageRewardV2Mutator'.default.HolderSoundVolume;
    OthersVolume = class'UDamageRewardV2Mutator'.default.UDamageSoundVolume;

    PC = PlayerController(Holder.Controller);
    if ( PC == None )
        Holder.PlaySound(S, SLOT_None, OthersVolume, false, Radius);
    else if ( Viewport(PC.Player) != None )
        Holder.PlaySound(S, SLOT_None, HolderVolume, false, Radius);
    else
    {
        Holder.PlayOwnedSound(S, SLOT_None, OthersVolume, false, Radius);
        PC.ClientPlaySound(S, true, HolderVolume, SLOT_None);
    }
}
