//==============================================================================
//  Damage numbers: the damage you deal (to health and armor) pops up above the
//  head of whoever took it, then floats up and fades out. Hits on the same
//  target in quick succession (shotgun pellets, minigun, link beam) add up in
//  one number, which starts over with each. Drawn in screen space at the
//  target's projected position, following it while it's in view; hits out of
//  sight behind walls or other world geometry aren't shown (ShowHit). UDamage
//  purple while your UDamage doubles them; teal (UDamageV2's defensive
//  UDamage) when the target's cuts them. Fed by
//  DamageNumbersInfo; drawn by the HUD with its other overlays, so it hides
//  with the HUD. Also plays the hit sound (PlayHitSound), optionally pitched
//  by the hit's damage.
//==============================================================================

class DamageNumbersOverlay extends HudOverlay
    config(User);

#exec AUDIO IMPORT FILE=Sounds\Tonk.wav NAME=Tonk

struct DamageNumber
{
    var Pawn Victim;
    var vector Loc;		// above Victim's head, updated while it's alive and known
    var int Amount;
    var float StartTime;
    var byte Kind;		// 0 by size (NumberColor), 1 UDamage purple, 2 defensive UDamage teal
};
var array<DamageNumber> Numbers;

var float MergeTime;	// a hit within this long of the last on a target adds to its number; it holds still until then
var float RiseTime;		// then it floats up and fades out over this long
var float PopTime;		// seconds the number takes to shrink from PopScale to normal
var float PopScale;
var float RiseHeight;	// how far it floats up, as a share of the screen height
var color UDamageColor, DefensiveUDamageColor;
var config float NumberSize;	// each player's own, in their User.ini: 1 is the HUD's small font

// hit sound: each player's own, in their User.ini; 0 turns it off
var config float HitSoundVolume;
var Sound HitSound;
var float HitSoundBoost;		// HitSoundVolume 1 plays at this; plain 1 is lost under the game's sounds
var float HitSoundInterval;		// at most one per this long (one hit on two targets)
var float LastHitSoundTime;
var int PendingSoundAmount;		// the frame's hits so far (one explosion on several targets), sounded together in Tick

// optionally, the hit sound's pitch by the hit's damage: HitSoundPitchHigh for
// the smallest, down to HitSoundPitchLow at HitSoundPitchDamage and up
var config bool bHitSoundPitchByDamage;
var config float HitSoundPitchHigh, HitSoundPitchLow, HitSoundPitchDamage;

// A hit: its number and sound, only if it's in sight of the camera (InSight),
// so hits around corners don't give away targets you hadn't seen. Once shown,
// a number stays up wherever its target goes.
simulated function ShowHit(PlayerController PC, Pawn Victim, vector Loc, int Amount, byte Kind)
{
    local Actor ViewActor;
    local vector CamLoc;
    local rotator CamRot;

    PC.PlayerCalcView(ViewActor, CamLoc, CamRot);
    if ( !InSight(Victim, Loc, CamLoc) )
        return;
    AddDamage(Victim, Loc, Amount, Kind);
    PendingSoundAmount += Amount;
    Enable('Tick');
}

// the frame's hits are in: one sound for them all, pitched by their total
simulated function Tick(float DeltaTime)
{
    local PlayerController PC;

    if ( PendingSoundAmount > 0 )
    {
        PC = Level.GetLocalPlayerController();
        if ( PC != None )
            PlayHitSound(PC, PendingSoundAmount);
        PendingSoundAmount = 0;
    }
    Disable('Tick');
}

simulated function PlayHitSound(PlayerController PC, int Amount)
{
    local float Pitch;

    if ( HitSound == None || HitSoundVolume <= 0 || Level.TimeSeconds - LastHitSoundTime < HitSoundInterval )
        return;
    LastHitSoundTime = Level.TimeSeconds;
    Pitch = 1.0;
    if ( bHitSoundPitchByDamage )
        Pitch = FMax(0.1, HitSoundPitchHigh
            - (HitSoundPitchHigh - HitSoundPitchLow) * FClamp(Amount / FMax(1, HitSoundPitchDamage), 0, 1));
    // as PC.ClientPlaySound, without its cap of 2
    if ( PC.ViewTarget != None )
        PC.ViewTarget.PlaySound(HitSound, SLOT_None, HitSoundVolume * HitSoundBoost,,, Pitch, false);
}

// a merged number takes the latest hit's Kind
simulated function AddDamage(Pawn Victim, vector Loc, int Amount, byte Kind)
{
    local int i;

    if ( Victim != None )
        for ( i = 0; i < Numbers.Length; i++ )
            if ( Numbers[i].Victim == Victim && Level.TimeSeconds - Numbers[i].StartTime < MergeTime )
            {
                Numbers[i].Amount += Amount;
                Numbers[i].Loc = Loc;
                Numbers[i].StartTime = Level.TimeSeconds;
                Numbers[i].Kind = Kind;
                return;
            }

    i = Numbers.Length;
    Numbers.Length = i + 1;
    Numbers[i].Victim = Victim;
    Numbers[i].Loc = Loc;
    Numbers[i].Amount = Amount;
    Numbers[i].StartTime = Level.TimeSeconds;
    Numbers[i].Kind = Kind;
}

