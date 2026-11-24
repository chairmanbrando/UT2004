# Instagib Beams

Fixes an issue with the default zooming Super Shock Rifle where it could hit multiple targets in a row (nice!) but would draw a new beam for each one (not nice!). Since all the targets would be straight ahead this would stack the beams up. Now it works more like a proper railgun and draws a single beam through the hit targets.

## But wait, there's more!

#### Rail me, baby!

This fix also enables piercing railgun shots with the non-zooming version of the gun. For whatever reason Epic's developers only gave the zooming Super Shock Rifle the multi-hit ability. Now they both have it!

#### Color fixes!

If you're using the [OldUnreal patch](https://github.com/OldUnreal/UT2004Patches?tab=readme-ov-file) and therefore DX11, the game's more prone to washing out bright colors than stock. It's got something to do with how gamma is calculated in this renderer vs. the old ones according to an AI that's far smarter than me. Regardless of the cause, it makes the blue beam notably harder to see than the red one -- sometimes nearly invisible from your perspective as you fire into a well-lit area.

This mutator attempts to fix this visibility disparity by drawing both teams' beams the same way: white underneath, tinted blue or red, with the red beam a touch dimmer so neither outshines the other.

- Red: `220,60,60`
- Blue: `70,70,255`

#### Any beam color you want!

With the above in place, I couldn't stop there. Thus, if you'd instead prefer everyone to fire the same beam color, you can set it up as such. The beam and its impact flash, ring, and scorch mark are all white underneath and tinted to the color you set. Oranges and greens and purples are all on the table, oh my!

While not recommended for gameplay reasons, dark colors work too by leveraging the alpha channel instead of tinting over white if the color you've chosen is sufficiently dark. If you want everyone to shoot black beams, you can do it.
