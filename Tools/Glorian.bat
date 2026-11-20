@echo off
rem Instant DM on Glorian with all current mutators (too long for a shortcut's Target)
start "" /D "%~dp0..\System" "%~dp0..\System\UT2004.exe" DM-UCMP3-Glorian?Game=XGame.xDeathMatch?Mutator=AdrenalineReward.MutAdrenalineReward,DamageNumbers.MutDamageNumbers,UDamageRewardV2.UDamageRewardV2Mutator,UT2026Bots.UT2026BotsMutator,UT2026.UT2026Mutator?NumBots=0?Difficulty=3?QuickStart=1
