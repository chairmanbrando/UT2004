# UDamage Reward v2

Fixes a long-standing bug where a dropped UDamage caught in midair wouldn't actually provide the power to the catcher despite the visible catch and the "someone got a UDamage" sound playing.

It also fixes what I personally consider a bug but is really only preference: The holder's entire character model glows purple while under UDamage's effect instead of only their gun. You no longer need a keen eye to pick out who to go after! Temporary whole-character effects, like being hit while armored, take precedence over this new glow so as to not upset damage messaging.

Note: This is meant to be used *in place* of the original mutator rather than alongside it. The original doesn't provide a `GroupName` in its `defaultproperties` so I cannot make these two mutually exclusive. It's on you, brother!

## But wait, there's more!

#### Extend Your Carnage!

To make things a little more interesting, this version is configurable to allow for kills to extend the length of your damage boost! Aggression rewards you with more time for aggression!

If you so desire, you could set it such that whoever's gotten it is essentially always dealing double damage until they die. But a more "competitive" setting is probably more in the realm of 1-2 seconds of extra time per kill.

#### Arena-wide Respawn Sounds!

The sound played when the UDamage spawns, and the range at which it's heard, can be changed. Why force pickup timing onto players when you can simply announce the UDamage's return to the whole arena?

Here are some decent enough sounds you can use:

- `AssaultSounds.AssaultRifle.IonPowerUp`
- `AmbModern.OneShot.cscanS2`
- `AmbModern.OneShot.hiss2`
- `AmbModern.OneShot.light5a`
- `AmbModern.OneShot.scream12`
- `AmbModern.OneShot.teleprt5`

If none satisfy, leave it stock or find your own in UnrealEd's sound package browser.

#### Offense Through Defense!

There's also an option to turn the UDamage into a defensive power-up if that's more your speed. When enabled the pickup becomes teal, applying a teal glow to the holder's character model, and provides substantial (two-thirds) damage reduction, halves outside sources of knockback, and eliminates self and falling damage entirely.

This adds a new take on the idea of aggression: What risk would you take if you knew you had a much lower chance of getting killed while going for it? Plus, you can shield- and rocket-jump all you want.

#### Bring the motherfucking ruckus!

Feeling silly? Turn on _Ruckus Mode_ and every armor charger, big health keg, and wildcard base spawns a UDamage instead, with all the options above still in play. Every UDamage respawns every 30 seconds (configurable), and UDamage time stacks with no 30-second cap. No armor, all damage! (Or the reverse in defensive mode.) Even so-called "strategic" maps with no UDamage normally are bigly affected by this nonsense.
