# UDamage Reward v2

Fixes a long-standing bug where a dropped UDamage caught in midair wouldn't actually provide the power to the catcher despite the visible catch and the "someone got a UDamage" sound playing.

Note: This is meant to be used *in place* of the original mutator rather than alongside it. The original doesn't provide a `GroupName` in its `defaultproperties` so I cannot make these two mutually exclusive. It's on you, brother!

To enhance the carnage, this version is configurable to allow for kills to extend the length of your damage boost. If you so desire you can set it so that you're basically always dealing double damage, but a more "competitive" setting is more like 1-2 seconds of extra time per kill.

Furthermore, the sound played when the UDamage spawns, and the range at which it's heard, can be changed. Why force pickup timing onto players when you can simply announce the UDamage's return to the whole arena? 🙃

There's also an option to turn the UDamage into a defensive power-up if that's more your speed. When enabled the pickup becomes teal and the holder takes a third of their normal damage, receives half the usual knockback from other sources, and takes no self or falling damage.

Finally, instead of only making the holder's gun glow purple (or teal) as the standard pickup does, now their entire character glows. You no longer need a keen eye to pick out who to go after! Temporary whole-player effects, like being hit while armored, take precedence over this new glow so as to not upset damage messaging.
