//==============================================================================
//  Adrenaline Reward: a player killed by another throws all their adrenaline
//  out as pickups, like Sonic's rings.
//  - Every adrenaline pickup, placed or thrown, is worth PickupAmount.
//  - Thrown ones stay MyLifeSpan seconds after landing, then fade out
//    (AdrenalineRewardPickup). The throwing is AdrenalineRewardRules'.
//==============================================================================

class MutAdrenalineReward extends Mutator;

var config int PickupAmount;    // adrenaline per pickup, 1-10 (stock 2)
var config int MyLifeSpan;      // seconds a thrown pickup stays after landing (dropped weapons: 8)

var localized string AmountText, AmountDesc, LifeSpanText, LifeSpanDesc;

function PostBeginPlay()
{
    local AdrenalineRewardRules Rules;

    Super.PostBeginPlay();
    Rules = Spawn(class'AdrenalineRewardRules');
    Rules.Mut = self;
    if ( Level.Game.GameRulesModifiers == None )
        Level.Game.GameRulesModifiers = Rules;
    else
        Level.Game.GameRulesModifiers.AddGameRules(Rules);
}

function int GetPickupAmount()
{
    return Clamp(PickupAmount, 1, 10);
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    if ( AdrenalinePickup(Other) != None )
        AdrenalinePickup(Other).AdrenalineAmount = GetPickupAmount();
    return true;
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);
    PlayInfo.AddSetting(default.RulesGroup, "PickupAmount", default.AmountText, 0, 1, "Text", "2;1:10");
    PlayInfo.AddSetting(default.RulesGroup, "MyLifeSpan", default.LifeSpanText, 0, 0, "Text", "8;3:30");
}

static event string GetDescriptionText(string PropName)
{
    switch ( PropName )
    {
        case "PickupAmount":    return default.AmountDesc;
        case "MyLifeSpan":      return default.LifeSpanDesc;
    }
    return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    PickupAmount=2
    MyLifeSpan=8
    AmountText="Adrenaline Per Pickup"
    AmountDesc="How much adrenaline each pickup is worth, 1-10, both placed ones and ones thrown from fragged players (who throw one per this many points). Stock is 2; UT2003 was 3."
    LifeSpanText="Seconds dropped Adrenaline should stay"
    LifeSpanDesc="Seconds thrown Adrenaline stays on the ground before fading out. Dropped weapons stay 8."
    FriendlyName="Adrenaline Reward"
    Description="Adrenaline is thrown from a fragged player's body. Collect their power for your own!"
    GroupName="Adrenaline"
}
