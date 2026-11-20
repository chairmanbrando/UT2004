# Damage Numbers

Damage numbers pop up RPG-style over targets you hit... provided they're within your line of sight. The number includes overkill damage, so if you headshot someone while holding the UDamage, you'll see the full amount even if it only took a fraction of that to kill them. Very satisfying!

Hits on the same target within 0.3s of each other add up and share a single number so things don't get cluttered with multi-hits or very fast hits. Similarly, they fade out and upward after half a second of being settled from adding up. The numbers' size can be set in `User.ini`, from `0.5` to `2.0`:

```ini
[DamageNumbers.DamageNumbersOverlay]
NumberSize=1.1
```

Because everyone loves a good hitsound (probably), this mutator includes a pleasing "tonk" on hit -- again limited to line-of-sight targets. Options are available to scale this as you see fit via `User.ini`:

```ini
[DamageNumbers.DamageNumbersOverlay]
HitSoundVolume=1.0
bHitSoundPitchByDamage=True
HitSoundPitchDamage=180
HitSoundPitchHigh=1.5
HitSoundPitchLow=0.5
```

The range of `HitSoundVolume` is `0.0` to `2.0` in case you want it gone or extra loud. When `bHitSoundPitchByDamage` is true, the pitch is scaled by the pitch options between 1 measly damage (assuming that can even happen) and `HitSoundPitchDamage`. Is it a little goofy to hear all this dinging and donging as you blast people/bots? Yes. Is it enjoyable nonetheless? Yes. Yes, it is.

And if you land on someone's head, you hear a *boing* instead. Because why not.
