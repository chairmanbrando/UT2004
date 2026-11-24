//==============================================================================
//  Instagib Beams: the instagib rifles' beams, adjusted. Swaps in its own
//  rifles (IBSuperShockRifle, IBZoomSuperShockRifle), whose beams:
//  - pierce players like a railgun (with bPierce): one straight line, killing
//    everyone in it, drawn as one beam (IBUtil). Stock plain instagib stops at
//    the first player; stock zoom instagib pierces, but draws a beam per victim.
//  - are drawn white and tinted (IBTintedBeam): blue and red by team, made
//    about as easy to see as each other (IBUtil's team colours), or one colour
//    for everyone (BeamColor).
//  Instagib hands its rifle out as the default weapon, which doesn't go
//  through GetInventoryClassOverride, so that's patched in each mutator handing
//  out a stock one (GetDefaultWeapon). Anything handing them out by class name
//  (Gun Game's tiers) gets ours through GetInventoryClassOverride.
//  The settings are read on the server; beams replicate as the class picked,
//  the tinted one with its colour.
//==============================================================================

class InstagibBeamsMutator extends Mutator
    config;

var config bool bPierce;        // beams go through players, killing everyone in line
var config string BeamColor;    // "R,G,B": one beam colour for everyone; blank, by team

var localized string PierceDisplayText, PierceDescText, ColorDisplayText, ColorDescText;

// ours in place of a stock instagib rifle, or None
static function class<Weapon> NewWeaponClass(class<Weapon> Old)
{
    if ( Old == class'SuperShockRifle' )
        return class'IBSuperShockRifle';
    if ( Old == class'ZoomSuperShockRifle' )
        return class'IBZoomSuperShockRifle';
    return None;
}

// The default weapon doesn't go through GetInventoryClassOverride: each
// mutator in the chain asks the ones after it first, then falls back to its
// own DefaultWeaponName. So, before that, point any mutator handing out a
// stock instagib rifle (MutInstaGib, MutZoomInstagib, InstagibMutator) at
// ours, wherever it is in the chain.
function class<Weapon> GetDefaultWeapon()
{
    local Mutator M;
    local class<Weapon> W;

    for ( M = Level.Game.BaseMutator; M != None; M = M.NextMutator )
    {
        if ( M.DefaultWeaponName ~= "XWeapons.SuperShockRifle" || M.DefaultWeapon == class'SuperShockRifle' )
            W = class'IBSuperShockRifle';
        else if ( M.DefaultWeaponName ~= "XWeapons.ZoomSuperShockRifle" || M.DefaultWeapon == class'ZoomSuperShockRifle' )
            W = class'IBZoomSuperShockRifle';
        else
            continue;
        M.DefaultWeaponName = string(W);
        M.DefaultWeapon = None;
    }

    return Super.GetDefaultWeapon();
}

function string GetInventoryClassOverride(string InventoryClassName)
{
    local class<Weapon> W;

    W = NewWeaponClass(class<Weapon>(DynamicLoadObject(InventoryClassName, class'Class', true)));
    if ( W != None )
        InventoryClassName = string(W);
    return Super.GetInventoryClassOverride(InventoryClassName);
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);
    PlayInfo.AddSetting(default.RulesGroup, "bPierce", default.PierceDisplayText, 0, 1, "Check");
    PlayInfo.AddSetting(default.RulesGroup, "BeamColor", default.ColorDisplayText, 0, 1, "Text", "11");
}

static event string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "bPierce":     return default.PierceDescText;
        case "BeamColor":   return default.ColorDescText;
    }
    return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    bPierce=True
    PierceDisplayText="Piercing Beams"
    PierceDescText="Beams go through players like a railgun, killing everyone in line, drawn as one beam. Off: they stop at the first player, as plain instagib's do."
    ColorDisplayText="Beam Colour"
    ColorDescText="One colour for everyone's beams, as R,G,B (0-255 each); e.g. 255,40,255 is neon violet. Blank: red and blue by team, both made about as easy to see."
    GroupName="InstagibBeams"
    FriendlyName="Instagib Beams"
    Description="Instagib rifle beams that pierce players like a railgun, and are easier to see: a blue and a red made about as visible as each other, or one colour of your choosing for everyone. Details: https://github.com/chairmanbrando/UT2004/blob/main/InstagibBeams/README.md"
    bAddToServerPackages=True
}
