//==============================================================================
//  CoD Mode: go RegenDelay seconds without taking damage and your health
//  starts coming back, RegenPerSecond a second, up to RegenMaxHealth. Any hit
//  (CoDModeRules) stops it and starts the wait over. Each life starts fresh.
//  Health chargers (bases holding a health pack) hold a big mini health vial
//  instead, +15 and overhealing (CoDHealthVial). Every other pickup, mini
//  vials included, is left alone.
//==============================================================================

class CoDModeMutator extends Mutator
    config;

var config float RegenDelay;        // seconds without damage before regen starts
var config float RegenPerSecond;    // health regained a second
var config int RegenMaxHealth;      // regen stops here

// a living pawn's regen state; dropped when it dies
struct RegenRecord
{
    var Pawn P;
    var float LastHit;      // Level.TimeSeconds of its last hit (or first sighting)
    var float Partial;      // regen not yet a whole point of health
};
var array<RegenRecord> Records;

var localized string DelayDisplayText, DelayDescText;
var localized string RateDisplayText, RateDescText;
var localized string MaxDisplayText, MaxDescText;

function PostBeginPlay()
{
    local CoDModeRules Rules;

    Super.PostBeginPlay();
    Rules = Spawn(class'CoDModeRules');
    Rules.Mut = self;
    if ( Level.Game.GameRulesModifiers == None )
        Level.Game.GameRulesModifiers = Rules;
    else
        Level.Game.GameRulesModifiers.AddGameRules(Rules);
}

// any health pack on a base (UT2026's HealthPackPlus too) becomes the big vial
function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local xPickupBase B;

    B = xPickupBase(Other);
    if ( B != None && B.PowerUp != None && ClassIsChildOf(B.PowerUp, class'HealthPack') )
        B.PowerUp = class'CoDHealthVial';
    return true;
}

function int FindRecord(Pawn P)
{
    local int i;

    for ( i = 0; i < Records.Length; i++ )
        if ( Records[i].P == P )
            return i;
    i = Records.Length;
    Records.Length = i + 1;
    Records[i].P = P;
    Records[i].LastHit = Level.TimeSeconds;
    return i;
}

// from CoDModeRules: P took damage, so its regen stops and the wait starts over
function NotifyHit(Pawn P)
{
    local int i;

    i = FindRecord(P);
    Records[i].LastHit = Level.TimeSeconds;
    Records[i].Partial = 0;
}

function Tick(float DeltaTime)
{
    local Controller C;
    local Pawn P;
    local int i, Gain;

    // forget the dead and gone
    for ( i = Records.Length - 1; i >= 0; i-- )
        if ( Records[i].P == None || Records[i].P.bDeleteMe || Records[i].P.Health <= 0 )
            Records.Remove(i, 1);

    for ( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if ( !C.bIsPlayer )
            continue;
        P = C.Pawn;
        if ( Vehicle(P) != None )
            P = Vehicle(P).Driver;
        if ( P == None || P.bDeleteMe || P.Health <= 0 )
            continue;

        i = FindRecord(P);
        if ( P.Health >= RegenMaxHealth )
        {
            Records[i].Partial = 0;
            continue;
        }
        if ( Level.TimeSeconds - Records[i].LastHit < RegenDelay )
            continue;

        Records[i].Partial += RegenPerSecond * DeltaTime;
        Gain = int(Records[i].Partial);
        if ( Gain > 0 )
        {
            Records[i].Partial -= Gain;
            P.Health = Min(P.Health + Gain, RegenMaxHealth);
        }
    }
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);
    PlayInfo.AddSetting(default.RulesGroup, "RegenDelay", default.DelayDisplayText, 0, 1, "Text", "4;0.0:60.0");
    PlayInfo.AddSetting(default.RulesGroup, "RegenPerSecond", default.RateDisplayText, 0, 1, "Text", "5;0.0:999.0");
    PlayInfo.AddSetting(default.RulesGroup, "RegenMaxHealth", default.MaxDisplayText, 0, 1, "Text", "3;1:199");
}

static event string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "RegenDelay":      return default.DelayDescText;
        case "RegenPerSecond":  return default.RateDescText;
        case "RegenMaxHealth":  return default.MaxDescText;
    }
    return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    RegenDelay=4.0
    DelayDisplayText="Regen Delay (s)"
    DelayDescText="Seconds without taking damage before health starts coming back."
    RegenPerSecond=25.0
    RateDisplayText="Regen Per Second"
    RateDescText="Health regained each second once regen starts."
    RegenMaxHealth=100
    MaxDisplayText="Regen Max Health"
    MaxDescText="Regen stops at this much health."
    GroupName="CoDMode"
    FriendlyName="CoD Mode"
    Description="Avoid damage for a few seconds and your health comes back. Health chargers hold a big +15 vial instead. Details: https://github.com/chairmanbrando/UT2004/blob/main/CoDMode/README.md"
    bAddToServerPackages=True
}
