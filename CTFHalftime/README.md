# CTF Halftime

Enable the creation and usage of asymmetrical CTF maps with a mutator that forces a team swap at halftime. CS has had one-sided maps since forever, for instance, and it's fine if both teams get a shot at it. Why not UT2004?

Yeah, I know some maps like November/December and Gauntlet have some asymmetry, but I'm talking about creating fully asymmetrical maps where it's purposefully easy to defend vs. attack or vice versa depending on how the map is set up. It's UT2004's version of Terrorists vs. Counter-Terrorists.

You can of course use it on standard symmetrical maps. The swap is "pointless" then, but it's no more pointless than side swaps in Real Life™ sports. It's a little respite from the otherwise constant action, and a losing team can try to reset their mentals and get things back under control.

Note: This mutator requires that the game have a time limit. Can't have a half*time* if there's no time, eh?

## How does this halftime business work?

A bit before halftime happens each player gets a warning on screen about it. When the current match's time hits its halfway point, everything freezes for a short wait: the literal halftime. It's configurable to last from 5-60 seconds.

Then teams switch sides and colors, keeping the scores and everyone's stats intact. The level and all its contents are reset to their default state, and play resumes. By default everyone's loadout is also reset back to their spawn state. This is intentional and makes asymmetrical maps possible.

However, there's a setting you can use for symmetrical maps that will keep current loadouts intact -- like in Bombing Run when a new round starts. Do not enable it for asymmetrical maps; that's counter to the entire point!

## Switching teams/colors is gross.

Yes, it's a bit confusing to go from shooting one color of enemy to another halfway through a match. But it was the simplest way to get this thing up and running, especially because I wanted bots to understand it. Bots are totally fine switching teams thanks to the "bots balance teams" game option, so this was the play.

I'm considering ways to handle the halftime swap physically rather than by teams. If it could be managed, the blue team would start spawning at the red base and attacking a red flag planted in their old base and vice versa. Is that more or less confusing than switching teams? Whomst knows. We'll just have to see if/when it comes to it.
