//==============================================================================
//  The tinted beam's impact flash (IBTintedBeam): stock's ShockImpactFlare,
//  but white (Textures\WhiteFlare.tga, from MakeTintTextures.ps1), so tinting
//  it takes any colour.
//==============================================================================

class IBImpactFlare extends ShockImpactFlare;

#exec TEXTURE IMPORT NAME=WhiteFlareTex FILE=Textures\WhiteFlare.tga MIPS=On

defaultproperties
{
    Skins(0)=Texture'InstagibBeams.WhiteFlareTex'
}
