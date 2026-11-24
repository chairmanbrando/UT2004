//==============================================================================
//  UDamage pickup for chargers. Replaces the stock respawn sound (played
//  client-side by PlayerSpawnEffect with the default 0.3 volume and 300 radius)
//  with a louder, longer-range one played from the server. Picking it up while
//  your UDamage warning is playing restarts the next warning from the top
//  (UDamageUtil).
//  On a wildcard charger, which swaps its pickup for a random one only after
//  the old one's respawn effect, the old one's effect would go with whatever
//  comes next: there, this keeps the stock effect, and plays its own sound as
//  it arrives instead (state Pickup), so only UDamage gets it.
//  Its pickup sound plays through UDamageUtil.PlayUDamageSound, at the
//  holder's and everyone else's volumes.
//  Imports our unclipped UDamage sound (Sounds\UDamagePickup.wav, from
//  MakeUDamagePickup.ps1), used with the Unclipped UDamage Sound setting
//  (UDamageUtil.UDamageSound); and its reverse (UDamagePickupRev), for the
//  SpawnSound setting.
//==============================================================================

class UDamageV2Pack extends UDamagePack
    notplaceable;

#exec AUDIO IMPORT FILE=Sounds\UDamagePickup.wav NAME=UDamagePickup
#exec AUDIO IMPORT FILE=Sounds\UDamagePickupRev.wav NAME=UDamagePickupRev

var string SpawnSoundName;	// set by UDamageRewardV2Mutator
var float SpawnSoundRadius;	// 0 keeps the stock respawn effect and sound
var float SpawnSoundVolume;
var Sound SpawnSound;
var bool bStackTime;		// set by UDamageRewardV2Mutator in Ruckus Mode: adds to the holder's time, up to MaxStackTime
var float MaxStackTime;

// SpawnSound, loaded from SpawnSoundName the first time; None if it's off or
// won't load
function Sound GetSpawnSound()
{
    if ( SpawnSound == None && SpawnSoundName != "" && SpawnSoundRadius > 0 )
    {
        SpawnSound = Sound(DynamicLoadObject(SpawnSoundName, class'Sound', true));
        if ( SpawnSound == None )
        {
            log(self$" couldn't load SpawnSound '"$SpawnSoundName$"', using the stock respawn sound");
            SpawnSoundName = "";
        }
    }
    return SpawnSound;
}

function PlaySpawnSound()
{
    local Actor Source;

    // the charger base is visible and present on clients; the pickup may still be hidden here
    Source = PickupBase;
    if ( Source == None )
        Source = self;
    Source.PlaySound(SpawnSound, SLOT_None, SpawnSoundVolume, false, SpawnSoundRadius);
}

function RespawnEffect()
{
    if ( WildcardBase(PickupBase) != None || GetSpawnSound() == None )
    {
        Super.RespawnEffect();
        return;
    }

    spawn(class'UDamageRespawnEffect');
    PlaySpawnSound();
}

function AnnouncePickup(Pawn Receiver)
{
    Receiver.HandlePickup(self);
    class'UDamageUtil'.static.PlayUDamageSound(Receiver, PickupSound, TransientSoundRadius);
}

// same as UDamagePack's, plus the warning reset and, in Ruckus Mode, stacking
// (stock tops the holder up to 30s instead)
auto state Pickup
{
    function Touch( actor Other )
    {
        local Pawn P;
        local float Time;

        if ( ValidTouch(Other) )
        {
            P = Pawn(Other);
            Time = 30;
            if ( bStackTime && xPawn(P) != None )
                Time = FMin(Time + FMax(xPawn(P).UDamageTime - Level.TimeSeconds, 0), MaxStackTime);
            P.EnableUDamage(Time);
            class'UDamageUtil'.static.AfterEnableUDamage(P);
            AnnouncePickup(P);
            SetRespawn();
        }
    }

// Pickup's, plus, on a wildcard charger, the respawn sound: this has just
// arrived (Pickup.Transmogrify; its base is set by now). A wildcard
// charger's first pickup goes straight to sleep, so never gets here.
Begin:
    if ( WildcardBase(PickupBase) != None && GetSpawnSound() != None )
        PlaySpawnSound();
    CheckTouching();
}

// Volume matches UDamageTimer's "UDamage ending" beeps: 1.5 * the pawn's
// TransientSoundVolume (0.3, from Actor).
defaultproperties
{
    SpawnSoundVolume=0.450000
    MaxStackTime=999.000000
}
