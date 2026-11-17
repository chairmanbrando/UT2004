//==============================================================================
//  Adrenaline Reward: a player killed by another throws all their adrenaline
//  out as pickups, like Sonic's rings.
//  - Every adrenaline pickup, placed or thrown, is worth PickupAmount.
//  - ThrowPercent (10-100) of it is thrown; the rest is lost, or kept
//    (bKeepUnthrown).
//  - Thrown ones stay MyLifeSpan seconds after landing, then fade out
//    (AdrenalineRewardPickup). The throwing is AdrenalineRewardRules'.
//==============================================================================

class MutAdrenalineReward extends Mutator;

var config int PickupAmount;    // adrenaline per pickup, 1-10 (stock 2)
var config int MyLifeSpan;      // seconds a thrown pickup stays after landing (dropped weapons: 8)
var config int ThrowPercent;    // percent of a fragged player's adrenaline thrown, 10-100
var config bool bKeepUnthrown;  // the fragged player keeps the rest

var localized string AmountText, AmountDesc, LifeSpanText, LifeSpanDesc, PercentText, PercentDesc, KeepText, KeepDesc;

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

function int GetThrowPercent()
{
    return Clamp(ThrowPercent, 10, 100);
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
    PlayInfo.AddSetting(default.RulesGroup, "ThrowPercent", default.PercentText, 0, 1, "Text", "3;10:100");
    PlayInfo.AddSetting(default.RulesGroup, "bKeepUnthrown", default.KeepText, 0, 1, "Check");
}

static event string GetDescriptionText(string PropName)
{
    switch ( PropName )
    {
        case "PickupAmount":    return default.AmountDesc;
        case "MyLifeSpan":      return default.LifeSpanDesc;
        case "ThrowPercent":    return default.PercentDesc;
        case "bKeepUnthrown":   return default.KeepDesc;
    }
    return Super.GetDescriptionText(PropName);
}

defaultproperties
{
    PickupAmount=2
    MyLifeSpan=8
    ThrowPercent=100
    PercentText="Percent Of Adrenaline Thrown"
    PercentDesc="How much of a fragged player's adrenaline is thrown out as pickups, 10-100 percent. They lose the rest too, unless they keep it (below)."
    KeepText="Keep Unthrown Adrenaline"
    KeepDesc="A fragged player keeps the adrenaline that isn't thrown, instead of losing it."
    AmountText="Adrenaline Per Pickup"
    AmountDesc="How much adrenaline each pickup is worth, 1-10, both placed ones and ones thrown from fragged players (who throw one per this many points). Stock is 2; UT2003 was 3."
    LifeSpanText="Seconds dropped Adrenaline should stay"
    LifeSpanDesc="Seconds thrown Adrenaline stays on the ground before fading out. Dropped weapons stay 8."
    FriendlyName="Adrenaline Reward"
    Description="Adrenaline is thrown from a fragged player's body. Collect their power for your own!"
    GroupName="Adrenaline"
}
