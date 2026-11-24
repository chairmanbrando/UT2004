//==============================================================================
//  The tinted beam's impact core (IBTintedBeam): stock's ShockExplosionCore,
//  but white (Textures\WhiteCore.tga, from MakeTintTextures.ps1), so tinting
//  it takes any colour.
//==============================================================================

class IBImpactCore extends ShockExplosionCore;

#exec TEXTURE IMPORT NAME=WhiteCoreTex FILE=Textures\WhiteCore.tga MIPS=On

defaultproperties
{
    Skins(0)=Texture'InstagibBeams.WhiteCoreTex'
}
