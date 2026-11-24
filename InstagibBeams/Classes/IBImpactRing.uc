//==============================================================================
//  The tinted beam's impact ring (IBTintedBeam): stock's ShockImpactRing, but
//  white (Textures\WhiteRing.tga, from MakeTintTextures.ps1), so tinting it
//  takes any colour.
//==============================================================================

class IBImpactRing extends ShockImpactRing;

#exec TEXTURE IMPORT NAME=WhiteRingTex FILE=Textures\WhiteRing.tga MIPS=On

defaultproperties
{
    Skins(0)=Texture'InstagibBeams.WhiteRingTex'
}
