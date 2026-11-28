#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------------------------------------------------------- ;
; READ THIS: I haven't played this game online in 20 years. I don't even know if
; any servers are up anywhere in the world. As such I don't know if anticheats
; are able to detect AHK-sent inputs. If you're gonna play online it would seem
; wise to stop this script beforehand. Just in case. I mean, you wouldn't want
; to get banned from one of the three servers online, would you? I think not.
; ---------------------------------------------------------------------------- ;

; ----- Change to your install location. ----- ;
try TraySetIcon "E:\Steam\steamapps\common\Unreal Tournament 2004\System\UT2004.exe", 1

; ----- Tweak these if things don't feel right. ----- ;
KeyDelay  := 30 ; ms between keystrokes ("typing speed")
PressTime := 20 ; ms each key is held down before release

; ----- Event mode is the only one that honours `SetKeyDelay`. ----- ;
SendMode "Event"
SetKeyDelay KeyDelay, PressTime

#HotIf WinActive("ahk_exe UT2004.exe")

; W + Mouse5 (either order) -> w Space w
~w & XButton2::
~XButton2 & w::Send "{w}{Space}{w}"

; A + Mouse5 (either order) -> a Space a
~a & XButton2::
~XButton2 & a::Send "{a}{Space}{a}"

; S + Mouse5 (either order) -> s Space s
~s & XButton2::
~XButton2 & s::Send "{s}{Space}{s}"

; D + Mouse5 (either order) -> d Space d
~d & XButton2::
~XButton2 & d::Send "{d}{Space}{d}"

; Set F13 to `quit` in `User.ini`.
^F11::Send "{F13}"

#HotIf
