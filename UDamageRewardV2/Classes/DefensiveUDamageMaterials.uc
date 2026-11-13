//==============================================================================
//  Teal versions of the UDamage materials for defensive UDamage, built at
//  runtime on each client (materials made in code can't replicate).
//  - Glow: overlays can't be tinted (see MakeGlow), so the stock glow's purple
//    texture (XGameShaders.PlayerShaders.WeaponUDamage) has been hue-shifted to
//    teal and imported here (Textures\TealGlow.tga).
//  - Pickup: the stock skin (PickupSkins.Shaders.FinalDamShader) multiplies a
//    grey texture by a purple ConstantColor; this uses teal. Its purple
//    reflection map is replaced by a neutral one, tinted teal.
//==============================================================================

class DefensiveUDamageMaterials extends Object;

#exec TEXTURE IMPORT NAME=TealGlow FILE=Textures\TealGlow.tga MIPS=On DXT=5

var Color TealColor;

static function ConstantColor MakeTeal(byte Alpha)
{
    local ConstantColor C;

    C = new class'ConstantColor';
    C.Color = default.TealColor;
    C.Color.A = Alpha;
    return C;
}

// An overlay glow, for weapons and players. Every stock overlay is a Shader
// with only a panning plain texture as Specular, masked by OverlayConstant;
// anything else there misdraws (a Combiner draws nothing, a ColorModifier's
// tint is ignored, a FinalBlend replaces the skin). So this is the stock glow
// (XGameShaders.PlayerShaders.WeaponUDamageShader) with the teal texture.
static function Material MakeGlow()
{
    local Shader Stock, S;
    local TexPanner StockPanner, Panner;

    Stock = Shader(DynamicLoadObject("XGameShaders.PlayerShaders.WeaponUDamageShader", class'Shader', true));
    if ( Stock == None )
        return None;
    StockPanner = TexPanner(Stock.Specular);

    Panner = new class'TexPanner';
    Panner.Material = Texture'TealGlow';
    if ( StockPanner != None )
    {
        Panner.PanDirection = StockPanner.PanDirection;
        Panner.PanRate = StockPanner.PanRate;
    }

    S = new class'Shader';
    S.Specular = Panner;
    S.SpecularityMask = Stock.SpecularityMask;
    return S;
}

static function Material MakePickupSkin()
{
    local Shader Stock, S;
    local Combiner StockDiffuse, Diffuse, Shine;
    local FinalBlend F;
    local Material Env;

    Stock = Shader(DynamicLoadObject("PickupSkins.Shaders.UdamShader", class'Shader', true));
    if ( Stock == None )
        return None;
    StockDiffuse = Combiner(Stock.Diffuse);

    Diffuse = new class'Combiner';
    Diffuse.Material1 = MakeTeal(0);
    if ( StockDiffuse != None )
    {
        Diffuse.Material2 = StockDiffuse.Material2;
        Diffuse.CombineOperation = StockDiffuse.CombineOperation;
        Diffuse.AlphaOperation = StockDiffuse.AlphaOperation;
    }

    S = new class'Shader';
    S.Diffuse = Diffuse;
    S.Opacity = Stock.Opacity;

    // a neutral reflection, tinted teal, for the stock purple one
    Env = Material(DynamicLoadObject("CubeMaps.Anubis.Anubis-texenv2", class'Material', true));
    if ( Env != None )
    {
        Shine = new class'Combiner';
        Shine.Material1 = MakeTeal(255);
        Shine.Material2 = Env;
        Shine.CombineOperation = CO_Multiply;
        S.Specular = Shine;
    }

    F = new class'FinalBlend';
    F.Material = S;
    F.FrameBufferBlending = FB_AlphaBlend;
    F.ZWrite = true;
    F.ZTest = true;
    return F;
}

defaultproperties
{
    TealColor=(B=200,G=210,R=20,A=255)
}
