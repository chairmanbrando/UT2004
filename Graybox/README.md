# Graybox

A texture package of flat greys at 64x64 for blocking out maps in UnrealEd.

| Texture | Grey | RGB | Use |
|---|---|---|---|
| `Graybox.Walls` | 0.7 | 179 |  |
| `Graybox.Floors` | 0.5 | 128 |  |
| `Graybox.Ceilings` | 0.8 | 204 |  |
| `Graybox.Objects` | 0.6 | 153 | Decorations and obstacles |
| `Graybox.Doors` | 0.4 | 102 | Literal doors or zone portals |
| `Graybox.Windows` | 0.9 | 230 | Literal windows or light emitters |

## Install

Move `Textures/Graybox.utx` into your UT2004 `Textures` folder.

## Rebuilding

The `.tga` files in `Textures` are the sources. If you want to change or add one, run this from UT2004's `System` folder:

```
ucc pkg import texture Graybox "..\Graybox\Textures"
```

That writes `Graybox.utx` into `System`. Move it to UT2004's `Textures` folder and you're golden. Note: `ucc pkg` only reads `.tga` and `.pcx` files.
