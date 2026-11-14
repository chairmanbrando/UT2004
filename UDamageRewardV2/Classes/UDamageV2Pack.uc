//==============================================================================
//  UDamage pickup for chargers. Replaces the stock respawn sound (played
//  client-side by PlayerSpawnEffect with the default 0.3 volume and 300 radius)
//  with a louder, longer-range one played from the server. Picking it up while
//  your UDamage warning is playing restarts the next warning from the top
//  (UDamageUtil).
//==============================================================================

class UDamageV2Pack extends UDamagePack
    notplaceable;

var string SpawnSoundName;	// set by UDamageRewardV2Mutator
var float SpawnSoundRadius;	// 0 keeps the stock respawn effect and sound
var float SpawnSoundVolume;
var Sound SpawnSound;

function RespawnEffect()
{
    local Actor Source;

    if ( SpawnSound == None && SpawnSoundName != "" && SpawnSoundRadius > 0 )
    {
        SpawnSound = Sound(DynamicLoadObject(SpawnSoundName, class'Sound', true));
        if ( SpawnSound == None )
        {
            log(self$" couldn't load SpawnSound '"$SpawnSoundName$"', using the stock respawn sound");
            SpawnSoundName = "";
        }
    }

    if ( SpawnSound == None )
    {
        Super.RespawnEffect();
        return;
    }

    spawn(class'UDamageRespawnEffect');

    // the charger base is visible and present on clients; the pickup is still hidden here
    Source = PickupBase;
    if ( Source == None )
        Source = self;
    Source.PlaySound(SpawnSound, SLOT_None, SpawnSoundVolume, false, SpawnSoundRadius);
}

// same as UDamagePack's, plus the warning reset
auto state Pickup
{
    function Touch( actor Other )
    {
        local Pawn P;

        if ( ValidTouch(Other) )
        {
            P = Pawn(Other);
            P.EnableUDamage(30);
            class'UDamageUtil'.static.ResetWarningIfExtended(P);
            AnnouncePickup(P);
            SetRespawn();
        }
    }
}

// Volume matches UDamageTimer's "UDamage ending" beeps: 1.5 * the pawn's
// TransientSoundVolume (0.3, from Actor).
defaultproperties
{
    SpawnSoundVolume=0.450000
}
