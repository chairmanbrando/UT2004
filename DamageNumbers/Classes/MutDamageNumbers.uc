//==============================================================================
//  Damage Numbers: the damage you deal pops up above whoever took it.
//  Server: DamageNumbersRules. Client: DamageNumbersInfo, DamageNumbersOverlay.
//==============================================================================

class MutDamageNumbers extends Mutator;

function PostBeginPlay()
{
    local GameRules G;

    Super.PostBeginPlay();

    // at the head of the chain, so a rule that doesn't pass hits on (or
    // declares Momentum without 'out') can't hide them
    G = Spawn(class'DamageNumbersRules');
    G.NextGameRules = Level.Game.GameRulesModifiers;
    Level.Game.GameRulesModifiers = G;
}

defaultproperties
{
    GroupName="DamageNumbers"
    FriendlyName="Damage Numbers"
    Description="The damage you deal to health and armor pops up above whoever took it, then floats up and fades out. Quick hits on the same target add up in one number. Purple with UDamage; teal on a target with UDamage Reward v2's defensive UDamage."
    bAddToServerPackages=True
}
