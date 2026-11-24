//==============================================================================
//  The tinted beam's scorch mark (IBTintedBeam): stock's ShockImpactScorch,
//  but white (Textures\WhiteScorch.tga, from MakeTintTextures.ps1), in the
//  tint set in PendingTexture as it spawns. A projector attaches to the
//  surface while it's spawning (Projector.PostBeginPlay) and can't take a
//  colour of its own, so the tinted material has to be in place before:
//  IBTintedBeam sets PendingTexture's default just before spawning one, and
//  this takes it in PreBeginPlay; and bPendingAlphaBlend likewise, for a dark
//  colour, alpha-blended onto the surface rather than added to it.
//==============================================================================

class IBScorch extends ShockImpactScorch;

#exec TEXTURE IMPORT NAME=WhiteScorchTex FILE=Textures\WhiteScorch.tga MIPS=On UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

var Material PendingTexture;
var bool bPendingAlphaBlend;

event PreBeginPlay()
{
    if ( default.PendingTexture != None )
        ProjTexture = default.PendingTexture;
    if ( default.bPendingAlphaBlend )
        FrameBufferBlendingOp = PB_AlphaBlend;
    Super.PreBeginPlay();
}

defaultproperties
{
    ProjTexture=Texture'InstagibBeams.WhiteScorchTex'
}
