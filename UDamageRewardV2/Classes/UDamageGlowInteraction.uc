//==============================================================================
//  Moves the UDamage glow onto its holder's character on this client: purple
//  (the stock glow) for stock UDamage, teal (DefensiveUDamageMaterials) for
//  defensive UDamage, which also turns your own 1st-person weapon's glow teal.
//  Stock UDamage marks the holder's weapon and attachment with its glow
//  (OverlayMaterial, replicated by the server); just before each frame is
//  drawn, an attachment showing it hands the glow to its holder (Instigator).
//  Right after, everything is put back. Nothing the server sends is changed, so
//  on a listen server other players still receive the stock state (a material
//  made in code would reach them as None).
//  A holder already showing another overlay (a hit flash, spawn protection)
//  keeps it instead. Added by UDamageGlowFX; removed on level change.
//  For defensive UDamage the HUD's UDamage timer icon is made teal too
//  (TealHudIcon).
//==============================================================================

class UDamageGlowInteraction extends Interaction;

struct SwapRecord
{
    var Actor A;
    var Material Old;	// put back if A still shows Shown
    var Material Shown;
    var float OldCounter;
};

var Material StockGlow;
var Material HolderGlow;	// drawn on the holder's character
var Material WeaponGlow;	// drawn on 1st-person weapons; None keeps the stock glow
var array<SwapRecord> Swapped;
var bool bDefensive;

function Init(bool bInDefensive)
{
    bDefensive = bInDefensive;
    StockGlow = Material(DynamicLoadObject("XGameShaders.PlayerShaders.WeaponUDamageShader", class'Material', true));
    if ( bDefensive )
    {
        HolderGlow = class'DefensiveUDamageMaterials'.static.MakeGlow();
        WeaponGlow = HolderGlow;
    }
    else
        HolderGlow = StockGlow;
}

function Swap(Actor A, Material Shown)
{
    local int i;

    i = Swapped.Length;
    Swapped.Length = i + 1;
    Swapped[i].A = A;
    Swapped[i].Old = A.OverlayMaterial;
    Swapped[i].Shown = Shown;
    Swapped[i].OldCounter = A.ClientOverlayCounter;
    A.OverlayMaterial = Shown;
    // in case drawing an overlay needs time left on it
    if ( Shown != None )
        A.ClientOverlayCounter = FMax(A.ClientOverlayCounter, 1.0);
}

function PreRender(Canvas Canvas)
{
    local PlayerController PC;
    local Actor A;
    local Pawn Holder;

    Swapped.Length = 0;
    if ( ViewportOwner == None )
        return;
    PC = ViewportOwner.Actor;
    if ( PC == None )
        return;
    if ( bDefensive )
        TealHudIcon(HudCDeathmatch(PC.myHUD));
    if ( StockGlow == None || HolderGlow == None )
        return;

    foreach PC.DynamicActors(class'Actor', A)
    {
        if ( A.OverlayMaterial != StockGlow )
            continue;
        if ( Weapon(A) != None )
        {
            if ( WeaponGlow != None )
                Swap(A, WeaponGlow);
        }
        else if ( WeaponAttachment(A) != None )
        {
            Swap(A, None);
            Holder = A.Instigator;
            if ( Holder != None && Holder.OverlayMaterial == None )
                Swap(Holder, HolderGlow);
        }
    }
}

// the HUD's UDamage timer icon (HudCDeathmatch.DrawUDamage), our teal copy;
// set every frame since a new HUD (team or game change) starts out stock
function TealHudIcon(HudCDeathmatch H)
{
    if ( H == None || H.UDamageIcon.WidgetTexture == Texture'TealUDamageIcon' )
        return;
    H.UDamageIcon.WidgetTexture = Texture'TealUDamageIcon';
    H.UDamageIcon.TextureCoords.X1 = 0;
    H.UDamageIcon.TextureCoords.Y1 = 0;
    H.UDamageIcon.TextureCoords.X2 = 73;
    H.UDamageIcon.TextureCoords.Y2 = 82;
}

function PostRender(Canvas Canvas)
{
    local int i;

    for ( i = Swapped.Length - 1; i >= 0; i-- )
        if ( Swapped[i].A != None && Swapped[i].A.OverlayMaterial == Swapped[i].Shown )
        {
            Swapped[i].A.OverlayMaterial = Swapped[i].Old;
            Swapped[i].A.ClientOverlayCounter = Swapped[i].OldCounter;
        }
    Swapped.Length = 0;
}

event NotifyLevelChange()
{
    Swapped.Length = 0;
    Master.RemoveInteraction(self);
}

defaultproperties
{
    bVisible=True
}
