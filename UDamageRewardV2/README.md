# UDamage Reward v2

Fixes a long-standing bug where a dropped UDamage caught in midair wouldn't actually provide the power to the catcher despite the visible catch and the "someone got a UDamage" sound playing.

It also fixes what I personally consider a bug but is really only preference: Instead of only their gun, the holder's entire character model glows purple while under UDamage's effect. You no longer need a keen eye to pick out whomst to go after! Temporary whole-character effects, like being hit while armored, take precedence over this new glow so as to not upset damage messaging.

Note: This is meant to be used *in place* of the original mutator rather than alongside it. The original doesn't provide a `GroupName` in its `defaultproperties` so I cannot make these two mutually exclusive. It's on you, brother!

## But wait, there's more!

#### Extend your carnage!

To make things a little more interesting, this version is configurable to allow for kills to extend the length of your damage boost! Aggression rewards you with more time for aggression!

If you so desire, you could set it such that whoever's gotten it is essentially always dealing double damage until they die. But a more "competitive" setting is probably more in the realm of 1-2 seconds of extra time per kill. This rewards carnage without making it likely the holder will be powered up for a minute or more.

#### Arena-wide respawn sounds!

The sound played when the UDamage spawns, its volume, and the range at which it's heard, can be changed. Why force UDamage timing onto players when you can simply announce its return to the whole arena?

Here are some respawn sound options you can use:

- `PickupSounds.UDamagePickup` (stock)
- `UDamageRewardV2.UDamagePickup` (unclipped remake; see below)
- `UDamageRewardV2.UDamagePickupRev` (unclipped remake backwards)
- `AmbModern.OneShot.hiss2`
- `AmbModern.OneShot.light5a`
- `AmbModern.OneShot.scream12`
- `AmbModern.OneShot.teleprt5`
- `AssaultSounds.AssaultRifle.IonPowerUp`

If none satisfy, leave it stock or find your favorite in UnrealEd's sound package browser.

#### A new UDamage sound!

The stock UDamage pickup sound is loud and boosted to the point of heavy clipping, so this mutator comes with a from-scratch remake that's roughly as loud without the harshness. With the _Unclipped UDamage Sound_ option enabled, this new sound plays (at a configurable volume) when the UDamage is picked up and when it's running out.

There's a further third option for controlling the volume of the warning sound as the UDamage holder hears it. The stock sound plays extra loudly and right at your ears, so that deafening **WARG WARG WARG WARG** is no more.

#### Offense through defense!

There's also an option to turn the UDamage into a defensive power-up if that's more your speed. When enabled the pickup becomes teal, applying a teal glow to the holder's character model, and provides substantial (two-thirds) damage reduction, halves outside sources of knockback, and eliminates self and falling damage entirely.

This adds a new take on the idea of aggression: What risk would you take if you knew you had a much lower chance of getting killed while going for it? Plus, you can shield- and rocket-jump all you want.

#### Bring the motherfucking ruckus!

Feeling silly? Turn on _Ruckus Mode_ and every armor charger, big health keg, and wildcard base spawns a UDamage instead, with all the options above still in play. Every UDamage respawns every 30 seconds (configurable), and UDamage time stacks with no 30-second cap.

No armor, all damage! Or the reverse in defensive mode. Even so-called "strategic" maps with no UDamage normally are bigly affected by this nonsense.

#### Accidents happen!

If a dropped UDamage pickup is destroyed prematurely (e.g. the holder falls off the map or burns in lava and throws the pickup into it), the remaining time on the pickup is subtracted from its base's respawn time. Wouldn't want people jumping off the map just to avoid having the UDamage in play, would we?

Importantly, this little "fix" does *not* apply in Ruckus Mode or in maps that have more than one UDamage pickup base. It also doesn't affect wildcard bases as the next powerup to spawn is unknown.
