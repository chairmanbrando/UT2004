//==============================================================================
//  The instagib beam, in a colour picked on the server (IBUtil.SpawnBeam): the
//  team's, or the BeamColor setting's. The colour (BeamColor) is set on
//  the server before the beam replicates, and arrives with it; each machine
//  then tints a white beam texture (Textures\WhiteBeam.tga, from
//  MakeTintTextures.ps1) with it, through a ColorModifier made at runtime and
//  kept for reuse while the colour stays the same (TintFor). White, so any
//  colour comes out as set, white included; stock's purple ShockBeamTex could
//  only be tinted to shades of purple. The impact flash, ring and core
//  (IBImpactFlare, IBImpactRing, IBImpactCore) and the scorch mark (IBScorch)
//  are white too, tinted to match; the coil and muzzle flash are stock's,
//  tinted as close as their purple allows. Spawned by IBUtil.SpawnBeam, with
//  its extra beam (IBExtraTintedBeam).
//  A dark colour (no channel up to DarkLimit) would barely show drawn
//  additively, as these are, and black not at all: those are alpha-blended
//  instead (DarkTint), over what's behind, from the white textures' alpha.
//  The coil and muzzle flash, with no alpha of their own, are left out then.
//==============================================================================

class IBTintedBeam extends ShockBeamEffect;

#exec TEXTURE IMPORT NAME=WhiteBeamTex FILE=Textures\WhiteBeam.tga MIPS=On

var color BeamColor;

// a colour's dark, drawn alpha-blended, with no channel up to this
var float DarkLimit;

// the last tints made, and their colours
var ColorModifier Tint, ScorchTint;
var color TintColor, ScorchTintColor;
var bool bScorchTintDark;

// the alpha-blended tints made (DarkTint)
struct DarkTintEntry
{
    var Material Tex;
    var color C;
    var FinalBlend Blend;
};
var array<DarkTintEntry> DarkTints;

replication
{
    reliable if ( bNetInitial && Role == ROLE_Authority )
        BeamColor;
}

// the white beam tinted C, made once per colour
static function ColorModifier TintFor(color C)
{
    if ( default.Tint == None || default.TintColor != C )
    {
        default.Tint = new(None) class'ColorModifier';
        default.Tint.Material = Texture'InstagibBeams.WhiteBeamTex';
        default.Tint.Color = C;
        default.TintColor = C;
    }
    return default.Tint;
}

// the white scorch mark tinted C, made once per colour: with AlphaBlend for a
// dark one (alpha-blended onto the surface), otherwise without, which a decal
// added to the surface has no use for
static function ColorModifier ScorchTintFor(color C, bool bDark)
{
    if ( default.ScorchTint == None || default.ScorchTintColor != C || default.bScorchTintDark != bDark )
    {
        default.ScorchTint = new(None) class'ColorModifier';
        default.ScorchTint.Material = Texture'InstagibBeams.WhiteScorchTex';
        default.ScorchTint.Color = C;
        default.ScorchTint.AlphaBlend = bDark;
        default.ScorchTintColor = C;
        default.bScorchTintDark = bDark;
    }
    return default.ScorchTint;
}

// Tex tinted C and alpha-blended over what's behind it, by Tex's alpha: for a
// dark colour, which drawn additively would barely show. Made once per
// texture and colour.
static function Material DarkTint(Material Tex, color C)
{
    local int i;
    local ColorModifier M;
    local FinalBlend B;
    local DarkTintEntry Entry;

    for ( i = 0; i < default.DarkTints.Length; i++ )
        if ( default.DarkTints[i].Tex == Tex && default.DarkTints[i].C == C && default.DarkTints[i].Blend != None )
            return default.DarkTints[i].Blend;

    M = new(None) class'ColorModifier';
    M.Material = Tex;
    M.Color = C;
    B = new(None) class'FinalBlend';
    B.Material = M;
    B.FrameBufferBlending = FB_AlphaBlend;
    B.ZWrite = false;

    Entry.Tex = Tex;
    Entry.C = C;
    Entry.Blend = B;
    default.DarkTints[default.DarkTints.Length] = Entry;
    return B;
}

simulated function bool IsDark()
{
    return Max(BeamColor.R, Max(BeamColor.G, BeamColor.B)) < DarkLimit;
}

// BeamColor, fully opaque
simulated function color OpaqueColor()
{
    local color C;

    C = BeamColor;
    C.A = 255;
    return C;
}

// the beam's material, tinted; alpha-blended if dark
simulated function ApplyBeamSkin()
{
    if ( IsDark() )
    {
        Skins[0] = DarkTint(Texture'InstagibBeams.WhiteBeamTex', OpaqueColor());
        Style = STY_Alpha;
    }
    else
        Skins[0] = TintFor(BeamColor);
}

// BeamColor, scaled so its strongest channel is Peak
simulated function color ScaledColor(float Peak)
{
    local color C;
    local float Scale;

    Scale = Peak / Max(1, Max(BeamColor.R, Max(BeamColor.G, BeamColor.B)));
    C.R = Min(255, BeamColor.R * Scale);
    C.G = Min(255, BeamColor.G * Scale);
    C.B = Min(255, BeamColor.B * Scale);
    C.A = 255;
    return C;
}

