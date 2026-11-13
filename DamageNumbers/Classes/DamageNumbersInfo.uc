//==============================================================================
//  One per human player, owned by their PlayerController and replicated only
//  to them: DamageNumbersRules sends the damage they deal through ClientShowDamage,
//  which hands it to their HUD's DamageNumbersOverlay. On a listen server or
//  offline, the local player's calls just run here.
//==============================================================================

class DamageNumbersInfo extends ReplicationInfo;

var DamageNumbersOverlay Overlay;	// client only

replication
{
    unreliable if ( Role == ROLE_Authority )
        ClientShowDamage;
}

// Victim arrives as None when it isn't replicated to this client; Loc is
// above its head when hit; Kind is the colour (DamageNumbersOverlay.AddDamage)
simulated function ClientShowDamage(Pawn Victim, vector Loc, int Amount, byte Kind)
{
    local PlayerController PC;

    PC = Level.GetLocalPlayerController();
    if ( PC == None || PC.myHUD == None )
        return;
    if ( Overlay == None || Overlay.bDeleteMe )
        Overlay = Spawn(class'DamageNumbersOverlay');
    if ( Overlay == None )
        return;
    PC.myHUD.AddHudOverlay(Overlay);	// ignores one it already has
    Overlay.ShowHit(PC, Victim, Loc, Amount, Kind);
}

simulated function Destroyed()
{
    if ( Overlay != None )
        Overlay.Destroy();
    Super.Destroyed();
}

defaultproperties
{
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
}
