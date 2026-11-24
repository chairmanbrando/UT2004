//==============================================================================
//  The instagib beam: traced through players (PierceTrace, with bPierce), then
//  drawn as one beam, from the shooter to where it stopped, in the team's or
//  the set colour (SpawnBeam). For IBSuperShockBeamFire and
//  IBZoomSuperShockBeamFire.
//==============================================================================

class IBUtil extends Object;

// the beam colours by team, with BeamColor blank. Red's a little dimmer, as
// red looks brighter than blue at the same strength.
var color RedTeamColor, BlueTeamColor;

// A railgun shot: Start to End in one straight line, through every player
// (not vehicle) in it. Hits gets each player gone through, in order, and
// HitLocs where; the trace goes on from each, traced from them so it skips
// them. Returns what stopped it, with HitLocation and HitNormal: the level, a
// vehicle or anything else, or a player past MaxHits; or None, with
// HitLocation = End and no HitNormal. Nothing is damaged here, so no victim
// is gibbed away mid-trace.
static function Actor PierceTrace(Actor Tracer, vector Start, vector End, int MaxHits,
    out array<Pawn> Hits, out array<vector> HitLocs, out vector HitLocation, out vector HitNormal)
{
    local Actor Other;
    local int i, Steps;

    Hits.Length = 0;
    HitLocs.Length = 0;
    // a safety cap: overlapping players could pass the trace back and forth
    for ( Steps = 0; Steps < 64; Steps++ )
    {
        Other = Tracer.Trace(HitLocation, HitNormal, End, Start, true);
        if ( Other == None )
            break;
        if ( Pawn(Other) == None || Vehicle(Other) != None || Hits.Length >= MaxHits )
            return Other;

        // each player once, if overlapping ones pass the trace back and forth
        for ( i = 0; i < Hits.Length; i++ )
            if ( Hits[i] == Other )
                break;
        if ( i == Hits.Length )
        {
            Hits[i] = Pawn(Other);
            HitLocs[i] = HitLocation;
        }
        Start = HitLocation;
        Tracer = Other;
    }
    HitLocation = End;
    HitNormal = vect(0,0,0);
    return None;
}

// SuperShockBeamFire.DoTrace, piercing with bPierce (up to MaxHits players),
// otherwise stopping at the first, as plain instagib's does
static function FireBeam(SuperShockBeamFire F, vector Start, rotator Dir, int MaxHits)
{
    local vector X, HitLocation, HitNormal;
    local Actor Other;
    local array<Pawn> Hits;
    local array<vector> HitLocs;
    local int i;

    if ( !class'InstagibBeamsMutator'.default.bPierce )
        MaxHits = 0;

    X = vector(Dir);
    Other = PierceTrace(F.Weapon, Start, Start + F.TraceRange * X, MaxHits, Hits, HitLocs, HitLocation, HitNormal);

    for ( i = 0; i < Hits.Length; i++ )
        if ( Hits[i] != None && !Hits[i].bDeleteMe )
            Hits[i].TakeDamage(F.DamageMax, F.Instigator, HitLocs[i], F.Momentum * X, F.DamageType);
    if ( Other != None && !Other.bWorldGeometry )
    {
        Other.TakeDamage(F.DamageMax, F.Instigator, HitLocation, F.Momentum * X, F.DamageType);
        HitNormal = vect(0,0,0);
    }

    if ( F.Weapon != None )
        SpawnBeam(F, Start, Dir, HitLocation, HitNormal);
}

// SuperShockBeamFire.SpawnBeamEffect, with our beam (IBTintedBeam): in the
// BeamColor setting's colour, or with it blank, the team's (BlueTeamColor for
// blue, RedTeamColor for red and for no team, as stock's beam is red then).
// Picked on the server; the beam replicates with its colour.
static function SpawnBeam(SuperShockBeamFire F, vector Start, rotator Dir, vector HitLocation, vector HitNormal)
{
    local IBTintedBeam Beam;
    local PlayerReplicationInfo PRI;
    local color C;

    if ( !CustomColor(C) )
    {
        if ( F.Instigator != None )
            PRI = F.Instigator.PlayerReplicationInfo;
        if ( PRI != None && PRI.Team != None && PRI.Team.TeamIndex == 1 )
            C = default.BlueTeamColor;
        else
            C = default.RedTeamColor;
    }

    Beam = F.Weapon.Spawn(class'IBTintedBeam',,, Start, Dir);
    if ( Beam != None )
    {
        Beam.BeamColor = C;
        Beam.AimAt(HitLocation, HitNormal);
    }
}

// The BeamColor setting, "R,G,B" with each 0-255, into C. False if it's blank
// (the team colours) or isn't three numbers.
static function bool CustomColor(out color C)
{
    local array<string> Parts;
    local string S;

    S = Repl(class'InstagibBeamsMutator'.default.BeamColor, " ", "");
    if ( S == "" )
        return false;
    Split(S, ",", Parts);
    if ( Parts.Length != 3 )
        return false;
    C.R = Clamp(int(Parts[0]), 0, 255);
    C.G = Clamp(int(Parts[1]), 0, 255);
    C.B = Clamp(int(Parts[2]), 0, 255);
    C.A = 255;
    return true;
}

defaultproperties
{
    RedTeamColor=(R=220,G=60,B=60,A=255)
    BlueTeamColor=(R=70,G=70,B=255,A=255)
}