// an emitter whose particles are in BeamColor, scaled so its strongest channel
// is Peak. An emitter colours its particles as it makes them, the first burst
// while it spawns, so the colour goes on the class (stock's red effects have
// theirs in defaultproperties) for the spawn, then back; and on the emitter,
// for any particles it makes later. A dark colour goes in the material
// instead (DarkTint), the particles left white, and is alpha-blended.
simulated function xEmitter SpawnTinted(class<xEmitter> EmitterClass, vector Loc, rotator Rot, float Peak)
{
    local color Tinted, Old0, Old1;
    local xEmitter E;

    if ( EmitterClass == None )
        return None;

    if ( IsDark() )
        Tinted = class'Canvas'.static.MakeColor(255, 255, 255, 255);
    else
        Tinted = ScaledColor(Peak);
    Old0 = EmitterClass.default.mColorRange[0];
    Old1 = EmitterClass.default.mColorRange[1];
    EmitterClass.default.mColorRange[0] = Tinted;
    EmitterClass.default.mColorRange[1] = Tinted;

    E = Spawn(EmitterClass,,, Loc, Rot);

    EmitterClass.default.mColorRange[0] = Old0;
    EmitterClass.default.mColorRange[1] = Old1;

    if ( E != None )
    {
        E.mColorRange[0] = Tinted;
        E.mColorRange[1] = Tinted;
        if ( IsDark() )
        {
            E.Skins[0] = DarkTint(E.Skins[0], OpaqueColor());
            E.Style = STY_Alpha;
        }
    }
    return E;
}

// ShockBeamEffect's, white and tinted, as stock's red ones are
simulated function SpawnImpactEffects(rotator HitRot, vector EffectLoc)
{
    SpawnTinted(class'IBImpactFlare', EffectLoc, HitRot, 235);
    SpawnTinted(class'IBImpactRing', EffectLoc, HitRot, 235);
    SpawnTinted(class'IBImpactCore', EffectLoc + HitNormal * 8, HitRot, 235);

    if ( IsDark() )
        class'IBScorch'.default.PendingTexture = ScorchTintFor(OpaqueColor(), true);
    else
        class'IBScorch'.default.PendingTexture = ScorchTintFor(ScaledColor(255), false);
    class'IBScorch'.default.bPendingAlphaBlend = IsDark();
    Spawn(class'IBScorch',,, EffectLoc, rotator(-HitNormal));
    class'IBScorch'.default.PendingTexture = None;
    class'IBScorch'.default.bPendingAlphaBlend = false;
}

// ShockBeamEffect's, tinted, plus a second layer, as the instagib beams have
simulated function SpawnEffects()
{
    local ShockBeamCoil Coil;
    local xWeaponAttachment Attachment;
    local IBTintedBeam E;

    ApplyBeamSkin();

    if ( Instigator != None )
    {
        if ( Instigator.IsFirstPerson() )
        {
            if ( (Instigator.Weapon != None) && (Instigator.Weapon.Instigator == Instigator) )
                SetLocation(Instigator.Weapon.GetEffectStart());
            else
                SetLocation(Instigator.Location);
            if ( !IsDark() )
                SpawnTinted(MuzFlashClass, Location, Rotation, 235);
        }
        else
        {
            Attachment = xPawn(Instigator).WeaponAttachment;
            if ( Attachment != None && (Level.TimeSeconds - Attachment.LastRenderTime) < 1 )
                SetLocation(Attachment.GetTipLocation());
            else
                SetLocation(Instigator.Location + Instigator.EyeHeight * vect(0,0,1) + Normal(mSpawnVecA - Instigator.Location) * 25.0);
            if ( !IsDark() )
                SpawnTinted(MuzFlash3Class, Location, Rotation, 235);
        }
    }

    if ( EffectIsRelevant(mSpawnVecA + HitNormal * 2, false) && (HitNormal != vect(0,0,0)) )
        SpawnImpactEffects(rotator(HitNormal), mSpawnVecA + HitNormal * 2);

    if ( !IsDark() && ((!Level.bDropDetail && (Level.DetailMode != DM_Low) && (VSize(Location - mSpawnVecA) > 40) && !Level.GetLocalPlayerController().BeyondViewDistance(Location, 0))
        || ((Instigator != None) && Instigator.IsFirstPerson())) )
    {
        Coil = ShockBeamCoil(SpawnTinted(CoilClass, Location, Rotation, 150));
        if ( Coil != None )
            Coil.mSpawnVecA = mSpawnVecA;
    }

    E = Spawn(class'IBExtraTintedBeam');
    if ( E != None )
    {
        E.BeamColor = BeamColor;
        E.AimAt(mSpawnVecA, HitNormal);
    }
}

defaultproperties
{
    Skins(0)=Texture'InstagibBeams.WhiteBeamTex'
    DarkLimit=100
    bNetTemporary=False
}