simulated function Render(Canvas C)
{
    local HUD H;
    local vector CamLoc, Screen;
    local rotator CamRot;
    local float Age, Rise, Alpha, Scale, XL, YL;
    local string S;
    local int i;

    H = HUD(Owner);
    if ( H == None )
        return;

    C.GetCameraLocation(CamLoc, CamRot);
    C.Font = H.GetFontSizeIndex(C, -1);
    C.Style = ERenderStyle.STY_Alpha;

    for ( i = Numbers.Length - 1; i >= 0; i-- )
    {
        Age = Level.TimeSeconds - Numbers[i].StartTime;
        if ( Age >= MergeTime + RiseTime || Age < 0 )
        {
            Numbers.Remove(i, 1);
            continue;
        }

        // follow the target while it's alive
        if ( Numbers[i].Victim != None && !Numbers[i].Victim.bDeleteMe && Numbers[i].Victim.Health > 0 )
            Numbers[i].Loc = Numbers[i].Victim.Location + (Numbers[i].Victim.CollisionHeight + 16) * vect(0,0,1);

        // behind the camera
        if ( (Numbers[i].Loc - CamLoc) Dot vector(CamRot) <= 0 )
            continue;

        Screen = C.WorldToScreen(Numbers[i].Loc);
        // still while more hits can add to it, then up and out
        Rise = FMax(0, Age - MergeTime) / RiseTime;
        Screen.Y -= RiseHeight * C.ClipY * Rise;
        Alpha = 1.0 - Square(Rise);
        Scale = 1.0;
        if ( Age < PopTime )
            Scale = PopScale - (PopScale - 1.0) * Age / PopTime;
        Scale *= FClamp(NumberSize, 0.5, 2.0);

        S = string(Numbers[i].Amount);
        C.FontScaleX = 1.0;
        C.FontScaleY = 1.0;
        C.TextSize(S, XL, YL);
        C.FontScaleX = Scale;
        C.FontScaleY = Scale;
        XL *= Scale;
        YL *= Scale;

        // a shadow, for light backgrounds
        C.DrawColor = class'Canvas'.static.MakeColor(0, 0, 0, 200 * Alpha);
        C.SetPos(Screen.X - XL / 2 + 2, Screen.Y - YL / 2 + 2);
        C.DrawText(S);
        if ( Numbers[i].Kind == 1 )
            C.DrawColor = UDamageColor;
        else if ( Numbers[i].Kind == 2 )
            C.DrawColor = DefensiveUDamageColor;
        else
            C.DrawColor = NumberColor(Numbers[i].Amount, Alpha);
        C.DrawColor.A = 255 * Alpha;
        C.SetPos(Screen.X - XL / 2, Screen.Y - YL / 2);
        C.DrawText(S);
    }

    C.FontScaleX = 1.0;
    C.FontScaleY = 1.0;
}

// Whether world geometry leaves Loc (above Victim's head), or the living
// Victim's middle, visible from the camera. Either will do: under a low
// ceiling Loc can be in it while the target is in plain view.
simulated function bool InSight(Pawn Victim, vector Loc, vector CamLoc)
{
    if ( FastTrace(Loc, CamLoc) )
        return true;
    return Victim != None && !Victim.bDeleteMe && Victim.Health > 0
        && FastTrace(Victim.Location, CamLoc);
}

// white for small hits, through yellow, to red for 100 and up
simulated function color NumberColor(int Amount, float Alpha)
{
    local float T;

    T = FClamp(Amount / 100.0, 0, 1);
    if ( T < 0.5 )
        return class'Canvas'.static.MakeColor(255, 255, 255 - 400 * T, 255 * Alpha);
    return class'Canvas'.static.MakeColor(255, 255 - 300 * (T - 0.5), 55 - 110 * (T - 0.5), 255 * Alpha);
}

defaultproperties
{
    MergeTime=0.300000
    RiseTime=0.500000
    PopTime=0.100000
    PopScale=1.400000
    RiseHeight=0.040000
    UDamageColor=(B=255,G=70,R=190,A=255)
    DefensiveUDamageColor=(B=200,G=210,R=20,A=255)
    NumberSize=1.000000
    HitSoundVolume=1.000000
    HitSound=Sound'DamageNumbers.Tonk'
    HitSoundBoost=2.000000
    HitSoundInterval=0.050000
    bHitSoundPitchByDamage=False
    HitSoundPitchHigh=1.500000
    HitSoundPitchLow=0.700000
    HitSoundPitchDamage=150.000000
}
