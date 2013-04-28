;-----------------------
;	For updates:
;	Change version number in exe and config file
;	Upload the changelog, file version  and new exe files to the ftp server
; 	check dont have debugging hotkeys and clipboards at end of script
;-----------------------
;	git add -A
;	git commit -m "Msg"
;	git push
;-----------------------


/*	Things to do
	Find active units /army offsets and use them in army overlay
	Unit Panel
	Check if Hatch was actually injected

*/

SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force
#MaxHotkeysPerInterval 999999
#InstallMouseHook
#InstallKeybdHook
#UseHook
#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
OnExit, ShutdownProcedure

Menu, Tray, Icon 
if not A_IsAdmin 
{
	try  Run *RunAs "%A_ScriptFullPath%"
	ExitApp
}
Menu Tray, Add, &Settings && Options, options_menu
Menu Tray, Add, &Check For Updates, TrayUpdate
Menu Tray, Add, &Homepage, Homepage
Menu Tray, Add, &Reload, g_reload
Menu Tray, Add, Exit, ShutdownProcedure
Menu Tray, Default, &Settings && Options
If A_IsCompiled
	Menu Tray, NoStandard
Else
{
	Menu Tray, Icon, Starcraft-2.ico
	debug := 1
	debug_name := "Kalamity"
}


start:
config_file := "MT_Config.ini"
old_backup_DIR := "Old Macro Trainers"
url := []
url.vr := "http://www.users.on.net/~jb10/macro_trainer_version.txt"
url.changelog := "http://www.users.on.net/~jb10/MT_ChangeLog.txt"
url.HelpFile := "http://www.users.on.net/~jb10/Macro Trainer Help File.htm"
url.Homepage := "http://www.users.on.net/~jb10/"
url.PixelColour := url.homepage "Macro Trainer/PIXEL COLOUR.htm"

version := 2.963

l_GameType := "1v1,2v2,3v3,4v4,FFA"
l_Races := "Terran,Protoss,Zerg"
GameWindowTitle := "StarCraft II"
GameIdentifier := "ahk_exe SC2.exe"
GameExe := "SC2.exe"

SAPI := ComObjCreate("SAPI.SpVoice")	; ComObjCreate("SAPI.SpVoice").Speak("Please read this file")
pToken := Gdip_Startup()
SetupUnitIDArray(A_unitID)
setupTargetFilters(a_UnitTargetFilter)
SetupColourArrays(HexColour, MatrixColour)

Menu, Tray, Tip, MT_V%version% Coded By Kalamity

If InStr(A_ScriptDir, old_backup_DIR)
{
	Msgbox, 4372, Launch Directoy?, This program has been launched from the "%old_backup_DIR%" directory.`nThis could be caused by running  the program via a shortcut/link after the program has updated.`nThis is due to the fact that the windows shortcut is updated to the old versions 'new/backup' location.`nIn future, please don't run this program using shortcuts.`n`nI recommend pressing NO to EXIT.`n`n %A_Tab% Continue?
	IfMsgBox No
		ExitApp
}
Gosub, pre_startup ; go read the ini file
SoundSet, %overall_program%
SAPI.volume := speech_volume


;-----------------------
;	Startup
;-----------------------

if HideTrayIcon
	Menu, Tray, NoIcon

InstallSC2Files()
#include %A_ScriptDir%\Included Files\Gdip.ahk
#include %A_ScriptDir%\Included Files\Colour Selector.ahk

CreatepBitmaps(a_pBitmap, a_unitID)


If (auto_update AND A_IsCompiled  AND HideTrayIcon <> 1 AND CheckForUpdates(version, url.vr ))
{
	changelog_text := Url2Var(url.changelog)
	Gui, New
	Gui +Toolwindow	+LabelAUpdate_On
	Gui, Add, Picture, x12 y10 w90 h90 , %A_ScriptName%
	Gui, Font, S10 CDefault Bold, Verdana
	Gui, Add, Text, x112 y10 w220, An update is available.
	Gui, Font, Norm 
	Gui, Add, Text, x112 y35 w560, Click UPDATE to download the latest version.
	Gui, Add, Text, x112 y+10 w560, Click CANCEL to continue running this version.
	Gui, Add, Text, x112 y+10 w560, Click DISABLE to stop the program automatically checking for updates.
	Gui, Font, S8 CDefault, Verdana
	Gui, Add, Text, x112 y+5 w560, %A_Tab% (You can still update via right clicking the tray icon.)
	Gui, Font, S10
	Gui, Add, Text, x112 y+10, You're currently running version %version%
	Gui, Font, S8 CDefault Bold, Verdana
	Gui, Add, Text, x10 y+5 w80, Changelog:
	Gui, Font, Norm 
	Gui, Add, Edit, x12 y+10 w560 h220 readonly -E0x200, % LTrim(changelog_text)
	Gui, Font, S8 CDefault Bold, Verdana
	Gui, Add, Button, Default x50 y+20 w100 h30 gUpdate, &Update
	Gui, Font, Norm 
	Gui, Add, Button, x+100 yp w100 h30 gLaunch vDisable_Auto_Update, &Disable
	Gui, Add, Button, x+100 yp w100 h30 gLaunch vCancel_Auto_Update, &Cancel
	Gui, Show,    w600, Macro Trainer Update
	Return				
}

Launch:

If (A_GuiControl = "Disable_Auto_Update")
	Iniwrite, % auto_check_updates := 0, %config_file%, Misc Settings, auto_check_updates
If (A_GuiControl = "Disable_Auto_Update" OR A_GuiControl = "Cancel_Auto_Update")
	Gui Destroy

If launch_settings
	gosub options_menu
CreateHotkeys()			;create them before launching the game incase users want to edit them
process, exist, %GameExe%
If !errorlevel
{
	RegRead, SC2InstallPath, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Blizzard Entertainment\StarCraft II Retail, GamePath
	try run %SC2InstallPath%
}
Process, wait, %GameExe%	; waits for starcraft to exist
while (!(B_SC2Process := getProcessBaseAddress(GameIdentifier)) || B_SC2Process < 0)		;using just the window title could cause problems if a folder had the same name e.g. sc2 folder
	sleep 250				; required to prevent memory read error - Handle closed: error 		;note the space before end quote
LoadMemoryAddresses(B_SC2Process)	
settimer, clock, 200
settimer, timer_exit, 5000
SetTimer, OverlayKeepOnTop, 1000, -10	;better here, as since WOL 2.0.4 having it in the "clock" section isn't reliable 
return
;-----------------------
; End of execution
;-----------------------
LWin & Space::	
		SetMouseDelay, 10	; to ensure release modifiers works
		SetKeyDelay, 10			
		releaseAllModifiers() 					;This will be active irrespective of the window
		RestoreModifierPhysicalState("Unblock")		;input on
		settimer, EmergencyInputCountReset, 5000	
		EmergencyInputCount ++		 
		If EmergencyInputCount >= 3
		{
		g_reload:
			SoundPlay, %A_Temp%\Windows Ding.wav
			if time && alert_array[GameType, "Enabled"]
				WriteOutWarningArrays()
			try  Run *RunAs "%A_ScriptFullPath%"
		;	try  Run "%A_ScriptFullPath%"
			ExitApp	;does the shutdown procedure.
		}
		SoundPlay, %A_Temp%\Windows Ding2.wav
	return	

EmergencyInputCountReset:
	settimer, EmergencyInputCountReset, off
	EmergencyInputCount := 0
	Return

g_ListVars:
	ListVars
	return

Stealth_Exit:
	ExitApp
	return
g_PlayModifierWarningSound:
	SoundPlay, %A_Temp%\ModifierDown.wav
return
ping:
	send, !g
	sleep 10
	Click
	Return

g_DoNothing:
Return			
g_LbuttonDown:	;Get the location of a dragbox
	MouseGetPos, MLDownX, MLDownY
Return	
	
speaker_volume_up:
	Send {Volume_Up 2}
	SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
	return
	
speaker_volume_down:
	Send {Volume_Down 2}
	SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
	return
	
speech_volume_up:
	if (100 <  speech_volume := SAPI.volume + 2)
		speech_volume := 100
	SAPI.volume := speech_volume
	SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
	return

speech_volume_down:
	if (0 > speech_volume := SAPI.volume - 2)
		speech_volume := 0
	SAPI.volume := speech_volume
	SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
	return

program_volume_up:
	SoundSet, +2
	SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
	Return

program_volume_down:	
	SoundSet, -2
	SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
	Return
	
g_GLHF:
	ReleaseModifiers(0)
	if !isChatOpen()
		send, +{Enter}
	send, GL{ASC 3}HF{!}
return

g_DeselectUnit:
if (getSelectionCount() > 1)
{
	mousegetpos, Xmouse, Ymouse
	ClickUnitPortrait(0, X, Y, Xpage, Ypage) ; -1 as selection index begins at 0 i.e 1st unit at pos 0 top left
	send +{click Left %X%, %Y%} 	
	send {click  %Xmouse%, %Ymouse%, 0}
}
return


ReleaseModifiersOld(Beep = 1, CheckIfCasting = 0)
{
	while (iscasting := CheckIfCasting && isUserCastingOrBuilding()) || getkeystate("Ctrl", "P") || getkeystate("Alt", "P") 
	|| getkeystate("Shift", "P") || getkeystate("LWin", "P") || getkeystate("RWin", "P")
	{
		count++
		if (count = 1 && Beep) && !iscasting 	;wont beep if casting
			SoundPlay, %A_Temp%\ModifierDown.wav	
		sleep, 5
	}
	if count
		sleep, 35	;give time for sc2 to update keystate - it can be a slower!
}

ReleaseModifiers(Beep = 1, CheckIfCasting = 0)
{
	startReleaseModifiers:
	count := 0
	firstRun++
	while (iscasting := CheckIfCasting && isUserCastingOrBuilding()) || getkeystate("Ctrl", "P") || getkeystate("Alt", "P") 
	|| getkeystate("Shift", "P") || getkeystate("LWin", "P") || getkeystate("RWin", "P")
	{
		count++
		if (count = 1 && Beep) && !iscasting && firstRun = 1	;wont beep if casting
			SoundPlay, %A_Temp%\ModifierDown.wav	
		sleep, 5
	}

	if count
	{
		if (firstRun = 1)
			sleep, 35	;give time for sc2 to update keystate - it can be a slower! 
		gosub, startReleaseModifiers
	}
	return
}


g_SendBaseCam:
	send, {Backspace}
return
g_CreateBaseCam1:
	send, +{F2}
Return
g_CreateBaseCam2:
	send, +{F3}
Return
g_CreateBaseCam3:
	send, +{F4}
Return
g_BaseCam1:
	send, {F2}
Return
g_BaseCam2:
	send, {F3}
Return
g_BaseCam3:
	send, {F4}
Return	

g_FineMouseMove:
	FineMouseMove(A_ThisHotkey)
Return

FineMouseMove(Hotkey)
{
	MouseGetPos, MX, MY
	if (Hotkey = "Left")
		mousemove, (MX-1), MY
	else if (Hotkey = "Right")
		mousemove, (MX+1), MY
	else if (Hotkey = "Up")
		mousemove, MX, MY-1
	else if (Hotkey = "Down")
		mousemove, MX, MY+1
}

g_FindTestPixelColourMsgbox:
	IfWinExist, Pixel Colour Finder
	{	
		WinActivate
		Return 					
	}
	Gui, New
	Gui +Toolwindow	+AlwaysOnTop
	Gui, Font, S10 CDefault Bold, Verdana
	Gui, Add, Text, x+40 y+10 w220, Colour Finder:
	Gui, Font,
	Gui, Add, Text, x20 y+10, Click " Help "  to learn how to set the pixel colour.
	Gui, Add, Text, x20 Y+10, Click " Start "  to begin.
	Gui, Add, Text, x20 y+10, Click " Cancel "  to leave.
	Gui, Add, Button, Default x30 y+30 w100 h30 default gg_PixelColourFinderHelpFile, &Help
	Gui, Add, Button, Default x+30  w100 h30 gg_FindTestPixelColour, Start
	Gui, Add, Button, Default x+30  w100 h30 gGuiReturn, Cancel
	Gui, Font, Norm 
	gui, show,, Pixel Colour Finder
return

g_PixelColourFinderHelpFile:
	IfWinExist, Pixel Finder - How To:
	{	WinActivate
		Return 					
	}
	Gui, New 
	Gui Add, ActiveX, xm w980 h640 vWB, Shell.Explorer
	WB.Navigate(url.PixelColour)
	Gui, Show,, Pixel Finder - How To:
Return

g_FindTestPixelColour:
	Gui, Destroy
	g_FindTestPixelColour()
Return

g_FindTestPixelColour()
{ 	global AM_MiniMap_PixelColourAlpha, AM_MiniMap_PixelColourRed, AM_MiniMap_PixelColourGreen, AM_MinsiMap_PixelColourBlue
	SoundPlay, %A_Temp%\Windows Ding.wav
	l_DirectionalKeys := "Left,Right,Up,Down"
	loop, parse, l_DirectionalKeys, `,
		hotkey, %A_loopfield%, g_FineMouseMove, on
	loop
	{
		pBitMap := GDIP_BitmapFromScreen()
		MouseGetPos, MX, MY
		FoundColour := GDIP_GetPixel(pbitmap, MX, MY) ;ARGB format
		GDIP_DisposeImage(pBitMap)
		tooltip, % "Found Colour: "  A_Tab FoundColour "`n`nUse the Left/Right/Up/Down Arrows to move the mouse accurately`n`n" A_Tab "Press Enter To Save`n`n" A_Tab "Press Backspace To Cancel", MX+50, MY-70
		if getkeystate("Enter", "P")
		{
			SoundPlay, %A_Temp%\Windows Ding.wav
			Gdip_FromARGB(FoundColour, A, R, G, B)	
			guicontrol, Options:, AM_MiniMap_PixelColourAlpha, %A%
			guicontrol, Options:, AM_MiniMap_PixelColourRed, %R%
			guicontrol, Options:, AM_MiniMap_PixelColourGreen, %G%
			guicontrol, Options:, AM_MinsiMap_PixelColourBlue, %B%
			break
		}
		else if getkeystate("Backspace", "P")
			break
	}
	tooltip
	loop, parse, l_DirectionalKeys, `,
		hotkey, %A_loopfield%, g_FineMouseMove, off
return
}

g_PrevWarning:
	If PrevWarning
	{
		DSpeak(PrevWarning.speech)
		MiniMapWarning.insert({"Unit": PrevWarning.unitIndex, "Time": Time})
	}
	Else DSpeak("There have been no alerts")
Return
	
Adjust_overlay:
	Dragoverlay := 1
	{
		SetBatchLines, -1
		gosub overlay_timer
		if DrawUnitOverlay
			gosub g_unitPanelOverlay_timer
		SetTimer, OverlayKeepOnTop,off
		SetTimer, overlay_timer, 50, 0		; make normal priority so it can interupt this thread to move
		SetTimer, g_unitPanelOverlay_timer, 50, 0
		SoundPlay, %A_Temp%\On.wav
	}	
	sleep 500
	KeyWait, %AdjustOverlayKey%, T40
	Dragoverlay := 0	 	
	{
		SetBatchLines, %SetBatchLines%
		SetTimer, OverlayKeepOnTop, 1000, -10
		SetTimer, overlay_timer, %OverlayRefresh%, -11
		SetTimer, g_unitPanelOverlay_timer, %UnitOverlayRefresh%, -11
		SoundPlay, %A_Temp%\Off.wav
		WinActivate, %GameIdentifier%
	}
Return	

Toggle_Identifier:
	If OverlayIdent = 3
		OverlayIdent := 0
	Else OverlayIdent ++
	Iniwrite, %OverlayIdent%, %config_file%, Overlays, OverlayIdent
Return

	
Overlay_Toggle:
	if (A_ThisHotkey = CycleOverlayKey)
	{
		If (3 = ActiveOverlays := DrawIncomeOverlay + DrawResourcesOverlay + DrawArmySizeOverlay)
		{
			DrawResourcesOverlay := DrawArmySizeOverlay := DrawIncomeOverlay := 0
			DrawResourcesOverlay(-1), DrawArmySizeOverlay(-1), DrawIncomeOverlay(-1)
		}
		Else if ( 2 = ActiveOverlays)
		{
			DrawResourcesOverlay := DrawArmySizeOverlay := !DrawIncomeOverlay := 1
			DrawResourcesOverlay(-1),DrawArmySizeOverlay(-1)
		}
		Else If (ActiveOverlays = 0)
			DrawIncomeOverlay := 1
		Else
		{
			If DrawIncomeOverlay
				DrawResourcesOverlay := !DrawIncomeOverlay := 0, DrawIncomeOverlay(-1) 				
			Else If DrawResourcesOverlay
				DrawArmySizeOverlay := !DrawResourcesOverlay := 0, DrawResourcesOverlay(-1)
			Else If DrawArmySizeOverlay
				DrawResourcesOverlay := DrawArmySizeOverlay := DrawIncomeOverlay := 1	
		}

	}	
	Else If (A_ThisHotkey = ToggleIncomeOverlayKey)
	{
		If (!DrawIncomeOverlay := !DrawIncomeOverlay)
			DrawIncomeOverlay(-1)	
	}
	Else If (A_ThisHotkey = ToggleResourcesOverlayKey)
	{
		If (!DrawResourcesOverlay := !DrawResourcesOverlay)
			DrawResourcesOverlay(-1)
	}
	Else If (A_ThisHotkey = ToggleArmySizeOverlayKey)
	{
		If (!DrawArmySizeOverlay := !DrawArmySizeOverlay)
			DrawArmySizeOverlay(-1)	
	}
	Else If (A_ThisHotkey = ToggleWorkerOverlayKey)
	{
		If (!DrawWorkerOverlay := !DrawWorkerOverlay)
			DrawWorkerOverlay(-1)
	}	
	Else If (A_ThisHotkey = ToggleIdleWorkersOverlayKey)
	{
		If (!DrawIdleWorkersOverlay := !DrawIdleWorkersOverlay)
			DrawIdleWorkersOverlay(-1)
	}	
	Else If (A_ThisHotkey = ToggleUnitOverlayKey)
	{
		If (!DrawUnitOverlay := !DrawUnitOverlay)
			DrawUnitOverlay(-1)
	}
	If (A_ThisHotkey = ToggleUnitOverlayKey) || (A_ThisHotkey = ToggleBuildingConstructionOverlayKey) 
		gosub, g_unitPanelOverlay_timer
	else gosub, overlay_timer ;this makes the change take effect immediately. 
Return
	
mt_pause_resume:
	if (mt_on := !mt_on)	; 1st run mt_on blank so considered false and does else	
	{
		game_status := "lobby" ; with this clock = 0 when not in game 
		timeroff("clock", "money", "gas", "scvidle", "supply", "worker", "inject", "Force_Inject", "Force_Inject_Alert", "unit_bank_read", "warpgate_warn", "Auto_mine", "Auto_Group", "MiniMap_Timer", "overlay_timer", "g_unitPanelOverlay_timer")
		inject_timer := 0	;ie so know inject timer is off
		DSpeak("Macro Trainer Paused")
	}	
	Else
	{
		settimer, clock, 200
		DSpeak("Macro Trainer Resumed")
	}
return
;------------
;	clock
;------------
clock:
	time := GetTime()
	if (!time AND game_status = "game") OR (UpdateTimers) ; time=0 outside game
	{	
		game_status := "lobby" ; with this clock = 0 when not in game (while in game at 0s clock = 44)	
		timeroff("money", "gas", "scvidle", "supply", "worker", "inject", "Force_Inject", "Force_Inject_Alert", "unit_bank_read", "warpgate_warn", "Auto_mine", "Auto_Group", "MiniMap_Timer", "overlay_timer", "g_unitPanelOverlay_timer")
		inject_timer := TimeReadRacesSet := UpdateTimers := Overlay_RunCount := PrevWarning := WinNotActiveAtStart := ResumeWarnings := 0 ;ie so know inject timer is off
		Try DestroyOverlays()
	}
	Else if (time AND game_status <> "game" AND getLocalPlayerNumber() <> 16)    OR (debug AND time AND game_status <> "game") ; Local slot = 16 while in lobby - this will stop replay announcements
	{
		game_status := "game", warpgate_status := "not researched"
		Alert_TimedOut := [], Alerted_Buildings := [], Alerted_Buildings_Base := []  
		MiniMapWarning := [], a_BaseList := []
		if WinActive(GameIdentifier)
			ReDraw := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := RedrawUnit := RedrawConstruction := 1
		if idle_enable	;this is the idle AFK
			settimer, user_idle, 1000
;		if (MaxWindowOnStart && !Auto_Mine && time < 5)  ;as automine has its own
		if (MaxWindowOnStart && time < 5)  ; automine currently disabled
		{	MouseMove A_ScreenWidth/2, A_ScreenHeight/2	;which has a longer sleep
			WinActivate, %GameIdentifier%
			WinNotActiveAtStart := 1
		}
		Gosub, player_team_sorter
		if (ResumeWarnings || UserSavedAppliedSettings) ; UserSavedAppliedSettings saved/applied from options as resume gets blanked
			ParseWarningArrays()
		if	mineralon
			settimer, money, 500
		if	gas_on
			settimer, gas, 1000
		if idleon		;this is the idle worker
			settimer, scvidle, 500	; the idle scv pointer changes every game
		if supplyon
			settimer, supply, 200
		if workeron
			settimer, worker, 1000
		if ( Auto_Read_Races AND race_reading ) && 	!((ResumeWarnings || UserSavedAppliedSettings) && time > 12)
			SetTimer, find_races_timer, 1000
		If (a_LocalPlayer["Race"] = "Terran")
			SupplyType := A_unitID["SupplyDepot"]
		Else If (a_LocalPlayer["Race"] = "Protoss")
			SupplyType := A_unitID["Pylon"]		
		if (alert_array[GameType, "Enabled"] || warpgate_warn_on || supplyon) 
			settimer, unit_bank_read, %UnitDetectionTimer_ms%			
		SetMiniMap(minimap)
		setupMiniMapUnitLists()
		l_ActiveDeselectArmy := setupSelectArmyUnits(l_DeselectArmy, A_unitID)
		ShortRace := substr(LongRace := a_LocalPlayer["Race"], 1, 4) ;because i changed the local race var from prot to protoss i.e. short to long
		setupAutoGroup(a_LocalPlayer["Race"], A_AutoGroup, A_unitID, A_UnitGroupSettings)
		If A_UnitGroupSettings["AutoGroup", ShortRace, "Enabled"]
			settimer, Auto_Group, %AutoGroupTimer%
		CreateHotkeys()
		if (a_LocalPlayer["Name"] == "Kalamity")
		{
			Hotkey, If, WinActive(GameIdentifier) && time
			hotkey, >!g, g_GLHF
			hotkey, +ESC, g_DeselectUnit
			Hotkey, If
		}	
		If (DrawMiniMap OR DrawAlerts OR DrawSpawningRaces)
			SetTimer, MiniMap_Timer, %MiniMapRefresh%, -10		
		SetTimer, overlay_timer, %OverlayRefresh%, -11	;lowest priority
		SetTimer, g_unitPanelOverlay_timer, %UnitOverlayRefresh%, -11	;lowest priority

		EnemyBaseList := GetEBases()		
;		If Auto_Mine
;			settimer, Auto_mine, 100
		UserSavedAppliedSettings := 0		
	}
return

setupMiniMapUnitLists()
{	local list, unitlist, ListType
	list := "UnitHighlightList1,UnitHighlightList2,UnitHighlightList3,UnitHighlightExcludeList"
	Loop, Parse, list, `,
	{	
		ListType := A_LoopField
		Active%ListType% := ""		;clear incase changed via options between games	
		StringReplace, unitlist, %A_LoopField%, %A_Space%, , All ; Remove Spaces also creates var unitlist				
		unitlist := Trim(unitlist, " `t , |")	; , or `, both work - remove spaces, tabs and commas
		loop, parse, unitlist, `,
			Active%ListType% .= A_unitID[A_LoopField] ","
		Active%ListType% := RTrim(Active%ListType%, ",")
	}
	Return
}

setupSelectArmyUnits(l_input, A_unitID)
{
	a_Units := []
	StringReplace, l_input, l_input, %A_Space%, , All ; Remove Spaces
	l_input := Trim(l_input, " `t , |")
	loop, parse, l_input, `,
		l_army .= A_unitID[A_LoopField] ","
	return 	l_army := Trim(l_army, " `t , |")
}


;----------------------
;	player_team_sorter
;-----------------------
player_team_sorter:
a_player := [], a_LocalPlayer := []
;LocalPlayerNumber := ReadMemory_Str(local_ID_off, , , , "#")
Loop, 8	;doing it this way allows for custom games with blank slots ;can get weird things if 16
{
	if (!getPlayerName(A_Index)) ;empty slot custom games?
	OR IsInList(getPlayerType(A_Index), 5, 6) ; 0=EmptySlot 3=Neut 5=ref 6=spec
		Continue
	a_player[A_Index] :=  new c_Player(A_Index)   
	If (A_Index = getLocalPlayerNumber())  OR (debug AND getPlayerName(A_Index) == debug_name)
		a_LocalPlayer :=  new c_Player(A_Index)
}
IF (IsInList(a_LocalPlayer.Type, 5, 6) OR (A_IsCompiled AND a_LocalPlayer.Type = 16))
	timeroff("money", "gas", "scvidle", "supply", "worker", "inject", "Force_Inject", "Force_Inject_Alert", "unit_bank_read", "warpgate_warn", "Auto_mine", "Auto_Group", "MiniMap_Timer", "overlay_timer", "g_unitPanelOverlay_timer") ;Pause all warnings. Clock still going so will resume next game
GameType := GetGameType(a_Player)
return
;-------------------------
;	End of Game 'Setup'
;-------------------------

Cast_ChronoGates:
	ReleaseModifiers()
	Critical
	SetMouseDelay, %CG_KeyDelay%	; 10 is default
	SetKeyDelay, %CG_KeyDelay%	
	BufferInput(aButtons.List, "Block")
	MouseGetPos, start_x, start_y
	send % "^" CG_control_group
	;Send, ^%CG_control_group%
	warp_gate_chrono(a_WarpGates, nexus_list, chrono_count)
	max_chronod := chrono_count - CG_chrono_remainder
	if (max_chronod >= 1)
	{
		send % CG_nexus_Ctrlgroup_key
		for index, unit in a_WarpGates
		{
			If (A_index > max_chronod)
				Break
			sleep, %Chrono_Gate_Sleep% 
			getMiniMapMousePos(unit, click_x, click_y)
			If (CG_Random_off = 1)
				Random, Random , -1, 1
			Else
				Random := 0
			click_x := click_x + Random , click_y := click_y + Random
			send % chrono_key
			If HumanMouse
				MouseMoveHumanSC2("x" click_x "y" click_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
			send {click Left %click_x%, %click_y%}
		}
		send % CG_control_group
		If HumanMouse
			MouseMoveHumanSC2("x" start_x "y" start_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
		MouseMove, start_x, start_y
	}
	BufferInput(aButtons.List) ;re-enable keys without sending buffer
	SetMouseDelay, 10	; default
	SetKeyDelay, 10		
	Critical Off	
Return

Auto_Group:
	critical
	AutoGroup(A_AutoGroup, AG_Delay)
	critical, off
	Return
	
AutoGroup(byref A_AutoGroup, AGDelay = 0)	;byref slightly faster...
{ 	global GameIdentifier
	static PrevSelectedUnits, SelctedTime
	; CtrlList := "" ;if unit type not in listt add to it - give count of list type
	CtrlType_i := 0 
	selection_i := getSelectionCount()
	UnitType_i := getSelectionTypeCount()
	while ( A_Index <= selection_i )		;loop thru the units in the selection buffer	
	{
		unit := getSelectedUnitIndex(A_Index - 1) 
		type := getUnitType(Unit) 					;note no -1 (as ctrl index starts at 0)
		If !isUnitLocallyOwned(Unit)
		{
				WrongUnit := 1
				break
		}
		if (A_Index > 1) && (A_Index < selection_i)
			CurrentlySelected .= "|"
		CurrentlySelected .= unit
		found := 0
		For Player_Ctrl_Group, ID_List in A_AutoGroup	;check the array - player_ctrl_group = key 1,2,3 etc, ID_List is the value
		{
			if type in %ID_List%
			{
				found := 1
				If !InStr(CtrlList, type) ;ie not in it
				{
					CtrlType_i ++	;probably don't really need this count mechanism anymore
					CtrlList .= type "|"
					CtrlGroupSet .= Player_Ctrl_Group "|"						
				}
				If !isInControlGroup(Player_Ctrl_Group, unit)  ; add to said ctrl group If not in group
					Player_Ctrl_GroupSet := Player_Ctrl_Group
				break		
			}				
		}
		if !found
		{
			WrongUnit := 1
			break
		}
	}

	if (CurrentlySelected <> PrevSelectedUnits || WrongUnit)
	{
		PrevSelectedUnits := CurrentlySelected
		SelctedTime := A_Tickcount
	}
	if (A_Tickcount - SelctedTime >= AGDelay) && !WrongUnit  && (CtrlType_i = UnitType_i) && (Player_Ctrl_GroupSet <> "") && WinActive(GameIdentifier) ; note <> "" as there is group 0! cant use " Player_Ctrl_GroupSet "
	{		;note, i use Alt as 'group 2' - so i have winactive here as i can 'alt tab out' thereby selecting a groupable unit and having the program send the command while outside sc2
		Sort, CtrlGroupSet, D| N U			;also now needed due to possible AG_delay and user being altabbed out when sending
		CtrlGroupSet := RTrim(CtrlGroupSet, "|")	
		Loop, Parse, CtrlGroupSet, |
			AG_Temp_count := A_Index	;this counts the number of different ctrl groups ie # 1's  and 2's etc - must be only 1
		If (AG_Temp_count = 1) && !isMenuOpen()
		&& !getkeystate("Shift", "P") && !getkeystate("Control", "P") && !getkeystate("Alt", "P")
		&& !getkeystate("LWin", "P") && !getkeystate("RWin", "P")
			send, +%Player_Ctrl_GroupSet%
	}
	Return
}

g_LimitGrouping:
	LimitGroup(A_AutoGroup, A_ThisHotkey)
Return

LimitGroup(byref UnitList, Hotkey)
{ 
	; CtrlList := "" ;if unit type not in listt add to it - give count of list type
	group := substr(Hotkey, 0)
	If (ID_List := UnitList[group]) ; ie not blank
	{
		loop, % getSelectionCount()		;loop thru the units in the selection buffer
		{
			type := getUnitType(getSelectedUnitIndex(A_Index - 1)) 					;note no -1 (as ctrl index starts at 0)
			if type NOT in %ID_List%
				Return
		}
	}
	send %Hotkey%
	Return
}	

inject_start:
	if inject_timer
	{
		inject_timer := !inject_timer
		settimer, inject, off
		DSpeak("Inject off")
	}
	else
	{
		inject_set := time
		inject_timer := !inject_timer
		settimer, inject, 250
		DSpeak("Inject on")
	}
	return

inject_reset:
	inject_set := time
	settimer, inject, off
	settimer, inject, 250
	inject_timer := 1
	DSpeak("Reset")
	return
	
Cast_DisableInject:	
	If (F_Inject_Enable := !F_Inject_Enable)
		DSpeak("Injects On")
	Else
	{
		settimer, Force_Inject, off
		settimer, Force_Inject_Alert, off
		DSpeak("Injects Off")
	}
	Return

	
BlockInput(Mode="Disable", byref L_Keys="", Delimiter="|") ; eg 	;	BlockInput("All", keylist)
{ 							
	If (Mode = "All")		;note 2 button hotkeys eg Shift+1 or ctrl+a will still work
		BlockInput, MouseMove	;note ctrl/shift/alt not in the keylists ..... 
	If (Mode = "Enable" || Mode = "All")			
		Loop, Parse, L_Keys, %Delimiter%
			Try	 Hotkey, %A_LoopField%, g_DoNothing, On
	Else
	{
		Loop, Parse, L_Keys, %Delimiter%
			Try	Hotkey, %A_LoopField%, Off
		BlockInput, MouseMoveOff	
		CreateHotkeys()	
	}
Return
}
	

cast_ForceInject:
cast_inject:
	If (A_ThisLabel = "cast_ForceInject")
		ReleaseModifiers(F_Inject_ModifierBeep, 1)	;note b4 critical section
	else ReleaseModifiers(1,0)	;hence will cast if user presses f5 and a swarmhost is highlighted
;	Critical ;cant use with input buffer, as prevents hotkey threads launching and hence tracking input
	Inject := []
	If (A_ThisLabel = "cast_ForceInject")
	{
			if !isMenuOpen()		;menu is always 1 regardless if chat is up
				settimer, Force_Inject, off
			else if isMenuOpen() & !isChatOpen()	;chat is 0 when  menu is in focus
				return ;as let the timer continue to check
			ForceCount++
			if F_Inject_Beep
				SoundPlay, %A_Temp%\Windows Ding3.wav 
	}
	Thread, NoTimers, true  ;cant use critical with input buffer, as prevents hotkey threads launching and hence tracking input
	Inject := []
	SetBatchLines -1
	SetMouseDelay, %I_KeyDelay%	; 10 is default
	SetKeyDelay, %I_KeyDelay%	

	If (Inject.LMouseState := GetKeyState("LButton")) ; 1=down
		send {click Left up}
	BufferInput(aButtons.List, "Buffer", 0)

	MouseGetPos, start_x, start_y
	If (ChatStatus := isChatOpen())
	{
		Xscentre := A_ScreenWidth/2, Yscentre := A_ScreenHeight/2
		send {click Left %Xscentre% %Yscentre%}
	}
	If (A_ThisLabel = "cast_ForceInject")
		castInjectLarva(auto_inject, 1, F_Sleep_Time)	
	else castInjectLarva(auto_inject, 0, auto_inject_sleep) ;ie nomral injectmethod

	If Inject.LMouseState 
	{
		If HumanMouse
			MouseMoveHumanSC2("x" MLDownX "y" MLDownY "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
		send {click Left down %MLDownX%, %MLDownY%}
	}
	If HumanMouse
		MouseMoveHumanSC2("x" start_x "y" start_y "t" HumanMouseTimeLo)
	Else		
		send {click  %start_x%, %start_y%, 0}
	
	If ChatStatus
		send {Enter}

	BufferInput(aButtons.List, "Send")
	if (Inject.LMouseState AND !GetKeyState("LButton", "P")) ;mouse button up
		send {click Left up}

	SetMouseDelay, 10	; default
	SetKeyDelay, 10		
	SetBatchLines %SetBatchLines%
	Thread, NoTimers, false
	inject_set := time
	if auto_inject_alert
		settimer, auto_inject, 250
	If F_Inject_Enable
	{
		random, randomForcedInjectDelay, 0, 1.2
		settimer, Force_Inject, 250	
		If F_Alert_Enable
			settimer, Force_Inject_Alert, 250	
	}
	If (A_ThisLabel = "cast_inject")
	{
		ForceCount := 0
		KeyWait, %cast_inject_key%, T4	
	}
Return
	

;----------------------
;	Auto Mine
;-----------------------	
Auto_mine:
If (time AND Time <= Start_Mine_Time + 8) && getIdleWorkers()
	{
		Settimer, Auto_mine, Off
		IF (A_ScreenWidth <> 1920) OR (A_ScreenHeight <> 1080)
			AutoMineMethod := "MiniMap"
		SetKeyDelay %AM_KeyDelay%				;sets the key delay for the current THREAD - hence any lanuched function
		SetMouseDelay %AM_KeyDelay%				;including sendwhileblocked()
		ReleaseModifiers()
		BlockInput, On
		A_Bad_patches := []
		A_Bad_patchesPatchCount := 0
		local_mineral_list := local_minerals(LocalBase, "Distance")	;Get list of local minerals	
		MouseMove A_ScreenWidth/2, A_ScreenHeight/2
		if !WinActive(GameIdentifier)
		{	WinNotActiveAtStart := 1
			WinActivate, %GameIdentifier%
			sleep 1500 ; give time for slower computers to make sc2 window 'truely' active
			DestroyOverlays()
			ReDraw := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := RedrawUnit := RedrawConstruction := 1
		}
		Gosub overlay_timer	; here so can update the overlays
		If (DrawMiniMap OR DrawAlerts OR DrawSpawningRaces)
			DrawMiniMap()
		sleep 300
		Critical 
		If (Auto_mineMakeWorker && SelectHomeMain(LocalBase))	
			MakeWorker(a_LocalPlayer["Race"])
		While (Start_Mine_Time > time := GetTime())
		{	sleep 140
			while (time = GetTime())	;opponent left game
			{	sleep 100
				if (A_index >= 10)	;game has been paused/victory screen for 1 second 
				{ 	BlockInput, Off
					Return
				}	
			}
		}
		While (GetTime() <= (Start_Mine_Time + 8) OR !A_IsCompiled) ; As if only hitting one patch, cant take more that 6 to get all minning
			if (AutoMineMethod = "MiniMap" || A_ScreenWidth <> 1920 || A_ScreenHeight <> 1080)
			{	
				if castAutoSmartMineMiniMap(local_mineral_list, AM_PixelColour, AM_MiniMap_PixelVariance/100)
					break
			}
			else 
				if castAutoMineBMap(local_mineral_list, A_Bad_patches)
					break	
		sleep 100
		Send, %escape% ; deselect gather mineral
		IF  (Auto_Mine_Set_CtrlGroup && SelectHomeMain(LocalBase))
			Send, ^%Base_Control_Group_Key%
		If (A_ScreenWidth = 1920 && A_ScreenHeight = 1080)
		{
			local_mineral_list := SortUnitsByMapOrder(local_mineral_list)	;list the patches from left to right OR up to down 
			local_mineral_list := SortByMedian(local_mineral_list) 			;converts the above list so 
			loop, parse, local_mineral_list, | 								;the patches are from middle to outer 
			{																;this trys to rally the worker to aprox middle of the field/mineral line
				if !Bad_patches[A_LoopField, "Error"]
				{	
					Get_Bmap_pixel(A_LoopField, click_x, click_y)
					send {click Left %click_x%, %click_y%}	
					sleep, % Auto_Mine_Sleep2/2 ;seems to need 1 ms
					If (getSelectionCount() = 1) AND (getSelectionType(0) = 253) 
					{
						SelectHomeMain(LocalBase)
						send {click Right %click_x%, %click_y%}	
						break
					}
				}
			}
		}
		BlockInput, Off
		SetKeyDelay 10
		SetMouseDelay 10	
		Critical Off		
	}
	Else If (Time >= Start_Mine_Time + 10) ; kill the timer if problem - done this way incase timer interupt and change time
		Settimer, Auto_mine, Off
Return	
		
SelectHomeMain(LocalBase)		
{	global	base_camera, A_unitID
	If (getSelectionCount() = 1) &&	((unit := getSelectionType(0)) = A_unitID["CommandCenter"] || Unit = A_unitID["Nexus"] || Unit = A_unitID["Hatchery"])
		return 1		
	else if (A_ScreenWidth = 1920 && A_ScreenHeight = 1080 && !Get_Bmap_pixel(LocalBase, click_x_base, click_y_base))
		send {click Left %click_x_base%, %click_y_base%}
	else 
	{
		mousemove, (X_MidScreen := A_ScreenWidth/2), (Y_MidScreen := A_ScreenHeight/2), 0 ; so the mouse cant move by pushing edge of screen 
		SendBaseCam()		
		send {click Left %X_MidScreen%, %Y_MidScreen%}
	}
	sleep 100 ; Need some time to update selection
	If (getSelectionCount() = 1) &&	((unit := getSelectionType(0)) = 48 || Unit = 90 || Unit = 117)
		return 1
	else return 0
}

MakeWorker(Race)
{ global
	If ( Race = "Terran" )
		Send, %Make_Worker_T_Key%
	Else If ( Race = "Protoss" )
		Send, %Make_Worker_P_Key%
	Else If ( Race = "Zerg" )
		Send, %Make_Worker_Z1_Key%%Make_Worker_Z2_Key%
}

SplitWorkers(Type="")
{ 	global
	if (Type = "2x3")
		Send, %Idle_Worker_Key%+%Idle_Worker_Key%+%Idle_Worker_Key%%Gather_Minerals_key%
	else if (Type = "3x2")
		Send, %Idle_Worker_Key%+%Idle_Worker_Key%%Gather_Minerals_key%
	else if (Type = "6x1")
		Send, %Idle_Worker_Key%%Gather_Minerals_key%	
	else ;select all of them
		Send, ^%Idle_Worker_Key%%Gather_Minerals_key%
}
SendBaseCam(sleep=120, blocked=1)
{ global
;	if blocked
;		send % base_camera
	send, %base_camera%
	sleep, %sleep%	; needs ~70ms to update camera
}
SortByMedian(List, Delimiter = "|", Sort = 0)		;This is used to list the mineral patches
{													; starting at the center and Working outwards
	if Sort
		Sort, list, D%Delimiter% N U
	StringSplit, Array, List, %Delimiter%		; this array isn't a real object :(
	n := Array0, MedianVal :=  round(.5*(n+1))
	Result :=  Array%MedianVal% "|"
	loop, % n
	{
		If ((HiIndex := MedianVal + A_index) <= n)
			Result .= Array%HiIndex% "|"
		If ((LoIndex := MedianVal - A_index) > 0)	;0 stores array count (hence > and not >=)
			Result .= Array%LoIndex% "|"
	}
	 return RTrim(Result, "|")
}

castAutoMineBMap(MineralList, byref A_BadPatches, Delimiter = "|") ;normal/main view/bigmap
{	global Auto_Mine_Sleep2, WorkerSplitType
	while (A_index < 4)	;just adds another safety net
		loop, parse, MineralList, %Delimiter% 
		{
			If (!(IdlePrev_i:=getIdleWorkers())) OR (BadPatches_i >= 8) 
				return 1
			If A_BadPatches[A_LoopField, "Error"]
				Continue	;hence skipping the bogus Click location	
			if !Get_Bmap_pixel(A_LoopField, click_x, click_y) || (!BasecamSent_i && (BasecamSent_i := SendBaseCam()) && !Get_Bmap_pixel(A_LoopField, click_x, click_y))
			{	;Get_Bmap_pixel returns 1 if x,y is on edge of screen --> move screen
				send {click Left %click_x%, %click_y%}		
				sleep, % Auto_Mine_Sleep2/2 ;seems to need 1 ms to update
				If (getSelectionCount() = 1) AND (getSelectionType(0) = 253) ;mineral field
				{	
					SplitWorkers(WorkerSplitType)
					Send, {click Left %click_x%, %click_y%}
					sleep, % Auto_Mine_Sleep2/2
					If getIdleWorkers() < IdlePrev_i
						continue
				}
			}
			A_BadPatches[A_LoopField, "Error"] := 1
			BadPatches_i ++
		}
	return 1
}
castAutoSmartMineMiniMap(MineralList, PixelColour, PixelVariance = 0, Delimiter = "|")	
{	global WorkerSplitType, Auto_Mine_Sleep2		; but the minimap inaccuray + the small mineral patches makes it difficult on some maps
	CoordMode, Mouse, Screen
	A_BadPatches := []	;keep this local variable, else it will affect the rally point which is done via normal view/big map
	RandMod := 1
	while (A_index < 8)	;just adds another safety net - as if only hitting one patch, with 1 worker per turn - max turns required = 6
	{
		OuterIndex := A_Index
		loop, parse, MineralList, %Delimiter% 
		{
			If (!(IdlePrev_i:=getIdleWorkers()))
			{	
				CoordMode, Mouse, Window 
				return 1	;return no idle workers
			}
			If (A_BadPatches[A_LoopField, "Error"] && OuterIndex >6 )
			{
				A_BadPatches[A_LoopField, "Error"] := ""		; this just helps increase the +/- random factor  
				RandMod := 2				; to help find a patch if the first goes have been bad
			}	
			If A_BadPatches[A_LoopField, "Error"]
				Continue
			if (OuterIndex > 5 && !selectedall)
			{
					selectedall := 1
					SplitWorkers() ; this select all of them just once
			}
			else 		
				 SplitWorkers(WorkerSplitType)
			sleep,  Auto_Mine_Sleep2 * .30		;due to game startup lag somtimes camera gets moved around. This might help?
			while (A_index < 3)
			{			
				getMiniMapMousePos(A_LoopField, X, Y)
				if !PixelSearch(PixelColour, X, Y, PixelVariance, A_index*RandMod, A_index*RandMod)
					continue
			;	msgbox % "Patch:" A_LoopField "`n" "x,y:" x ", " y "`n" "loop: " A_index "`n" "Bad x,y:" A_BadPatches[A_LoopField, "X"] ", " A_BadPatches[A_LoopField, "Y"] "`nXRand:" XRand ", " YRand
				send {click Left %X%, %Y%}
				sleep,  Auto_Mine_Sleep2	; needs ~25 ms to update idle workers else it will move camera via left - but more online due to startup lag
				if (getIdleWorkers() < IdlePrev_i)	; clicking minimap without the 'gather minerals' state being active				
					continue, 2									; we cant try the offset before the random	
			}
			A_BadPatches[A_LoopField, "Error"] := 1
		}
	}
	CoordMode, Mouse, Window 
	return 1
}

PixelSearch(Colour, byref X, byref Y,variance=0, X_Margin=6, Y_Margin=6)
{	;supply the approx location via X & Y. Then pixel is returned
	pBitMap := GDIP_BitmapFromScreen()		;im not sure if i have to worry about converting coord mode here
	Gdip_FromARGB(Colour, A, R, G, B)		;i dont belive so, as it should all be relative
	X_Max := X+X_Margin, Y_Max := Y+Y_Margin
	while ((X := X-X_Margin+A_Index-1) <= X_Max)
		while ((Y := Y-Y_Margin+A_Index-1) <= Y_Max)			
			if	((found := !Gdip_FromARGB(GDIP_GetPixel(pbitmap, X, Y), FA, FR, FG, FB) ;Gdip_FromARGB doesnt return a value hence !
			&& (FA >= A - A*variance && FA <= A + A*variance)
			&& (FR >= R - R*variance && FR <= R + R*variance)
			&& (FG >= G - G*variance && FG <= G + G*variance)
			&& (FB >= B - B*variance && FB <= B + B*variance)))
				break, 2
	GDIP_DisposeImage(pBitMap)
	if found
		return 1
	else return 0
}



;----------------------
;	races
;-----------------------
find_races_timer:
If (time < 8)
	Return
SetTimer, find_races_timer, off		

find_races:
If (A_ThisLabel = "find_races")
	TimeReadRacesSet := time
if !time	;leave this in, so if they press the hotkey whileoutside of game, wont get gibberish
	return
Else EnemyRaces := GetEnemyRaces()
if (race_clipboard && WinActive(GameIdentifier))
	clipboard := EnemyRaces
if race_speech
	DSpeak(EnemyRaces)
return

;--------------------------------------------
;    Minerals -------------
;--------------------------------------------
money:
	if (mineraltrigger <= getPlayerMinerals())
	{
			if (Mineral_i <= sec_mineral)	; sec_mineral sets how many times the alert should be read
			{
				DSpeak(w_mineral)
				settimer, money, % additional_delay_minerals *1000	; will give the second warning after additional seconds
			}
			else 	; this ensures follow up warnings are not delayed by waiting for additional seconds before running timmer
				settimer, money, 500
			Mineral_i ++
	}
	else
	{
		Mineral_i = 0
		settimer, money, 500
	}
return

;--------------------------------------------
;    Gas -------------
;--------------------------------------------
gas:	
	if (gas_trigger <= getPlayerGas())
	{
			if (Gas_i <= sec_gas)	; sec_mineral sets how many times the alert should be read
			{
				DSpeak(w_gas)
				settimer, gas, % additional_delay_gas *1000	; will give the second warning after additional seconds
			}
			if (Gas_i >= sec_gas )
				settimer, gas, 1000
			Gas_i ++
	}
	else
	{
		Gas_i = 0
		settimer, gas, 1000
	}
return				


;--------------------------------------------
;    worker production -------------
;--------------------------------------------
worker:	
	If (a_LocalPlayer["Race"] = "Terran" || a_LocalPlayer["Race"] = "Protoss")
		WorkerInProduction(a_BaseList, workerProductionTPIdle, 1 + sec_workerprod, additional_delay_worker_production, 120)
	else
	{
		if ( OldWorker_i <> NewWorker_i := getPlayerWorkerCount())
		{	;A worker has been produced or killed
			reset_worker_time := time, Worker_i = 0
			workerproduction_time_if := workerproduction_time
		}
		else
		{ 
			if  (time - reset_worker_time) > workerproduction_time_if AND (Worker_i <= sec_workerprod) ; sec_workerprod sets how many times to play warning.
			{
				If ( a_LocalPlayer["Race"] = "Terran"  )
					DSpeak(w_workerprod_T)
				Else If ( a_LocalPlayer["Race"] = "Protoss" )
					DSpeak(w_workerprod_P)
				Else If ( a_LocalPlayer["Race"] = "Zerg" )
					DSpeak(w_workerprod_Z)
				Else 
					DSpeak("Build Worker")
				workerproduction_time_if := additional_delay_worker_production ; will give the second warning after 12 ingame seconds
				reset_worker_time := time		; This allows for the additional warnings to be delayed relative to the 1st warning
				Worker_i ++
			}
		}
		 OldWorker_i := NewWorker_i
	}
	return
WorkerInProduction(a_BaseList, maxIdleTime, maxWarnings, folloupWarningDelay, MaxWorkerCount)	;add secondary delay and max workers
{	global a_LocalPlayer, w_workerprod_T, w_workerprod_P, w_workerprod_Z
	static lastWorkerInProduction, warningCount, lastwarning
	
	if (getPlayerWorkerCount() >= MaxWorkerCount)	;stop warnings enough workers
		return

	time := getTime()
	for index, Base in a_BaseList
	{
		state := isWorkerInProduction(Base) 
		if (state > 0) ;gives true if working in production > 0, or -1 if making orbital or mothership or flying etc hence >0
		{
			warningCount := 0
			lastWorkerInProduction := time
			return
		}
		else if (state < 0)
			morphingBases++
		else lazyBases++	;hence will only warn if there are no workers in production
							; and at least 1 building is capable of making workers i.e not flying/moring
	}
	if !lazyBases && morphingBases
		lastWorkerInProduction := time	;this prevents you getting a warning immeditely after the base finishes morphing
		
	if lazybases && (time - lastWorkerInProduction >= maxIdleTime) && ( warningCount < maxWarnings)
	{
		if (warningCount && time - lastwarning < folloupWarningDelay)
			return
		lastwarning := time
		warningCount++
		If ( a_LocalPlayer["Race"] = "Terran" )
			DSpeak(w_workerprod_T)
		Else If ( a_LocalPlayer["Race"] = "Protoss" )
			DSpeak(w_workerprod_P)
		Else If ( a_LocalPlayer["Race"] = "Zerg" )
			DSpeak(w_workerprod_Z)
		Else 
			DSpeak("Build Worker")	;dont update the idle time so it gets bigger
	}
	return 
}
;--------------------------------------------
;    suply -------------
;--------------------------------------------

supply:
	sup:= getPlayerSupply(), SupCap := getPlayerSupplyCap() ; Returns 0 when memory returns Fail
	if  ( !sup or sup < minimum_supply )  		;this prevents the onetime speaking before a value has been read for sup - Note 0 instead of fail due to math procedures above
		return 
	Else If ( sup < supplylower )
		trigger := sub_lowerdelta
	Else If ( sup >= supplylower AND sup < supplymid )	
		trigger := sub_middelta
	Else If ( sup >= supplymid AND sup < supplyupper )	
		trigger := sub_upperdelta
	Else if ( sup >= supplyupper )
		trigger := above_upperdelta
	if ( ( sup + trigger ) >= supcap AND supcap < 200 And !SupplyInProduction)	
	{
									; <= sec_supply, as this includes the 1st primary warning
		if (Supply_i <= sec_supply )  ; sec_supply sets how many times alert will be played it should be counted.
		{
			DSpeak(w_supply)	;this is the supply warning
			settimer, supply, % additional_delay_supply *1000
		}
		Else	; this ensures follow up warnings are not delayed by waiting for additional seconds before running timmer
			settimer, supply, 200
		Supply_i ++	
	}
	else
	{
		Supply_i = 0 	; reset alert count
		settimer, supply, 200
	}
return


;-------
; scv idle
;-------

scvidle:
	if ( time < 5 ) OR ("Fail" = idle_count := getIdleWorkers())
		return
	if ( idle_count >= idletrigger )
	{
		if (Idle_i <= sec_idle )
		{
			DSpeak(w_idle)
			settimer, scvidle, % additional_idle_workers *1000
		}
		Else
			settimer, scvidle, 500
		Idle_i ++
	}
	else
	{
		Idle_i = 0
		settimer, scvidle, 500
	}
	return

;------------
;	Inject	Timers
;------------
inject:
	if ( time - inject_set >= manual_inject_time )		;for manual inject alarm
	{
		inject_timer := 1
		inject_set:=time
		
		If W_inject_ding_on
			SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
		If W_inject_speech_on
			DSpeak(w_inject_spoken)	
	}		
	return
	
auto_inject:
	if ( time - inject_set >= auto_inject_time ) && (!F_Inject_Enable ||  ForceCount >= F_Max_Injects)
	{
		settimer, auto_inject, off
		If W_inject_ding_on
			loop, 2
			{
				SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
				sleep 150
			}	
		If W_inject_speech_on
			DSpeak(w_inject_spoken)
	}
	return
	
Force_Inject:
	if (time - inject_set >= F_Inject_Delay + randomForcedInjectDelay) AND ( ForceCount < F_Max_Injects) AND WinActive(GameIdentifier)
		gosub cast_ForceInject
	Return

Force_Inject_Alert:
	If ( time - inject_set >= F_Inject_Delay + randomForcedInjectDelay - F_Alert_PreTime ) AND ( ForceCount < F_Max_Injects) AND WinActive(GameIdentifier)
	{
		settimer, Force_Inject_Alert, off
		SoundPlay, %A_Temp%\Windows Ding2.wav  ;SoundPlay *-1
	}
	Return

Return
	
;----------------
;	User Idle
;----------------
user_idle:
; If only one hook is installed, only its type of physical input affects A_TimeIdlePhysical (the other/non-installed hook's input, both physical and artificial, has no effect).
	time := getTime()
	If ( time > UserIdle_LoLimit AND time < UserIdle_HiLimit) AND  (A_TimeIdlePhysical > idle_time *1000)	;
	{	
		settimer, user_idle, off
		pause_check := getTime()
		sleep, 500			
		if ( pause_check = getTime())
			return	; the game is already paused		
		send, +{enter}%chat_text%{enter} 
		Send, %pause_game%
	}
	Else If ( time > 10 )
		settimer, user_idle, off	
return

;------------
;	Worker Count
;------------
worker_count:
	worker_origin := A_ThisHotkey ; so a_hotkey notchanged via thread interuption
	IF 	( !time ) ; ie = 0 
	{
		DSpeak("The game has not started")
		return
	}
	If ( worker_origin = worker_count_enemy_key)
	{
		if ( GameType <> "1v1" )
		{
			DSpeak("Enemy worker count is only available in 1v1")
			return
		}	
		For slot_number in a_Player
		{
			If ( a_LocalPlayer["Team"] <> a_Player[slot_number, "Team"] )
			{
				playernumber := a_Player[slot_number, "Team"]	
				player_race := a_Player[slot_number, "Race"]
				Break
			}
		}
	}
	Else
	{
		playernumber := a_LocalPlayer["Slot"]
		player_race := 	a_LocalPlayer["Race"]
	}
	if ( "Fail" = newcount := getPlayerWorkerCount(playernumber))
	{
		DSpeak("Try Again in a few seconds")
		return
	}
	Else If ( player_race = "Terran" )
		DSpeak(newcount "SCVs")
	Else If ( player_race = "Protoss" )
		DSpeak(newcount "Probes")
	Else If ( player_race = "Zerg" )
		DSpeak(newcount "Drones")
	Else 
		DSpeak(newcount "Workers")
return	

;--------------------
;	WarpGate Warning
;--------------------
warpgate_warn:
	if (gateway_count AND !warpgate_warning_set) ;  AND warpgate_status must = "researched" 
	{
		settimer warpgate_warn, % delay_warpgate_warn *1000
		warpgate_warning_set := 1
	}
	else if ( !gateway_count  )
	{
		settimer warpgate_warn, 1000 ;reset timer back to fast
		warpgate_warn_count := 0
		warpgate_warning_set := 0
	}
	else if ( warpgate_warn_count <= sec_warpgate) 
	{
		warpgate_warn_count ++
		settimer warpgate_warn, % delay_warpgate_warn_followup *1000
		DSpeak(w_warpgate)	
	}
	else
		settimer warpgate_warn, 1000	;this is required to speed up the timer if they dont convert the gateways
return

;------------------
;	Unit Bank Read	; I wrote this when I was first startings. I should really clean it up, but I cant be fucked.
;------------------
unit_bank_read:
SupplyInProductionCount := gateway_count := warpgate_count := 0
a_BaseListTmp := []
;UnitBankCount := getUnitCount()
While (A_Index <= getHighestUnitIndex()) ; Read +10% blanks in a row
{
	u_iteration := A_Index -1
	unit_base := B_uStructure + (u_iteration * S_uStructure)
	unit_type := getUnitType(u_iteration)
	unit_owner := getUnitOwner(u_iteration)
	Filter := getUnitTargetFilter(u_iteration)	
	; unit_HP := MAXHP - sustained dmg
	; unit_HP := (ReadMemory((( ReadMemory(B_uStructure + ((A_Index - 1) * S_uStructure) + O_uModelPointer,"StarCraft II") << 5) & 0xFFFFFFFF) + u_MaxHP_Off,"StarCraft II") /4096) - (ReadMemory(B_uStructure + ((A_Index - 1) * S_uStructure) + 0x10C,"StarCraft II")/4096)
		
	If (Filter & DeadFilterFlag) || (type = "Fail")
		Continue
	IF (unit_type = supplytype && unit_owner = a_LocalPlayer["Slot"] AND isUnderConstruction(u_iteration))
			SupplyInProductionCount ++		
	if ( warpgate_warn_on AND (unit_type = A_unitID["Gateway"] OR unit_type = A_unitID["WarpGate"]) 
		AND unit_owner = a_LocalPlayer["Slot"] AND !isUnderConstruction(u_iteration)) ; 0 means its completed 
	{
		if ( unit_type = A_unitID["Gateway"]) 
		{
			gateway_count ++	
			if warpgate_warning_set
			{
				isinlist := 0
				For index in MiniMapWarning
				{
					if MiniMapWarning[index,"Unit"] = u_iteration
					{	isinlist := 1
						Break
					}		
				}
				if !isinlist
					MiniMapWarning.insert({"Unit": u_iteration, "Time": Time})
			} 
		}
		Else if (unit_type = A_unitID["WarpGate"] && warpgate_status <> "researched") ; as unit_type must = warpgate_id
		{
			warpgate_status := "researched"
			settimer warpgate_warn, 1000
		}
	}
	if (unit_type = A_unitID["Nexus"] || unit_type = A_unitID["CommandCenter"] 
	|| unit_type =  A_unitID["PlanetaryFortress"] || unit_type =  A_unitID["OrbitalCommand"])
	&& unit_owner = a_LocalPlayer["Slot"] && !isUnderConstruction(u_iteration)
		a_BaseListTmp.insert(u_iteration)
		
	if (alert_array[GameType, "Enabled"])	
	{
		loop_AlertList:
		loop, % alert_array[GameType, "list", "size"]
		{ 			; the below if statement for time		
			Alert_Index := A_Index	;the alert index number which corresponds to the ini file/config
			if  ( unit_type = A_unitID[alert_array[GameType, A_Index, "IDName"]] AND a_Player[unit_owner, "Team"] <> a_LocalPlayer["Team"]) ;So if its a shrine and the player is not on ur team
			{
				if ( time < alert_array[GameType, A_Index, "DWB"] OR time > alert_array[GameType, A_Index, "DWA"]  ) ; too early/late to warn - add unit to 'warned list'
				{			
					For index, warned_base in Alert_TimedOut	; ;checks if the exact unit is in the time list already (eg if time > dont_warn_before, the original if statement wont be true so BAS_Warning will remain "give warning")			
						if ( unit_base = Alert_TimedOut[index, unit_owner] ) ;checks if unit_type is in the list already
							continue, loop_AlertList ; dont break, as could be other alerts for same unit but with different times later/lower in list									
					Alert_TimedOut[Alert_TimedOut.maxindex() ? Alert_TimedOut.maxindex()+1 : 1, unit_owner, Alert_Index] := unit_base
					continue, loop_AlertList
				}
				Else
				{	;during warn time lets check if the unit has already been warned			
					For index, warned_base in Alert_TimedOut	; ;checks if the exact unit is in the time list already (eg if time > dont_warn_before, the original if statement wont be true so BAS_Warning will remain "give warning")			
						if ( unit_base = Alert_TimedOut[index, unit_owner, Alert_Index] ) ;checks if unit_base is in the list already					
								break loop_AlertList
																						
					If  !alert_array[GameType, A_Index, "Repeat"] ;else check if this unit type has already been warned												
						For index, warned_type in Alerted_Buildings ;	if ( unit_type = Alerted_Buildings[index, unit_owner] ) ;checks if unit_type is in the list already						
							if ( Alert_Index = Alerted_Buildings[index, unit_owner] ) ;checks if alert index i.e. alert 1,2,3 is in the list already						
								break loop_AlertList			
								
					For index, warned_unit in Alerted_Buildings_Base  ; this list contains all the exact units which have already been warned				
						if ( unit_base = Alerted_Buildings_Base[index, unit_owner] ) ;checks if unit_type is in the list already				
							break loop_AlertList ; this warning is for the exact unitbase Address																				
				}										
				MiniMapWarning.insert({"Unit": u_iteration, "Time": Time})

				If ( alert_array[GameType, "Clipboard"] && WinActive(GameIdentifier))
					clipboard := alert_array[GameType, A_Index, "Name"] " Detected - " a_Player[unit_owner, "Colour"] " - " a_Player[unit_owner, "Name"]
				PrevWarning := []
				PrevWarning.speech := alert_array[GameType, A_Index, "Name"]
				PrevWarning.unitIndex := u_iteration
				DSpeak(alert_array[GameType, A_Index, "Name"])
				if (!alert_array[GameType, A_Index, "Repeat"])	; =0 these below setup a list like above, but contins the unit_type - to prevent rewarning
					Alerted_Buildings.insert({(unit_owner): Alert_Index})
					;Alerted_Buildings[Alerted_Buildings.maxindex() ? Alerted_Buildings.maxindex()+1 : 1, unit_owner] :=  Alert_Index					
				Alerted_Buildings_Base.insert({(unit_owner): unit_base})
				;Alerted_Buildings_Base[Alerted_Buildings_Base.maxindex() ? Alerted_Buildings_Base.maxindex()+1 : 1, unit_owner] := unit_base	; prevents the same exact unit beings warned on next run thru
				break loop_AlertList	
			} ;End of if unit is on list and player not on our team 
		} ; loop, % alert_array[GameType, "list", "size"]
	} ; if (alert_array[GameType, "Enabled"])	 
} ; While ((UnitRead_i + EndCount) / getUnitCount() < 1.1)
SupplyInProduction := SupplyInProductionCount
a_BaseList := a_BaseListTmp
return


OverlayKeepOnTop:
	if (!WinActive(GameIdentifier) And ReDraw <> 1)
	{	ReDraw := ReDrawIncome := ReDrawResources := ReDrawArmySize := ReDrawWorker := ReDrawIdleWorkers := RedrawUnit := RedrawConstruction := 1
		DestroyOverlays()
	}
Return

MiniMap_Timer:
	DrawMiniMap()
Return

g_HideMiniMap:
	if DrawMiniMap
	{
		Try Gui, MiniMapOverlay: Destroy 
		sleep, 1500
		ReDraw := 1
	}
return

overlay_timer: 	;DrawIncomeOverlay(ByRef Redraw, UserScale=1, PlayerIdent=0, Background=0,Drag=0)
	If (WinActive(GameIdentifier) || Dragoverlay) ;really only needed to ressize/scale not drag - as the movement is donve via  a post message - needed as overlay becomes the active window during drag etc
	{
		If DrawIncomeOverlay
			DrawIncomeOverlay(ReDrawIncome, IncomeOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
		If DrawResourcesOverlay
			DrawResourcesOverlay(ReDrawResources, ResourcesOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
		If DrawArmySizeOverlay
			DrawArmySizeOverlay(ReDrawArmySize, ArmySizeOverlayScale, OverlayIdent, OverlayBackgrounds, Dragoverlay)
		If DrawWorkerOverlay
			DrawWorkerOverlay(ReDrawWorker, WorkerOverlayScale, Dragoverlay) ;2 less parameters
		If DrawIdleWorkersOverlay
			DrawIdleWorkersOverlay(ReDrawIdleWorkers, IdleWorkersOverlayScale, dragOverlay)
	}
Return

g_unitPanelOverlay_timer:
	DrawUnitOverlay := 1
	If (DrawUnitOverlay || DrawBuildingConstructionOverlay) && (WinActive(GameIdentifier) || Dragoverlay)
	{
		getEnemyUnits(aEnemyUnits, aEnemyBuildingConstruction)
		FilterUnits(aEnemyUnits, aEnemyBuildingConstruction, a_UnitID, a_Player)
		if DrawUnitOverlay
			DrawUnitOverlay(RedrawUnit, UnitOverlayScale, OverlayIdent, Dragoverlay)
	}
return

;--------------------
;	Mini Map Setup
;--------------------
SetMiniMap(byref minimap)
{	minimap := []

	minimap.MapLeft := getmapleft()
	minimap.MapRight := getmapright()	
	minimap.MapTop := getMaptop()
	minimap.MapBottom := getMapBottom()

	AspectRatio := getScreenAspectRatio()	
	If (AspectRatio = "16:10")
	{
		ScreenLeft := (27/1680) * A_ScreenWidth		
		ScreenBottom := (1036/1050) * A_ScreenHeight	
		ScreenRight := (281/1680) * A_ScreenWidth	
		ScreenTop := (786/1050) * A_ScreenHeight

	}	
	Else If (AspectRatio = "5:4")
	{	
		ScreenLeft := (25/1280) * A_ScreenWidth
		ScreenBottom := (1011/1024) * A_ScreenHeight
		ScreenRight := (257/1280) * A_ScreenWidth 
		Screentop := (783/1024) * A_ScreenHeight
	}	
	Else If (AspectRatio = "4:3")
	{	
		ScreenLeft := (25/1280) * A_ScreenWidth
		ScreenBottom := (947/960) * A_ScreenHeight
		ScreenRight := (257/1280) * A_ScreenWidth 
		ScreenTop := (718/960) * A_ScreenHeight
		
	}
	Else ;16:9 Else if (AspectRatio = "16:9")
	{
		ScreenLeft 		:= (29/1920) * A_ScreenWidth
		ScreenBottom 	:= (1066/1080) * A_ScreenHeight
		ScreenRight 	:= (289/1920) * A_ScreenWidth 
		ScreenTop 		:= (807/1080) * A_ScreenHeight
	}	
	minimap.ScreenWidth := ScreenRight - ScreenLeft
	minimap.ScreenHeight := ScreenBottom - ScreenTop
	minimap.MapPlayableWidth 	:= minimap.MapRight - minimap.MapLeft
	minimap.MapPlayableHeight 	:= minimap.MapTop - minimap.MapBottom
	
	if (minimap.MapPlayableWidth >= minimap.MapPlayableHeight)
	{
		minimap.scale := minimap.Screenwidth / minimap.MapPlayableWidth
		X_Offset := 0
		minimap.ScreenLeft := ScreenLeft + X_Offset
		Y_offset := (minimap.ScreenHeight - minimap.scale * minimap.MapPlayableHeight) / 2
		minimap.ScreenTop := ScreenTop + Y_offset
		minimap.ScreenBottom := ScreenBottom - Y_offset
		minimap.Height := minimap.ScreenBottom - minimap.ScreenTop
		minimap.Width := minimap.ScreenWidth 
		
	}
	else
	{
		minimap.scale := minimap.ScreenHeight / minimap.MapPlayableHeight
		X_Offset:= (minimap.ScreenWidth - minimap.scale * minimap.MapPlayableWidth)/2
		minimap.ScreenLeft := ScreenLeft + X_Offset
		minimap.ScreenRight := ScreenRight - X_Offset	
		Y_offset := 0
		minimap.ScreenTop := ScreenTop + Y_offset
		minimap.ScreenBottom := ScreenBottom - Y_offset
		minimap.Height := minimap.ScreenHeight 
		minimap.Width := minimap.ScreenRight - minimap.ScreenLeft	
	}
	minimap.UnitMinimumRadius := 1 / minimap.scale
	minimap.UnitMaximumRadius  := 10
	minimap.AddToRadius := 1 / minimap.scale			
Return
}

drawUnitRectangle(G, x, y, width, height)
{ 	global minimap
	static pPen
	width *= minimap.scale
	height *= minimap.scale
	
	x := x - width / 2
	y :=y - height /2
					;as pen is only 1 pixel, it doesn't encroach into the fill paint (only occurs when >=2)
	if !pPen
		pPen := Gdip_CreatePen(0xFF000000, 1)		
	Gdip_DrawRectangle(G, pPen, x, y, width, height)
}

FillUnitRectangle(G, x, y, width, height, colour)
{ 	global minimap
	static a_pBrush := []
	width *= minimap.scale
	height *= minimap.scale
	x := x - width / 2
	y := y - height /2

	if !a_pBrush[colour]	;faster than creating same colour again 
		a_pBrush[colour] := Gdip_BrushCreateSolid(colour)
	Gdip_FillRectangle(G, a_pBrush[colour], x, y, width, height)
}

getMiniMapMousePos(Unit, ByRef  Xvar="", ByRef  Yvar="") ; Note raounded as mouse clicks dont round decimals e.g. 10.9 = 10
{
	global minimap
	uX := getUnitPositionX(Unit), uY := getUnitPositionY(Unit)
	uX -= minimap.MapLeft, uY -= minimap.MapBottom ; correct units position as mapleft/start of map can be >0
	Xvar := round(minimap.ScreenLeft + (uX/minimap.MapPlayableWidth * minimap.Width))
	Yvar := round(minimap.Screenbottom - ( uY/minimap.MapPlayableHeight * minimap.Height))		;think about rounding mouse clicks igornore decimals
	return	
}

getMiniMapPos(Unit, ByRef  Xvar="", ByRef  Yvar="") ; unit aray index Number
{
	global minimap
	uX := getUnitPositionX(Unit), uY := getUnitPositionY(Unit)
	uX -= minimap.MapLeft, uY -= minimap.MapBottom ; correct units position as mapleft/start of map can be >0
	Xvar := minimap.ScreenLeft + (uX/minimap.MapPlayableWidth * minimap.Width)
	Yvar := minimap.Screenbottom - ( uY/minimap.MapPlayableHeight * minimap.Height)		;think about rounding mouse clicks igornore decimals
	return	
}




Homepage:
	run % url.homepage
	return

;------------
;	Exit
;------------

timer_Exit:
{
	process, exist, %GameExe%
	if !errorlevel 		;errorlevel = 0 if not exist
		ExitApp ; this will run the shutdown routine below
}
return

ShutdownProcedure:
	Closed := ReadMemory()
	Closed := ReadMemory_Str()
	Gdip_Shutdown(pToken)
	If A_IsCompiled
	{	
		SoundGet, volume
		volume := Round(volume, 0)
		Iniwrite, %volume%, %config_file%, Volume, program
		if SAPI ; needed as simple work around if user exits script b4 5 second wait
		{ 	
			speech_volume := Round(SAPI.volume, 0)
			Iniwrite, %speech_volume%, %config_file%, Volume, speech
		}
	}
	ExitApp

Return

;------------
;	Updates
;------------

GuiReturn:
	Gui Destroy
	Return 

OptionsGuiClose:
OptionsGuiEscape:
Gui Destroy
Gosub pre_startup	;so the correct values get read back for time *1000 conversion from ms/s vice versa
Return				

GuiClose:
GuiEscape:
	Gui Destroy
Return	

AUpdate_OnClose: ;from the Auto Update GUI
	Gui Destroy
	Goto Launch
	
TrayUpdate:
	IfWinExist, Macro Trainer Update
	{	WinActivate
		Return 					
	}
	IF (CheckForUpdates(version, url.vr ))
	{
		changelog_text := Url2Var(url.changelog)
		Gui, New
		Gui +Toolwindow	
		Gui, Add, Picture, x12 y10 w90 h90 , %A_ScriptName%
		Gui, Font, S10 CDefault Bold, Verdana
		Gui, Add, Text, x112 y10 w220, An update is available.
		Gui, Font, Norm 
		Gui, Add, Text, x112 y35 w300, Click UPDATE to download the latest version.
		Gui, Add, Text, x112 y+5, You're currently running version %version%
		Gui, Font, S8 CDefault Bold, Verdana
		Gui, Add, Text, x112 y+5 w80, Changelog:
		Gui, Font, Norm 
		Gui, Add, Edit, x12 y+10 w560 h220 readonly -E0x200, % LTrim(changelog_text)
		Gui, Font, S8 CDefault Bold, Verdana
		Gui, Add, Button, Default x122 y330 w100 h30 gUpdate, &Update
		Gui, Font, Norm 
		Gui, Add, Button, x342 y330 w100 h30 gGuiReturn, Cancel
		Gui, Show, x483 y242 h379 w593, Macro Trainer Update
		Return				
	}
	Else
	{
		Gui, New
		Gui +Toolwindow +AlwaysOnTop	
		Gui, Add, Picture, x12 y10 w90 h90 , %A_ScriptName%
		Gui, Font, S10 CDefault, Verdana
		Gui, Add, Text, x112 y15  , You already have the latest version.
		Gui, Add, Text, xp yp+20  , Version:
		Gui, Font, S10 CDefault Bold, Verdana
		Gui, Add, Text, xp+60 yp  , %version%
		Gui, Font, Norm 
		Gui, Font, S8 CDefault Bold, Verdana
		Gui, Font, Norm 
		Gui, Add, Button, Default x160 yp+40  w100 h30 gGuiReturn, &OK
		Gui, Show, , Macro Trainer Update
		Return
	}
Update:
	; latestVersion is a global variable set by the checkforupdate()
	EXE_url := "http://www.users.on.net/~jb10/Macro Trainer V" latestVersion ".exe"
	save := "Macro Trainer V" latestVersion ".exe"
	If ( InternetFileRead( binData, EXE_url ) > 0 && !ErrorLevel )
	If VarZ_Save( binData, save ) 
	{
		Sleep 200
		DLP(1,1,"Download Complete") ; 1 file of 1 with message on complete
		MsgBox, 262145, Update, Download complete.`n`nClick Ok to run the latest version (Vr %latestVersion%)`nClick cancel to continue running this version.
		IfMsgBox Ok ;msgbox 1 = ok/cancel buttons
		{	
			FileCreateDir, %old_backup_DIR%
			FileMove, %A_ScriptName%, %old_backup_DIR%\%A_ScriptName%, 1 ;ie 1 = overwrite	
			Run %save%	
			ExitApp
		}
		Else	DLP( False ) ;removes the progress
		FileCopy, %A_ScriptName%, %old_backup_DIR%\%A_ScriptName%, 1
	}
	Return

	
;------------
;	Startup/Reading the ini file
;------------
pre_startup:
	
if FileExist(config_file) ; the file exists lets read the ini settings
{
	;[Version]
	IniRead, read_version, %config_file%, Version, version, 1 ; 1 if cant find value - IE early version
	;[Auto Inject]
	IniRead, auto_inject, %config_file%, Auto Inject, auto_inject_enable, 1
	IniRead, auto_inject_alert, %config_file%, Auto Inject, alert_enable, 1
	IniRead, auto_inject_time, %config_file%, Auto Inject, auto_inject_time, 41
	IniRead, cast_inject_key, %config_file%, Auto Inject, auto_inject_key, F5
	IniRead, Inject_control_group, %config_file%, Auto Inject, control_group, 9
	IniRead, Inject_spawn_larva, %config_file%, Auto Inject, spawn_larva, v
	
	; [MiniMap Inject]
	section := "MiniMap Inject"
	IniRead, MI_Queen_Group, %config_file%, %section%, MI_Queen_Group, 7
	IniRead, MI_QueenDistance, %config_file%, %section%, MI_QueenDistance, 17

		
	;[Manual Inject Timer]
	IniRead, manual_inject_timer, %config_file%, Manual Inject Timer, manual_timer_enable, 0
	IniRead, manual_inject_time, %config_file%, Manual Inject Timer, manual_inject_time, 43
	IniRead, inject_start_key, %config_file%, Manual Inject Timer, start_stop_key, Lwin & RButton
	IniRead, inject_reset_key, %config_file%, Manual Inject Timer, reset_key, Lwin & LButton
	
	;[Inject Warning]
	IniRead, W_inject_ding_on, %config_file%, Inject Warning, ding_on, 1
	IniRead, W_inject_speech_on, %config_file%, Inject Warning, speech_on, 0
	IniRead, w_inject_spoken, %config_file%, Inject Warning, w_inject, Inject
	
	;[Forced Inject]
	section := "Forced Inject"
	IniRead, F_Inject_Enable, %config_file%, %section%, F_Inject_Enable, 0
	IniRead, F_Inject_ModifierBeep, %config_file%, %section%, F_Inject_ModifierBeep, 1
	IniRead, F_Inject_Beep , %config_file%, %section%, F_Inject_Beep, 0
	IniRead, F_Alert_Enable, %config_file%, %section%, Alert_Enable, 1
	IniRead, F_Alert_PreTime, %config_file%, %section%, F_Alert_PreTime, 1
	IniRead, F_Inject_Delay, %config_file%, %section%, F_Inject_Delay, 15
	IniRead, F_Max_Injects, %config_file%, %section%, F_Max_Injects, 4
	IniRead, F_Sleep_Time, %config_file%, %section%, F_Sleep_Time, 5
	IniRead, F_InjectOff_Key, %config_file%, %section%, F_InjectOff_Key, Lwin & F5
	
	

	;[Idle AFK Game Pause]
	IniRead, idle_enable, %config_file%, Idle AFK Game Pause, enable, 0
	IniRead, idle_time, %config_file%, Idle AFK Game Pause, idle_time, 15
	IniRead, UserIdle_LoLimit, %config_file%, Idle AFK Game Pause, UserIdle_LoLimit, 3	;sc2 seconds
	IniRead, UserIdle_HiLimit, %config_file%, Idle AFK Game Pause, UserIdle_HiLimit, 10	
	IniRead, chat_text, %config_file%, Idle AFK Game Pause, chat_text, Sorry, please give me 2 minutes. Thanks :)


	;[Starcraft Settings & Keys]
	IniRead, name, %config_file%, Starcraft Settings & Keys, name, YourNameHere
	IniRead, pause_game, %config_file%, Starcraft Settings & Keys, pause_game, {Pause}
	IniRead, base_camera, %config_file%, Starcraft Settings & Keys, base_camera, {Backspace}
	IniRead, escape, %config_file%, Starcraft Settings & Keys, escape, {escape}
	
	;[Backspace Inject Keys]
	section := "Backspace Inject Keys"
	IniRead, BI_create_camera_pos_x, %config_file%, %section%, create_camera_pos_x, +{F6}	
	IniRead, BI_camera_pos_x, %config_file%, %section%, camera_pos_x, {F6}	


	;[Forgotten Gateway/Warpgate Warning]
	section := "Forgotten Gateway/Warpgate Warning"
	IniRead, warpgate_warn_on, %config_file%, %section%, enable, 1
	IniRead, sec_warpgate, %config_file%, %section%, warning_count, 1
	IniRead, delay_warpgate_warn, %config_file%, %section%, initial_time_delay, 10
	IniRead, delay_warpgate_warn_followup, %config_file%, %section%, follow_up_time_delay, 15
	IniRead, w_warpgate, %config_file%, %section%, spoken_warning, "WarpGate"

	;[Chrono Boost Gateway/Warpgate]
	section := "Chrono Boost Gateway/Warpgate"
	IniRead, CG_Enable, %config_file%, %section%, enable, 1
	IniRead, Cast_ChronoGate_Key, %config_file%, %section%, Cast_ChronoGate_Key, F5
	IniRead, CG_control_group, %config_file%, %section%, CG_control_group, 9
	IniRead, CG_Random_off, %config_file%, %section%, CG_Random_off, 1
	IniRead, CG_KeyDelay, %config_file%, %section%, CG_KeyDelay, 2
	
	IniRead, CG_nexus_Ctrlgroup_key, %config_file%, %section%, CG_nexus_Ctrlgroup_key, 4
	IniRead, chrono_key, %config_file%, %section%, chrono_key, c
	IniRead, CG_chrono_remainder, %config_file%, %section%, CG_chrono_remainder, 2
	IniRead, Chrono_Gate_Sleep, %config_file%, %section%, Chrono_Gate_Sleep, 50
	
	;[Advanced Auto Inject Settings]
	IniRead, auto_inject_sleep, %config_file%, Advanced Auto Inject Settings, auto_inject_sleep, 50
	IniRead, I_KeyDelay, %config_file%, Advanced Auto Inject Settings, KeyDelay, 2
	IniRead, drag_origin, %config_file%, Advanced Auto Inject Settings, drag_origin, Left

	;[Read Opponents Spawn-Races]
	IniRead, race_reading, %config_file%, Read Opponents Spawn-Races, enable, 1
	IniRead, Auto_Read_Races, %config_file%, Read Opponents Spawn-Races, Auto_Read_Races, 1
	IniRead, read_races_key, %config_file%, Read Opponents Spawn-Races, read_key, LWin & F1
	IniRead, race_speech, %config_file%, Read Opponents Spawn-Races, speech, 1
	IniRead, race_clipboard, %config_file%, Read Opponents Spawn-Races, copy_to_clipboard, 0

	;[Worker Production Helper]	
	IniRead, workeron, %config_file%, Worker Production Helper, warning_enable, 1
	IniRead, workerProductionTPIdle, %config_file%, Worker Production Helper, workerProductionTPIdle, 10
	IniRead, workerproduction_time, %config_file%, Worker Production Helper, production_time_lapse, 24
		workerproduction_time_if := workerproduction_time	;this allows to swap the 2nd warning time

	;[Minerals]
	IniRead, mineralon, %config_file%, Minerals, warning_enable, 1
	IniRead, mineraltrigger, %config_file%, Minerals, mineral_trigger, 1000

	;[Gas]
	IniRead, gas_on, %config_file%, Gas, warning_enable, 0
	IniRead, gas_trigger, %config_file%, Gas, gas_trigger, 600


	;[Idle Workers]
	IniRead, idleon, %config_file%, Idle Workers, warning_enable, 1
	IniRead, idletrigger, %config_file%, Idle Workers, idle_trigger, 5

	;[Supply]
	IniRead, supplyon, %config_file%, Supply, warning_enable, 1
	IniRead, minimum_supply, %config_file%, Supply, minimum_supply, 11
	IniRead, supplylower, %config_file%, Supply, supplylower, 40
	IniRead, supplymid, %config_file%, Supply, supplymid, 80
	IniRead, supplyupper, %config_file%, Supply, supplyupper, 120
	IniRead, sub_lowerdelta, %config_file%, Supply, sub_lowerdelta, 4
	IniRead, sub_middelta, %config_file%, Supply, sub_middelta, 5
	IniRead, sub_upperdelta, %config_file%, Supply, sub_upperdelta, 6
	IniRead, above_upperdelta, %config_file%, Supply, above_upperdelta, 8

	;[Additional Warning Count]-----set number of warnings to make
	IniRead, sec_supply, %config_file%, Additional Warning Count, supply, 1
	IniRead, sec_mineral, %config_file%, Additional Warning Count, minerals, 1
	IniRead, sec_gas, %config_file%, Additional Warning Count, gas, 0
	IniRead, sec_workerprod, %config_file%, Additional Warning Count, worker_production, 1
	IniRead, sec_idle, %config_file%, Additional Warning Count, idle_workers, 0
	
	;[Auto Control Group]
	Short_Race_List := "Terr|Prot|Zerg", section := "Auto Control Group", A_UnitGroupSettings := []
	Loop, Parse, l_Races, `, ;Terran ie full name
		while (10 > i := A_index - 1)	
			A_UnitGroupSettings["LimitGroup", A_LoopField, i, "Enabled"] := IniRead(config_file, section, A_LoopField "_LimitGroup_" i, 0)
	loop, parse, Short_Race_List, |
	{			
		A_UnitGroupSettings["AutoGroup", A_LoopField, "Enabled"] := IniRead(config_file, section, "AG_Enable_" A_LoopField , 0)
		loop, 10		;this reads the auto group and removes the final |/, 
		{				;and repalces all | with better looking ,
			String := RTrim(IniRead(config_file, section, "AG_" A_LoopField A_Index - 1 , A_Space), "`, |")
			StringReplace, String, String, |, `, %a_space%, All ;replace | with ,
			A_UnitGroupSettings[A_LoopField, A_Index - 1] := String			
		}
	}
	IniRead, AG_Delay, %config_file%, %section%, AG_Delay, 0

	
	;[ Volume]
	section := "Volume"
	IniRead, speech_volume, %config_file%, %section%, speech, 100
	IniRead, overall_program, %config_file%, %section%, program, 100
	IniRead, speaker_volume_up_key, %config_file%, %section%, +speaker_volume_key, Lwin & =
	IniRead, speaker_volume_down_key, %config_file%, %section%, -speaker_volume_key, Lwin & -
	IniRead, speech_volume_up_key, %config_file%, %section%, +speech_volume_key, Lwin & PgUp
	IniRead, speech_volume_down_key, %config_file%, %section%, -speech_volume_key, Lwin & PgDn
	IniRead, program_volume_up_key, %config_file%, %section%, +program_volume_key, Lwin & Up
	IniRead, program_volume_down_key, %config_file%, %section%, -program_volume_key, Lwin & Down
	; theres an iniwrite volume in the exit routine

	;[Warnings]-----sets the audio warning
	IniRead, w_supply, %config_file%, Warnings, supply, "Supply"
	IniRead, w_mineral, %config_file%, Warnings, minerals, "Money"
	IniRead, w_gas, %config_file%, Warnings, gas, "Gas"
	IniRead, w_workerprod_T, %config_file%, Warnings, worker_production_T, "Build SCV"
	IniRead, w_workerprod_P, %config_file%, Warnings, worker_production_P, "Build Probe"
	IniRead, w_workerprod_Z, %config_file%, Warnings, worker_production_Z, "Build Drone"
	IniRead, w_idle, %config_file%, Warnings, idle_workers, "Idle"

	;[Additional Warning Delay]
	IniRead, additional_delay_supply, %config_file%, Additional Warning Delay, supply, 10
	IniRead, additional_delay_minerals, %config_file%, Additional Warning Delay, minerals, 10
	IniRead, additional_delay_gas, %config_file%, Additional Warning Delay, gas, 10
	IniRead, additional_delay_worker_production, %config_file%, Additional Warning Delay, worker_production, 25 ;sc2time
	IniRead, additional_idle_workers, %config_file%, Additional Warning Delay, idle_workers, 10

	;[Stealth Mode]
	IniRead, HideTrayIcon, %config_file%, Stealth Mode, HideTrayIcon, 0
	IniRead, exit_hotkey, %config_file%, Stealth Mode, exit_hotkey, Lwin & Esc
	
	;[Misc Hotkey]
	IniRead, worker_count_local_key, %config_file%, Misc Hotkey, worker_count_key, F8
	IniRead, worker_count_enemy_key, %config_file%, Misc Hotkey, enemy_worker_count, Lwin & F8
	IniRead, warning_toggle_key, %config_file%, Misc Hotkey, pause_resume_warnings_key, Lwin & Pause
	IniRead, ping_key, %config_file%, Misc Hotkey, ping_map, Lwin & MButton

	;[Misc Settings]
	section := "Misc Settings"
	IniRead, input_method, %config_file%, %section%, input_method, Event
	IniRead, auto_update, %config_file%, %section%, auto_check_updates, 1
	IniRead, launch_settings, %config_file%, %section%, launch_settings, 0
	IniRead, MaxWindowOnStart, %config_file%, %section%, MaxWindowOnStart, 1
	IniRead, HumanMouse, %config_file%, %section%, HumanMouse, 0
	IniRead, HumanMouseTimeLo, %config_file%, %section%, HumanMouseTimeLo, 70
	IniRead, HumanMouseTimeHi, %config_file%, %section%, HumanMouseTimeHi, 110
	IniRead, ProcessSleep, %config_file%, %section%, ProcessSleep, 0
	IniRead, SetBatchLines, %config_file%, %section%, SetBatchLines, 10ms
		SetBatchLines, %SetBatchLines%
	IniRead, UnitDetectionTimer_ms, %config_file%, %section%, UnitDetectionTimer_ms, 3500
	

	;[Key Blocking]
	section := "Key Blocking"
	IniRead, BlockingStandard, %config_file%, %section%, BlockingStandard, 1
	IniRead, BlockingFunctional, %config_file%, %section%, BlockingFunctional, 1
	IniRead, BlockingNumpad, %config_file%, %section%, BlockingNumpad, 1
	IniRead, BlockingMouseKeys, %config_file%, %section%, BlockingMouseKeys, 1
	IniRead, BlockingMultimedia, %config_file%, %section%, BlockingMultimedia, 1
	IniRead, BlockingModifier, %config_file%, %section%, BlockingModifier, 1

	aButtons := []
	aButtons.List := getKeyboardAndMouseButtonArray(BlockingStandard*1 + BlockingFunctional*2 + BlockingNumpad*4
																	 + BlockingMouseKeys*8 + BlockingMultimedia*16 + BlockingModifier*32)	;gets an object contains keys
	;[Auto Mine]
	section := "Auto Mine"
	IniRead, auto_mine, %config_file%, %section%, enable, 0
	IniRead, Auto_Mine_Set_CtrlGroup, %config_file%, %section%, Auto_Mine_Set_CtrlGroup, 1
	IniRead, Auto_mineMakeWorker, %config_file%, %section%, Auto_mineMakeWorker, 1
	IniRead, AutoMineMethod, %config_file%, %section%, AutoMineMethod, Normal
	IniRead, WorkerSplitType, %config_file%, %section%, WorkerSplitType, 3x2
	IniRead, Auto_Mine_Sleep2, %config_file%, %section%, Auto_Mine_Sleep2, 100
	IniRead, AM_PixelColour, %config_file%, %section%, AM_PixelColour, 4286496753
	;this just stores the ARGB colours for the auto mine menu
	Gdip_FromARGB(AM_PixelColour, AM_MiniMap_PixelColourAlpha, AM_MiniMap_PixelColourRed, AM_MiniMap_PixelColourGreen, AM_MinsiMap_PixelColourBlue)
	IniRead, AM_MiniMap_PixelVariance, %config_file%, %section%, AM_MiniMap_PixelVariance, 0
	IniRead, Start_Mine_Time, %config_file%, %section%, Start_Mine_Time, 1
	IniRead, AM_KeyDelay, %config_file%, %section%, AM_KeyDelay, 2
	
	IniRead, Idle_Worker_Key, %config_file%, %section%, Idle_Worker_Key, {F1}
	IniRead, Gather_Minerals_key, %config_file%, %section%, Gather_Minerals_key, g
	IniRead, Base_Control_Group_Key, %config_file%, %section%, Base_Control_Group_Key, 4
	IniRead, Make_Worker_T_Key, %config_file%, %section%, Make_Worker_T_Key, s
	IniRead, Make_Worker_P_Key, %config_file%, %section%, Make_Worker_P_Key, e
	IniRead, Make_Worker_Z1_Key, %config_file%, %section%, Make_Worker_Z1_Key, s
	IniRead, Make_Worker_Z2_Key, %config_file%, %section%, Make_Worker_Z2_Key, d 
	
	;[Misc Automation]
	section := "Misc Automation"
	IniRead, SelectArmyEnable, %config_file%, %section%, SelectArmyEnable, 0	;enable disable
	IniRead, Sc2SelectArmy_Key, %config_file%, %section%, Sc2SelectArmy_Key, {F2}
	IniRead, castSelectArmy_key, %config_file%, %section%, castSelectArmy_key, F2
	IniRead, SleepSelectArmy, %config_file%, %section%, SleepSelectArmy, 15
	IniRead, ModifierBeepSelectArmy, %config_file%, %section%, ModifierBeepSelectArmy, 1
	IniRead, SelectArmyDeselectXelnaga, %config_file%, %section%, SelectArmyDeselectXelnaga, 1
	IniRead, SelectArmyDeselectPatrolling, %config_file%, %section%, SelectArmyDeselectPatrolling, 1
	IniRead, SelectArmyDeselectHoldPosition, %config_file%, %section%, SelectArmyDeselectHoldPosition, 0
	IniRead, SelectArmyDeselectFollowing, %config_file%, %section%, SelectArmyDeselectFollowing, 0
	IniRead, SelectArmyControlGroupEnable, %config_file%, %section%, SelectArmyControlGroupEnable, 0
	IniRead, Sc2SelectArmyCtrlGroup, %config_file%, %section%, Sc2SelectArmyCtrlGroup, 1	
	IniRead, SplitUnitsEnable, %config_file%, %section%, SplitUnitsEnable, 0
	IniRead, castSplitUnit_key, %config_file%, %section%, castSplitUnit_key, F4
	IniRead, SplitctrlgroupStorage_key, %config_file%, %section%, SplitctrlgroupStorage_key, 9
	IniRead, SleepSplitUnits, %config_file%, %section%, SleepSplitUnits, 20
	IniRead, l_DeselectArmy, %config_file%, %section%, l_DeselectArmy, %A_Space%
	IniRead, DeselectSleepTime, %config_file%, %section%, DeselectSleepTime, 0

	;[Alert Location]
	IniRead, Playback_Alert_Key, %config_file%, Alert Location, Playback_Alert_Key, <#F7
	
	Gosub, iniread_alert_list
	
	;[Overlays]
	section := "Overlays"
	list := "IncomeOverlay,ResourcesOverlay,ArmySizeOverlay,WorkerOverlay,IdleWorkersOverlay,UnitOverlay"
	loop, parse, list, `,
	{
		IniRead, Draw%A_LoopField%, %config_file%, %section%, Draw%A_LoopField%, 0
		IniRead, %A_LoopField%Scale, %config_file%, %section%, %A_LoopField%Scale, 1
		if (%A_LoopField%Scale < .5)	;so cant get -scales
			%A_LoopField%Scale := .5
		IniRead, %A_LoopField%X, %config_file%, %section%, %A_LoopField%X, % 200 * A_index	
		if (%A_LoopField%X = "" || < 0) ; guard against blank key
			%A_LoopField%X := 200 * (A_Index/2)
		Else if (%A_LoopField%X > A_ScreenWidth)
			%A_LoopField%X := A_ScreenWidth/2
		IniRead, %A_LoopField%Y, %config_file%, %section%, %A_LoopField%Y, % 200 * A_index	
		if (%A_LoopField%Y = "" || < 0)
			%A_LoopField%Y := 200 * (A_Index/2)
		Else if (%A_LoopField%Y > A_ScreenHeight)
			%A_LoopField%Y := A_ScreenHeight/2
	}


;	IniRead, DrawWorkerOverlay, %config_file%, %section%, DrawWorkerOverlay, 1
;	IniRead, DrawIdleWorkersOverlay, %config_file%, %section%, DrawIdleWorkersOverlay, 1

	IniRead, ToggleUnitOverlayKey, %config_file%, %section%, ToggleUnitOverlayKey, <#U
	IniRead, ToggleIdleWorkersOverlayKey, %config_file%, %section%, ToggleIdleWorkersOverlayKey, <#L
	IniRead, ToggleIncomeOverlayKey, %config_file%, %section%, ToggleIncomeOverlayKey, <#I
	IniRead, ToggleResourcesOverlayKey, %config_file%, %section%, ToggleResourcesOverlayKey, <#R
	IniRead, ToggleArmySizeOverlayKey, %config_file%, %section%, ToggleArmySizeOverlayKey, <#A
	IniRead, ToggleWorkerOverlayKey, %config_file%, %section%, ToggleWorkerOverlayKey, <#W	
	IniRead, AdjustOverlayKey, %config_file%, %section%, AdjustOverlayKey, Home
	IniRead, ToggleIdentifierKey, %config_file%, %section%, ToggleIdentifierKey, <#q
	IniRead, CycleOverlayKey, %config_file%, %section%, CycleOverlayKey, <#Enter
	IniRead, OverlayIdent, %config_file%, %section%, OverlayIdent, 2
	IniRead, OverlayBackgrounds, %config_file%, %section%, OverlayBackgrounds, 0
	IniRead, MiniMapRefresh, %config_file%, %section%, MiniMapRefresh, 300
	IniRead, OverlayRefresh, %config_file%, %section%, OverlayRefresh, 1000
	IniRead, UnitOverlayRefresh, %config_file%, %section%, UnitOverlayRefresh, 4500

	
	;[MiniMap]
	section := "MiniMap" 	
	IniRead, UnitHighlightList1, %config_file%, %section%, UnitHighlightList1, SporeCrawler, SporeCrawlerUprooted, MissileTurret, PhotonCannon, Observer	;the list
	IniRead, UnitHighlightList2, %config_file%, %section%, UnitHighlightList2, DarkTemplar, Changeling, ChangelingZealot, ChangelingMarineShield, ChangelingMarine, ChangelingZerglingWings, ChangelingZergling
	IniRead, UnitHighlightList3, %config_file%, %section%, UnitHighlightList3, %A_Space%
	IniRead, UnitHighlightList1Colour, %config_file%, %section%, UnitHighlightList1Colour, 0xFFFFFFFF  ;the colour
	IniRead, UnitHighlightList2Colour, %config_file%, %section%, UnitHighlightList2Colour, 0xFFFF00FF 
	IniRead, UnitHighlightList3Colour, %config_file%, %section%, UnitHighlightList3Colour, 0xFF09C7CA 
	IniRead, UnitHighlightExcludeList, %config_file%, %section%, UnitHighlightExcludeList, CreepTumor, CreepTumorBurrowed
	IniRead, DrawMiniMap, %config_file%, %section%, DrawMiniMap, 1
	IniRead, TempHideMiniMapKey, %config_file%, %section%, TempHideMiniMapKey, !Space
	IniRead, DrawSpawningRaces, %config_file%, %section%, DrawSpawningRaces, 1
	IniRead, DrawAlerts, %config_file%, %section%, DrawAlerts, 1
	IniRead, BlendUnits, %config_file%, %section%, BlendUnits, 1
	
	;[Hidden Options]
	section := "Hidden Options"
	IniRead, AutoGroupTimer, %config_file%, %section%, AutoGroupTimer, 30
	
	
	; Resume Warnings
	Iniread, ResumeWarnings, %config_file%, Resume Warnings, Resume, 0
		
	if ( version > read_version ) ; its an update and the file exists - better backup the users settings
	{
		FileCreateDir, %old_backup_DIR%
		FileCopy, %config_file%, %old_backup_DIR%\v%read_version%_%config_file%, 1 ;ie 1 = overwrite
		Filemove, Macro Trainer V%read_version%.exe, %old_backup_DIR%\Macro Trainer V%read_version%.exe, 1 ;ie 1 = overwrite		
		FileInstall, MT_Config.ini, %config_file%, 1 ; 1 overwrites
		Gosub, ini_settings_write ;to write back users old settings
		Gosub, pre_startup ; Read the ini settings again - this updates the 'read version' and also helps with Control group 'ERROR' variable 
		;IniRead, read_version, %config_file%, Version, version, 1	;this is a safety net - and used to prevent keeping user alert lists in update pre 2.6 & Auto control group 'ERROR'
		;msgbox It seems that this is the first time that you have ran this version.`n`nYour old %config_file% & Macro Trainer have been backed up to `"\%old_backup_DIR%`". A new config file has been installed which contains your previous personalised settings`n`nPress OK to continue.
		Pressed := CMsgbox( "Macro Trainer Vr" version , "It seems that this is the first time that you have ran this version.`n`nYour old " config_file " and Macro Trainer have been backed up to '\" old_backup_DIR "'.`nA new config file has been installed which contains your previous personalised settings`n`nPress Launch to run SC2 and pwn noobs.`n`nOtherwise press Options to open the options menu.", "*Launch|&Options", 560, 160, 45, A_ScriptName, 110, 0, 12)
		If ( Pressed = "Options")
			gosub options_menu
	}		
}
Else If A_IsCompiled  ; config file doesn't exist
{
	FileInstall, MT_Config.ini, %config_file%, 0 ; includes and install the ini to the working directory - 0 prevents file being overwritten
	CMsgbox( "Macro Trainer Vr" version ,"This appears to be the first time you have run this program.`n`nPlease take a moment to read the help file and edit the settings in the options menu as you see fit.`n`n", "*OK", 500, 130, 10, A_ScriptName, 110)
	Gosub pre_startup
	gosub options_menu
}
Return	; to the startup procedure
	

;------------
;	Backing up the users ini settings
;------------
ini_settings_write:
	; Iniwrites
	Tmp_GuiControl := A_GuiControl ; store this result otherwise it will be empty when it gets to the bottom
	if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply") ;I come from the save menu options Not an update and writing back user settings
	{
		Try 
		{
			Try Hotkey,	%exit_hotkey%, off

			Hotkey, If, WinActive(GameIdentifier) 						
														; 	deactivate the hotkeys
			hotkey, %speaker_volume_up_key%, off		; 	so they can be updated with their new keys
			hotkey, %speaker_volume_down_key%, off		;	
			hotkey, %speech_volume_up_key%, off			; 
			hotkey, %speech_volume_down_key%, off		; Anything with a try command has an 'if setting is on' section in the
			hotkey, %program_volume_up_key%, off		; create hotkeys section
			hotkey, %program_volume_down_key%, off		; still left the overall try just incase i missed something
			hotkey, %warning_toggle_key%, off			; gives the user a friendlier error
		
			Hotkey, If, WinActive(GameIdentifier) && time	
			hotkey, %worker_count_local_key%, off
			hotkey, %worker_count_enemy_key%, off
			hotkey, %Playback_Alert_Key%, off
			hotkey, %TempHideMiniMapKey%, off
			hotkey, %AdjustOverlayKey%, off
			hotkey, %ToggleIdentifierKey%, off
			hotkey, %ToggleIncomeOverlayKey%, off
			hotkey, %ToggleResourcesOverlayKey%, off
			hotkey, %ToggleArmySizeOverlayKey%, off			
			hotkey, %ToggleWorkerOverlayKey%, off			
			hotkey, %CycleOverlayKey%, off		
		Try	hotkey, %read_races_key%, off
		try	hotkey, %inject_start_key%, off
		try	hotkey, %inject_reset_key%, off	

			Hotkey, If, WinActive(GameIdentifier) && time && !isMenuOpen() && SelectArmyEnable
			hotkey, %castSelectArmy_key%, off
			Hotkey, If, WinActive(GameIdentifier) && time && !isMenuOpen() && SplitUnitsEnable
			hotkey, %castSplitUnit_key%, off
			Hotkey, If, WinActive(GameIdentifier) && (a_LocalPlayer["Race"] = "Zerg") && (auto_inject <> "Disabled") && time
			hotkey, %cast_inject_key%, off
			hotkey, %F_InjectOff_Key%, Cast_DisableInject, on	
			Hotkey, If, WinActive(GameIdentifier) && (a_LocalPlayer["Race"] = "Protoss") && CG_Enable && time
			hotkey, %Cast_ChronoGate_Key%, off
			Hotkey, If, WinActive(GameIdentifier) && !isMenuOpen() && time
			Hotkey, %ping_key%, off		
			while (10 > i := A_index - 1)
			{
				try hotkey, ^%i%, off
				try hotkey, +%i%, off
				try hotkey, ^+%i%, off
			}			
			Hotkey, If	
		}
		Catch, Error	;error is an object
		{
			clipboard := "Error: " error.message "`nLine: " error.line "`nExtra: "error.Extra
			msgbox % "There was an error while updating the hotkey state.`nYour previous hotkeys may still be active until you restart.`nPlease report this error (it has been copied to the clipboard).`n`nError: " error.message "`nLine: " error.line "`nSpecifically: " error.Extra
		}
		IF (Tmp_GuiControl = "save")
		{
			Gui, Submit
			Gui, Destroy
		}
		Else Gui, Submit, NoHide
	}
	
	;[Auto Inject]
	IniWrite, %auto_inject%, %config_file%, Auto Inject, auto_inject_enable
	IniWrite, %auto_inject_alert%, %config_file%, Auto Inject, alert_enable
	IniWrite, %auto_inject_time%, %config_file%, Auto Inject, auto_inject_time
	IniWrite, %cast_inject_key%, %config_file%, Auto Inject, auto_inject_key
	IniWrite, %Inject_control_group%, %config_file%, Auto Inject, control_group
	IniWrite, %Inject_spawn_larva%, %config_file%, Auto Inject, spawn_larva

	;[Manual Inject Timer]
	IniWrite, %manual_inject_timer%, %config_file%, Manual Inject Timer, manual_timer_enable
	IniWrite, %manual_inject_time%, %config_file%, Manual Inject Timer, manual_inject_time
	IniWrite, %inject_start_key%, %config_file%, Manual Inject Timer, start_stop_key
	IniWrite, %inject_reset_key%, %config_file%, Manual Inject Timer, reset_key
	
	;[Inject Warning]
	IniWrite, %W_inject_ding_on%, %config_file%, Inject Warning, ding_on
	IniWrite, %W_inject_speech_on%, %config_file%, Inject Warning, speech_on
	IniWrite, %w_inject_spoken%, %config_file%, Inject Warning, w_inject	
	
		;[Forced Inject]
	section := "Forced Inject"
	IniWrite, %F_Inject_Enable%, %config_file%, %section%, F_Inject_Enable
	IniWrite, %F_Inject_ModifierBeep%, %config_file%, %section%, F_Inject_ModifierBeep
	IniWrite, %F_Inject_Beep%, %config_file%, %section%, F_Inject_Beep 
	IniWrite, %F_Alert_Enable%, %config_file%, %section%, Alert_Enable
	IniWrite, %F_Alert_PreTime%, %config_file%, %section%, F_Alert_PreTime
	IniWrite, %F_Inject_Delay%, %config_file%, %section%, F_Inject_Delay
	IniWrite, %F_Max_Injects%, %config_file%, %section%, F_Max_Injects
	IniWrite, %F_Sleep_Time%, %config_file%, %section%, F_Sleep_Time
	IniWrite, %F_InjectOff_Key%, %config_file%, %section%, F_InjectOff_Key

	;[Idle AFK Game Pause]
	IniWrite, %idle_enable%, %config_file%, Idle AFK Game Pause, enable
	IniWrite, %idle_time%, %config_file%, Idle AFK Game Pause, idle_time
	IniWrite, %UserIdle_LoLimit%, %config_file%, Idle AFK Game Pause, UserIdle_LoLimit
	if (UserIdle_HiLimit < UserIdle_LoLimit)
		UserIdle_HiLimit := UserIdle_LoLimit + 5
	IniWrite, %UserIdle_HiLimit%, %config_file%, Idle AFK Game Pause, UserIdle_HiLimit
	IniWrite, %chat_text%, %config_file%, Idle AFK Game Pause, chat_text


	;[Starcraft Settings & Keys]
	IniWrite, %pause_game%, %config_file%, Starcraft Settings & Keys, pause_game
	IniWrite, %base_camera%, %config_file%, Starcraft Settings & Keys, base_camera
	IniWrite, %escape%, %config_file%, Starcraft Settings & Keys, {escape}
	
	; [MiniMap Inject]
	section := "MiniMap Inject"
	IniWrite, %MI_Queen_Group%, %config_file%, %section%, MI_Queen_Group
	IniWrite, %MI_QueenDistance%, %config_file%, %section%, MI_QueenDistance
	
	;[Backspace Inject Keys]
	section := "Backspace Inject Keys"
	IniWrite, %BI_create_camera_pos_x%, %config_file%, %section%, create_camera_pos_x
	IniWrite, %BI_camera_pos_x%, %config_file%, %section%, camera_pos_x
	
	;[Forgotten Gateway/Warpgate Warning]
	section := "Forgotten Gateway/Warpgate Warning"
	IniWrite, %warpgate_warn_on%, %config_file%, %section%, enable
	IniWrite, %sec_warpgate%, %config_file%, %section%, warning_count
	IniWrite, %delay_warpgate_warn%, %config_file%, %section%, initial_time_delay
	IniWrite, %delay_warpgate_warn_followup%, %config_file%, %section%, follow_up_time_delay
	IniWrite, %w_warpgate%, %config_file%, %section%, spoken_warning

	
	;[Chrono Boost Gateway/Warpgate]
	section := "Chrono Boost Gateway/Warpgate"
	IniWrite, %CG_Enable%, %config_file%, %section%, enable
	IniWrite, %Cast_ChronoGate_Key%, %config_file%, %section%, Cast_ChronoGate_Key
	IniWrite, %CG_control_group%, %config_file%, %section%, CG_control_group
	IniWrite, %CG_Random_off%, %config_file%, %section%, CG_Random_off
	IniWrite, %CG_KeyDelay%, %config_file%, %section%, CG_KeyDelay
	IniWrite, %CG_nexus_Ctrlgroup_key%, %config_file%, %section%, CG_nexus_Ctrlgroup_key
	IniWrite, %chrono_key%, %config_file%, %section%, chrono_key
	IniWrite, %CG_chrono_remainder%, %config_file%, %section%, CG_chrono_remainder
	IniWrite, %Chrono_Gate_Sleep%, %config_file%, %section%, Chrono_Gate_Sleep
	
	;[Auto Control Group]
	Short_Race_List := "Terr|Prot|Zerg"
	section := "Auto Control Group"		
	Loop, Parse, l_Races, `, ;Terran ie full name
		while (10 > i := A_index - 1)
		{
			if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply") ; this ensure wont blank the field when version updates
				A_UnitGroupSettings["LimitGroup", A_LoopField, i, "Enabled"] := LG_%A_LoopField%%i%
			IniWrite, % A_UnitGroupSettings["LimitGroup", A_LoopField, i,"Enabled"], %config_file%, %section%, %A_LoopField%_LimitGroup_%i%
		}		
	loop, parse, Short_Race_List, |
	{	
		i := 0
		if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply")
			A_UnitGroupSettings["AutoGroup", A_LoopField, "Enabled"] := AG_Enable_%A_LoopField%
		IniWrite, % A_UnitGroupSettings["AutoGroup", A_LoopField, "Enabled"], %config_file%, %section%, AG_Enable_%A_LoopField%		
		loop, 10
		{	if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply")			
				A_UnitGroupSettings[A_LoopField, i] := AG_%A_LoopField%%i%
			IniWrite, % A_UnitGroupSettings[A_LoopField, i], %config_file%, %section%, AG_%A_LoopField%%i%
			i++
		}
	}
	IniWrite, %AG_Delay%, %config_file%, %section%, AG_Delay

	;[Advanced Auto Inject Settings]
	IniWrite, %auto_inject_sleep%, %config_file%, Advanced Auto Inject Settings, auto_inject_sleep
	IniWrite, %I_KeyDelay%, %config_file%, Advanced Auto Inject Settings, KeyDelay
	IniWrite, %drag_origin%, %config_file%, Advanced Auto Inject Settings, drag_origin

	;[Read Opponents Spawn-Races]
	IniWrite, %race_reading%, %config_file%, Read Opponents Spawn-Races, enable
	IniWrite, %Auto_Read_Races%, %config_file%, Read Opponents Spawn-Races, Auto_Read_Races
	IniWrite, %read_races_key%, %config_file%, Read Opponents Spawn-Races, read_key
	IniWrite, %race_speech%, %config_file%, Read Opponents Spawn-Races, speech
	IniWrite, %race_clipboard%, %config_file%, Read Opponents Spawn-Races, copy_to_clipboard

	;[Worker Production Helper]	
	IniWrite, %workeron%, %config_file%, Worker Production Helper, warning_enable
	IniWrite, %workerproduction_time%, %config_file%, Worker Production Helper, production_time_lapse
	IniWrite, %workerProductionTPIdle%, %config_file%, Worker Production Helper, workerProductionTPIdle

	;[Minerals]
	IniWrite, %mineralon%, %config_file%, Minerals, warning_enable
	IniWrite, %mineraltrigger%, %config_file%, Minerals, mineral_trigger

	;[Gas]
	IniWrite, %gas_on%, %config_file%, Gas, warning_enable
	IniWrite, %gas_trigger%, %config_file%, Gas, gas_trigger


	;[Idle Workers]
	IniWrite, %idleon%, %config_file%, Idle Workers, warning_enable
	IniWrite, %idletrigger%, %config_file%, Idle Workers, idle_trigger

	;[Supply]
	IniWrite, %supplyon%, %config_file%, Supply, warning_enable
	IniWrite, %minimum_supply%, %config_file%, Supply, minimum_supply
	IniWrite, %supplylower%, %config_file%, Supply, supplylower
	IniWrite, %supplymid%, %config_file%, Supply, supplymid
	IniWrite, %supplyupper%, %config_file%, Supply, supplyupper
	IniWrite, %sub_lowerdelta%, %config_file%, Supply, sub_lowerdelta
	IniWrite, %sub_middelta%, %config_file%, Supply, sub_middelta
	IniWrite, %sub_upperdelta%, %config_file%, Supply, sub_upperdelta
	IniWrite, %above_upperdelta%, %config_file%, Supply, above_upperdelta

	;[Additional Warning Count]-----set number of warnings to make
	IniWrite, %sec_supply%, %config_file%, Additional Warning Count, supply
	IniWrite, %sec_mineral%, %config_file%, Additional Warning Count, minerals
	IniWrite, %sec_gas%, %config_file%, Additional Warning Count, gas
	IniWrite, %sec_workerprod%, %config_file%, Additional Warning Count, worker_production
	IniWrite, %sec_idle%, %config_file%, Additional Warning Count, idle_workers

	;[ Volume]
	section := "Volume"
	IniWrite, %speech_volume%, %config_file%, %section%, speech
	IniWrite, %overall_program%, %config_file%, %section%, program
	IniWrite, %speaker_volume_up_key%, %config_file%, %section%, +speaker_volume_key
	IniWrite, %speaker_volume_down_key%, %config_file%, %section%, -speaker_volume_key
	IniWrite, %speech_volume_up_key%, %config_file%, %section%, +speech_volume_key
	IniWrite, %speech_volume_down_key%, %config_file%, %section%, -speech_volume_key
	IniWrite, %program_volume_up_key%, %config_file%, %section%, +program_volume_key
	IniWrite, %program_volume_down_key%, %config_file%, %section%, -program_volume_key
	; theres an iniwrite volume in the exit routine

	;[Warnings]-----sets the audio warning
	IniWrite, %w_supply%, %config_file%, Warnings, supply
	IniWrite, %w_mineral%, %config_file%, Warnings, minerals
	IniWrite, %w_gas%, %config_file%, Warnings, gas
	IniWrite, %w_workerprod_T%, %config_file%, Warnings, worker_production_T
	IniWrite, %w_workerprod_P%, %config_file%, Warnings, worker_production_P
	IniWrite, %w_workerprod_Z%, %config_file%, Warnings, worker_production_Z
	IniWrite, %w_idle%, %config_file%, Warnings, idle_workers

	;[Additional Warning Delay]
	IniWrite, %additional_delay_supply%, %config_file%, Additional Warning Delay, supply
	IniWrite, %additional_delay_minerals%, %config_file%, Additional Warning Delay, minerals
	IniWrite, %additional_delay_gas%, %config_file%, Additional Warning Delay, gas
	IniWrite, %additional_delay_worker_production%, %config_file%, Additional Warning Delay, worker_production ;sc2time
	IniWrite, %additional_idle_workers%, %config_file%, Additional Warning Delay, idle_workers

	;[Stealth Mode]
	IniWrite, %HideTrayIcon%, %config_file%, Stealth Mode, HideTrayIcon
	IniWrite, %exit_hotkey%, %config_file%, Stealth Mode, exit_hotkey
	
		;[Auto Mine]
	section := "Auto Mine"
	IniWrite, %auto_mine%, %config_file%, %section%, enable
	IniWrite, %Auto_Mine_Set_CtrlGroup%, %config_file%, %section%, Auto_Mine_Set_CtrlGroup
	IniWrite, %Auto_mineMakeWorker%, %config_file%, %section%, Auto_mineMakeWorker
	IniWrite, %AutoMineMethod%, %config_file%, %section%, AutoMineMethod
	IniWrite, %WorkerSplitType%, %config_file%, %section%, WorkerSplitType
	IniWrite, %Auto_Mine_Sleep2%, %config_file%, %section%, Auto_Mine_Sleep2
	if (Tmp_GuiControl = "save" OR Tmp_GuiControl = "Apply") ;lets calculate the (possibly) new colour
		AM_PixelColour := Gdip_ToARGB(AM_MiniMap_PixelColourAlpha, AM_MiniMap_PixelColourRed, AM_MiniMap_PixelColourGreen, AM_MinsiMap_PixelColourBlue)
	IniWrite, %AM_PixelColour%, %config_file%, %section%, AM_PixelColour
	IniWrite, %AM_MiniMap_PixelVariance%, %config_file%, %section%, AM_MiniMap_PixelVariance
	IniWrite, %Start_Mine_Time%, %config_file%, %section%, Start_Mine_Time
	IniWrite, %Idle_Worker_Key%, %config_file%, %section%, Idle_Worker_Key
	IniWrite, %AM_KeyDelay%, %config_file%, %section%, AM_KeyDelay
	IniWrite, %Gather_Minerals_key%, %config_file%, %section%, Gather_Minerals_key
	IniWrite, %Base_Control_Group_Key%, %config_file%, %section%, Base_Control_Group_Key
	IniWrite, %Make_Worker_T_Key%, %config_file%, %section%, Make_Worker_T_Key
	IniWrite, %Make_Worker_P_Key%, %config_file%, %section%, Make_Worker_P_Key
	IniWrite, %Make_Worker_Z1_Key%, %config_file%, %section%, Make_Worker_Z1_Key
	IniWrite, %Make_Worker_Z2_Key%, %config_file%, %section%, Make_Worker_Z2_Key
	
	;[Misc Automation]
	section := "Misc Automation"
	IniWrite, %SelectArmyEnable%, %config_file%, %section%, SelectArmyEnable
	IniWrite, %Sc2SelectArmy_Key%, %config_file%, %section%, Sc2SelectArmy_Key
	IniWrite, %castSelectArmy_key%, %config_file%, %section%, castSelectArmy_key
	IniWrite, %SleepSelectArmy%, %config_file%, %section%, SleepSelectArmy
	IniWrite, %ModifierBeepSelectArmy%, %config_file%, %section%, ModifierBeepSelectArmy
	IniWrite, %SelectArmyDeselectXelnaga%, %config_file%, %section%, SelectArmyDeselectXelnaga
	IniWrite, %SelectArmyDeselectPatrolling%, %config_file%, %section%, SelectArmyDeselectPatrolling
	IniWrite, %SelectArmyDeselectHoldPosition%, %config_file%, %section%, SelectArmyDeselectHoldPosition
	IniWrite, %SelectArmyDeselectFollowing%, %config_file%, %section%, SelectArmyDeselectFollowing
	
	IniWrite, %SelectArmyControlGroupEnable%, %config_file%, %section%, SelectArmyControlGroupEnable
	IniWrite, %Sc2SelectArmyCtrlGroup%, %config_file%, %section%, Sc2SelectArmyCtrlGroup
	IniWrite, %SplitUnitsEnable%, %config_file%, %section%, SplitUnitsEnable
	IniWrite, %castSplitUnit_key%, %config_file%, %section%, castSplitUnit_key
	IniWrite, %SplitctrlgroupStorage_key%, %config_file%, %section%, SplitctrlgroupStorage_key
	IniWrite, %SleepSplitUnits%, %config_file%, %section%, SleepSplitUnits
	IniWrite, %l_DeselectArmy%, %config_file%, %section%, l_DeselectArmy
	IniWrite, %DeselectSleepTime%, %config_file%, %section%, DeselectSleepTime
		
	;[Misc Hotkey]
	IniWrite, %worker_count_local_key%, %config_file%, Misc Hotkey, worker_count_key
	IniWrite, %worker_count_enemy_key%, %config_file%, Misc Hotkey, enemy_worker_count
	IniWrite, %warning_toggle_key%, %config_file%, Misc Hotkey, pause_resume_warnings_key
	IniWrite, %ping_key%, %config_file%, Misc Hotkey, ping_map

	;[Misc Settings]
	section := "Misc Settings"
	IniWrite, %input_method%, %config_file%, %section%, input_method
	IniWrite, %auto_update%, %config_file%, %section%, auto_check_updates
	Iniwrite, %launch_settings%, %config_file%, %section%, launch_settings
	Iniwrite, %MaxWindowOnStart%, %config_file%, %section%, MaxWindowOnStart
	Iniwrite, %HumanMouse%, %config_file%, %section%, HumanMouse
	Iniwrite, %HumanMouseTimeLo%, %config_file%, %section%, HumanMouseTimeLo
	Iniwrite, %HumanMouseTimeHi%, %config_file%, %section%, HumanMouseTimeHi
	Iniwrite, %SetBatchLines%, %config_file%, %section%, SetBatchLines
	Iniwrite, %ProcessSleep%, %config_file%, %section%, ProcessSleep
	Iniwrite, %UnitDetectionTimer_ms%, %config_file%, %section%, UnitDetectionTimer_ms

	;[Key Blocking]
	section := "Key Blocking"
	IniWrite, %BlockingStandard%, %config_file%, %section%, BlockingStandard
	IniWrite, %BlockingFunctional%, %config_file%, %section%, BlockingFunctional
	IniWrite, %BlockingNumpad%, %config_file%, %section%, BlockingNumpad
	IniWrite, %BlockingMouseKeys%, %config_file%, %section%, BlockingMouseKeys
	IniWrite, %BlockingMultimedia%, %config_file%, %section%, BlockingMultimedia
	IniWrite, %BlockingModifier%, %config_file%, %section%, BlockingModifier
	
	;[Alert Location]
	IniWrite, %Playback_Alert_Key%, %config_file%, Alert Location, Playback_Alert_Key

	;[Overlays]
	section := "Overlays"
	list := "IncomeOverlay,ResourcesOverlay,ArmySizeOverlay,WorkerOverlay,IdleWorkersOverlay,UnitOverlay"
	loop, parse, list, `,
	{
		drawname := "Draw" A_LoopField,	drawvar := %drawname%
		scalename := A_LoopField "Scale", scalevar := %scalename%
		Togglename := "Toggle" A_LoopField "Key", Togglevar := %Togglename%
		IniWrite, %drawvar%, %config_file%, %section%, %drawname%
		Iniwrite, %scalevar%, %config_file%, %section%, %scalename%	
		Iniwrite, %Togglevar%, %config_file%, %section%, %Togglename% 	
	}
	Iniwrite, %AdjustOverlayKey%, %config_file%, %section%, AdjustOverlayKey	
	Iniwrite, %ToggleIdentifierKey%, %config_file%, %section%, ToggleIdentifierKey	
	Iniwrite, %CycleOverlayKey%, %config_file%, %section%, CycleOverlayKey	
		If (OverlayIdent = "Hidden")	
			OverlayIdent := 0
		Else If (OverlayIdent = "Name (White)")	
			OverlayIdent := 1				
		Else If (OverlayIdent = "Name (Coloured)")	
			OverlayIdent := 2		
		Else If (OverlayIdent = "Coloured Race Icon")	
			OverlayIdent := 3
		Else if OverlayIdent NOT in 0,1,2,3
			OverlayIdent := 3	
	Iniwrite, %OverlayIdent%, %config_file%, %section%, OverlayIdent	
	Iniwrite, %OverlayBackgrounds%, %config_file%, %section%, OverlayBackgrounds	
	Iniwrite, %MiniMapRefresh%, %config_file%, %section%, MiniMapRefresh	
	Iniwrite, %OverlayRefresh%, %config_file%, %section%, OverlayRefresh	
	Iniwrite, %UnitOverlayRefresh%, %config_file%, %section%, UnitOverlayRefresh

	
	;[MiniMap]
	section := "MiniMap" 
	IniWrite, %UnitHighlightList1%, %config_file%, %section%, UnitHighlightList1	;the list
	IniWrite, %UnitHighlightList2%, %config_file%, %section%, UnitHighlightList2
	IniWrite, %UnitHighlightList3%, %config_file%, %section%, UnitHighlightList3
	IniWrite, %UnitHighlightList1Colour%, %config_file%, %section%, UnitHighlightList1Colour ;the colour
	IniWrite, %UnitHighlightList2Colour%, %config_file%, %section%, UnitHighlightList2Colour
	IniWrite, %UnitHighlightList3Colour%, %config_file%, %section%, UnitHighlightList3Colour
	IniWrite, %UnitHighlightExcludeList%, %config_file%, %section%, UnitHighlightExcludeList
	IniWrite, %DrawMiniMap%, %config_file%, %section%, DrawMiniMap
	IniWrite, %TempHideMiniMapKey%, %config_file%, %section%, TempHideMiniMapKey
	IniWrite, %DrawSpawningRaces%, %config_file%, %section%, DrawSpawningRaces
	IniWrite, %DrawAlerts%, %config_file%, %section%, DrawAlerts
	Iniwrite, %BlendUnits%, %config_file%, %section%, BlendUnits

	;this writes back the unit detection lists and settings
	if (read_version >= 2.943)		;This is due to wol 2.04 changing ID codes - Easier just to start fresh
	{
		loop, parse, l_GameType, `,
		{
			alert_array[A_LoopField, "Enabled"] := BAS_on_%A_LoopField%
			alert_array[A_LoopField, "Clipboard"] := BAS_copy2clipboard_%A_LoopField%
		}
		Gosub, Alert_Array_General_Write
	}

	IF (Tmp_GuiControl = "save" or Tmp_GuiControl = "Apply")
	{
		Tmp_GuiControl := ""
		CreateHotkeys()	; to reactivate the hotkeys
		UserSavedAppliedSettings := 1
		if time && alert_array[GameType, "Enabled"]
			WriteOutWarningArrays()
		If (game_status = "game") ; so if they change settings during match will update timers
			UpdateTimers := 1
		
	}
Return



options_menu:
IfWinExist, Macro Trainer V%version% Settings
{
	WinActivate
	Return 									; prevent error due to reloading gui 
}
Gui, Options:New
gui, font, norm s9	;here so if windows user has +/- font size this standardises it. But need to do other menus one day
;Gui, +ToolWindow  +E0x40000 ; E0x40000 gives it a icon on taskbar
options_menu := "home32.png|radarB32.png|map32.png|Inject32.png|Group32.png|reticule32.png|Robot32.png|key.png|warning32.ico|miscB32.png|speakerB32.png|bug32.png|settings.ico"
l_UnitNames := "Colossus|TechLab|Reactor|InfestorTerran|BanelingCocoon|Baneling|Mothership|PointDefenseDrone|Changeling|ChangelingZealot|ChangelingMarineShield|ChangelingMarine|ChangelingZerglingWings|ChangelingZergling|InfestedTerran|CommandCenter|SupplyDepot|Refinery|Barracks|EngineeringBay|MissileTurret|Bunker|SensorTower|GhostAcademy|Factory|Starport|Armory|FusionCore|AutoTurret|SiegeTankSieged|SiegeTank|VikingAssault|VikingFighter|CommandCenterFlying|BarracksTechLab|BarracksReactor|FactoryTechLab|FactoryReactor|StarportTechLab|StarportReactor|FactoryFlying|StarportFlying|SCV|BarracksFlying|SupplyDepotLowered|Marine|Reaper|Ghost|Marauder|Thor|Hellion|Medivac|Banshee|Raven|Battlecruiser|Nuke|Nexus|Pylon|Assimilator|Gateway|Forge|FleetBeacon|TwilightCouncil|PhotonCannon|Stargate|TemplarArchive|DarkShrine|RoboticsBay|RoboticsFacility|CyberneticsCore|Zealot|Stalker|HighTemplar|DarkTemplar|Sentry|Phoenix|Carrier|VoidRay|WarpPrism|Observer|Immortal|Probe|Interceptor|Hatchery|CreepTumor|Extractor|SpawningPool|EvolutionChamber|HydraliskDen|Spire|UltraliskCavern|InfestationPit|NydusNetwork|BanelingNest|RoachWarren|SpineCrawler|SporeCrawler|Lair|Hive|GreaterSpire|Egg|Drone|Zergling|Overlord|Hydralisk|Mutalisk|Ultralisk|Roach|Infestor|Corruptor|BroodLordCocoon|BroodLord|BanelingBurrowed|DroneBurrowed|HydraliskBurrowed|RoachBurrowed|ZerglingBurrowed|InfestorTerranBurrowed|QueenBurrowed|Queen|InfestorBurrowed|OverlordCocoon|Overseer|PlanetaryFortress|UltraliskBurrowed|OrbitalCommand|WarpGate|OrbitalCommandFlying|ForceField|WarpPrismPhasing|CreepTumorBurrowed|SpineCrawlerUprooted|SporeCrawlerUprooted|Archon|NydusCanal|BroodlingEscort|Mule|Larva|HellionTank|MothershipCore|Locust|SwarmHostBurrowed|SwarmHost|Oracle|Tempest|WidowMine|Viper|WidowMineBurrowed"

ImageListID := IL_Create(10, 5, 1)  ; Create an ImageList with initial capacity for 10 icons, grows it by 5 if need be, and 1=large icons
 
loop, parse, options_menu, | ; | = delimter
	IL_Add(ImageListID, A_Temp "\" A_LoopField) 
	
Gui, Add, TreeView, -Lines ReadOnly ImageList%ImageListID% h440 w150 gOptionsTree

TV_Add("Home", 0, "Icon1")  
TV_Add("Detection List", 0, "Icon2")  
TV_Add("MiniMap/Overlays", 0, "Icon3")  
TV_Add("Injects", 0, "Icon4")  
TV_Add("Unit Grouping", 0, "Icon5")  
TV_Add("Chrono Boost", 0, "Icon6") 
TV_Add("Misc Automation", 0, "Icon7") 
TV_Add("SC2 Keys", 0, "Icon8")  
TV_Add("Warnings", 0, "Icon9")
TV_Add("Misc Abilities", 0, "Icon10")
TV_Add("Volume", 0, "Icon11")
TV_Add("Report Bug", 0, "Icon12")
TV_Add("Settings", 0, "Icon13")

Gui, Add, Tab2, w440 h440 ys x+5 vInjects_TAB, Info||Auto|Forced|Alert|Manual
GuiControlGet, MenuTab, Pos, Injects_TAB
Gui, Tab,  Auto
	Gui, Add, GroupBox, w200 h240 section vOriginTab, Auto Inject
			GuiControlGet, OriginTab, Pos
		Gui, Add, Text,xp+10 yp+25, Method:		
				If (auto_inject = 0 OR auto_inject = "Disabled")
					droplist_var := 4
				Else If (auto_inject = "MiniMap")
					droplist_var := 1
				Else if (auto_inject = "Backspace Adv") || (auto_inject = "Backspace CtrlGroup")
					droplist_var := 2
				Else droplist_var := 3
				Gui, Add, DropDownList,x+10 yp-2 w130 vAuto_inject Choose%droplist_var%, MiniMap||Backspace CtrlGroup|Backspace|Disabled
				tmp_xvar := OriginTabx + 10
		Gui, Add, Checkbox, x%tmp_xvar% yp+30 vauto_inject_alert checked%auto_inject_alert%, Enable Alert
			GuiControlGet, XTab, Pos, auto_inject_alert ;XTabX = x loc
		Gui, Add, Text,y+15, Time Between Alerts (s):
		Gui, Add, Edit, Number Right x+25 yp-2 w45 
			Gui, Add, UpDown, Range1-100000 vauto_inject_time, %auto_inject_time% ;these belong to the above edit
		Gui, Add, Text, X%XTabX% yp+35, Inject Hotkey:
		Gui, Add, Edit, Readonly yp-2 xs+85 center w65 vcast_inject_key gedit_hotkey, %cast_inject_key%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#cast_inject_key,  Edit ;have to use a trick eg '#' as cant write directly to above edit var, or it will activate its own label!

		Gui, Add, Text, X%XTabX% yp+35 w70, Spawn Larva:
		Gui, Add, Edit, Readonly yp-2 xs+85 w65 center vInject_spawn_larva , %Inject_spawn_larva%
			Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#Inject_spawn_larva,  Edit

		Gui, Add, Text, X%XTabX% yp40, Control Group: %A_space%(Unit Selection Storage)
			Gui, Add, Edit, Readonly y+10 xs+60 w90 center vInject_control_group , %Inject_control_group%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#Inject_control_group,  Edit	

	Gui, Add, GroupBox, xs y+30 w200 h140, Advanced Settingss
				Gui, Add, Text, xs+20 yp+25 vSG1, Sleep time (ms):`n(Lower is faster)
					GuiControlGet, XTab2, Pos, SG1 ;XTabX = x loc
				Gui, Add, Edit, Number Right xs+125 yp-2 w45 vEdit_pos_var 
					Gui, Add, UpDown,  Range1-100000 vAuto_inject_sleep, %auto_inject_sleep%
					GuiControlGet, settingsR, Pos, Edit_pos_var ;XTabX = x loc
			
			Gui, Add, Text, xs+20 yp+40, Input Delay (ms):
				Gui, Add, Edit, Number Right xs+125 yp-2 w45 vTT_I_KeyDelay
					Gui, Add, UpDown,  Range0-10 vI_KeyDelay, %I_KeyDelay%						
				
		
Gui, Add, GroupBox, w200 h240 ys xs+210 section, Backspace Setup
		Gui, Add, Text, xs+10 yp+25, Drag Origin:
		if (Drag_origin = "Right")
			droplist_var :=2
		Else
			droplist_var := 1
		Gui, Add, DropDownList,x+60 yp-2 w50 vDrag_origin Choose%droplist_var%, Left|Right|
		
		Gui, Add, Text, xs+10 yp+40, Create Camera: %A_space% %A_space% (Location Storge)
			Gui, Add, Edit, Readonly y+10 xs+60 w90 center vBI_create_camera_pos_x , %BI_create_camera_pos_x%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#BI_create_camera_pos_x,  Edit
		
		Gui, Add, Text, xs+10 yp+40, Camera Position: %A_space% %A_space% (Goto Location)
			Gui, Add, Edit, Readonly y+10 xs+60 w90 center vBI_camera_pos_x , %BI_camera_pos_x%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#BI_camera_pos_x,  Edit
				
Gui, Add, GroupBox, xs y+88 w200 h140, MiniMap && BackspaceCtrlG Setup
		Gui, Add, Text, xs+10 yp+25, Queen Control Group:
			Gui, Add, Edit, Readonly y+10 xs+60 w90 center vMI_Queen_Group, %MI_Queen_Group%
				Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#MI_Queen_Group,  Edit			
		
		Gui, Add, Text, xs+10 yp+40, Max Queen Distance:`n%A_Space% %A_Space% (From Hatch)
			Gui, Add, Edit, Number Right xp+132 yp w45 vTT2_MI_QueenDistance
					Gui, Add, UpDown,  Range1-100000 vMI_QueenDistance, %MI_QueenDistance%			

Gui, Tab,  Info
		gui, font, norm bold s10
		Gui, Add, Text, X%OriginTabX% y+15 cFF0000, Note:
		gui, font, norm s11
		gui, Add, Text, w410 y+15, If a queen has inadequate energy (or is too far from her hatchery), her hatchery will not be injected.
		gui, Add, Text, w410 y+20, The Minimap && Backspace CtrlGroup methods require queens to be hotkeyd. In other words, hatches without a nearby HOTKEYED queen will not be injected.
		gui, Add, Text, w410 y+20, Both Backspace methods require the camera hotkeys be set.
		gui, Add, Text, w410 y+20, If a control, alt, shift, or windows key is held down at the start of the macro you will hear a warning sound.  Release the key(s) and the injects will begin.
		Gui, Font, underline
		Gui, Add, Text,  x300 y262 cBlue gg_PlayModifierWarningSound, Warning Sound
		gui, font, norm bold s10
		Gui, Add, Text, X%OriginTabX% y+10 cFF0000, Problems:
		gui, font, norm s11
		gui, Add, Text, w410 y+15, If you are consistently missing hatcheries, try increasing the sleep time. The Backspace CtrlGroup method is less robust than the other methods. 
		gui, Add, Text, w410 y+15, If something really goes wrong, you can reload the program by pressing "Lwin && space" three times.
		gui, font, norm s10
		gui, font, 		
		
Gui, Tab,  Manual
		Gui, Add, GroupBox,  w295 h165, Manual Inject Timer	;h185
				Gui, Add, Checkbox,xp+10 yp+30 vmanual_inject_timer checked%manual_inject_timer%, Enable
				Gui, Add, Text,y+15, Alert After (s): 
				Gui, Add, Edit, Number Right x+5 yp-2 w45 
					Gui, Add, UpDown, Range1-100000 vmanual_inject_time, %manual_inject_time%
				GuiControlGet, settings2R, Pos, manual_inject_timer
				Gui, Add, Text, x%settings2RX% yp+35 w90, Start/Stop Hotkey:
				Gui, Add, Edit, Readonly yp x+20 w120  vinject_start_key center gedit_hotkey, %inject_start_key%
				Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#inject_start_key,  Edit
				Gui, Add, Text, x%settings2RX% yp+35 w90, Reset Hotkey:
				Gui, Add, Edit, Readonly yp x+20 w120  vinject_reset_key center gedit_hotkey, %inject_reset_key%
				Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#inject_reset_key,  Edit
				
Gui, Tab,  Forced
	Gui, Add, GroupBox, y+20 w230 h250, Fully Automated Injects
		Gui, Add, Checkbox,xp+10 yp+30 vF_Inject_Enable checked%F_Inject_Enable%, Enable
		Gui, Add, Checkbox,y+10 vF_Inject_ModifierBeep checked%F_Inject_ModifierBeep%, Beep If modifier is held down
		Gui, Add, Checkbox,y+10 vF_Inject_Beep checked%F_Inject_Beep%, Beep when auto Inject begins


		Gui, Add, Text,y+15 x%settings2RX% w165, Time Between Injects (SC2 s): 
			Gui, Add, Edit, Number Right x+5 yp-2 w45 
				Gui, Add, UpDown, Range39-100000 vF_Inject_Delay, %F_Inject_Delay%
		Gui, Add, Text,y+15 x%settings2RX% w165, Max. (sequential) Forced Injects: 
			Gui, Add, Edit, Number Right x+5 yp-2 w45 vTT_F_Max_Injects 
				Gui, Add, UpDown, Range1-100000 vF_Max_Injects, %F_Max_Injects%	

		Gui, Add, Text,y+15 x%settings2RX% w165, Sleep time: 
			Gui, Add, Edit, Number Right x+5 yp-2 w45 vTT_F_Sleep_Time 
				Gui, Add, UpDown, Range0-100000 vF_Sleep_Time, %F_Sleep_Time%	

		Gui, Add, Text, x%settings2RX% yp+25, Enable/Disable Hotkey:
			Gui, Add, Edit, Readonly y+10 xp+40 w120  vF_InjectOff_Key center gedit_hotkey, %F_InjectOff_Key%
			Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#F_InjectOff_Key,  Edit				
			
	Gui, Add, GroupBox,  w230 h80 x%OriginTabx% yp+40, Pre-Inject Alert
		Gui, Add, Checkbox,xp+10 yp+25 vF_Alert_Enable checked%F_Alert_Enable%, Enable
		Gui, Add, Text,y+15 x%settings2RX% w165, Preinject Alert (sc2 s): 
			Gui, Add, Edit, Number Right x+5 yp-2 w45 vTT_F_Alert_PreTime
				Gui, Add, UpDown, Range0-100000 vF_Alert_PreTime, %F_Alert_PreTime%
	Gui, Add, Text,y40 x430 w160, Note:`n`nForced Injects will become activated after your first auto/F5 inject.`n`nForced injections are performed using the 'MiniMap' macro, but this function is still compatible with the auto inject 'backspace' method. 
		
		
Gui, Tab,  Alert
		Gui, Add, GroupBox,  w210 h140, Alert Type
		Gui, Add, Checkbox,xp+10 yp+30 vW_inject_ding_on checked%W_inject_ding_on%, Windows Ding
		Gui, Add, Checkbox,yp+25 vW_inject_speech_on checked%W_inject_speech_on%, Spoken Warning
		Gui, Add, Text,y+15 w125, Spoken Warning:
		Gui, Add, Edit, w180 vW_inject_spoken center, %w_inject_spoken%
		Gui, Font, s10
		Gui, Add, Text, y+60 w360, Note: Due to an inconsistency with the programming language, some systems may not hear the 'windows ding'.
		Gui, Font	
							

Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY% vKeys_TAB, SC2 Keys				
	Gui, Add, GroupBox, w280 h135, Starcraft Settings && Keys
		Gui, Add, Text, xp+10 yp+30 w90, Pause Game: 
			Gui, Add, Edit, Readonly yp-2 x+10 w120  center vpause_game , %pause_game%
				Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#pause_game,  Edit
				
		Gui, Add, Text, X%XTabX% yp+35 w90, Escape:
			Gui, Add, Edit, Readonly yp-2 x+10 w120  center vescape , %escape%
				Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#escape,  Edit
				
		Gui, Add, Text, X%XTabX% yp+35 w90, Base Camera:
			Gui, Add, Edit, Readonly yp-2 x+10 w120  center vbase_camera , %base_camera%
				Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#base_camera,  Edit

		gui, font, s10
		tmpX := XTabX-15
		Gui, Add, Text,  X%tmpX% y+50 +wrap, Ensure the following keys match the associated SC2 Functions.
		Gui, Add, Text,  X%tmpX% y+5 +wrap, (either change these settings here or in the SC2 Hotkey options/menu)
		gui, font, 		
			

Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY% vWarnings_TAB, Supply||Macro|Macro2|Warpgates
Gui, Tab, Supply	
; Gui, Add, GroupBox, w420 h335, Supply				
	Gui, Add, Checkbox, X%XTabX% y+30 Vsupplyon checked%supplyon%, Enable Alert

		
			Gui, Add, GroupBox, X%XTabX% yp+35 w175 h260 section, Supply Ranges && Deltas
	
			Gui, font, italic
			Gui, Add, Text,xs+10 yp+25 w100, Warn When Below:
			Gui, font, 
				Gui, Add, Edit, Number Right x+10 yp-2 w45 
					Gui, Add, UpDown, Range1-200 Vsub_lowerdelta, %sub_lowerdelta%

			Gui, Add, Text,xs+10 y+15 w100, Low Range Cutoff:
				Gui, Add, Edit, Number Right x+10 yp-2 w45 
					Gui, Add, UpDown, Range1-200 Vsupplylower, %supplylower%

			Gui, font, italic 
			Gui, Add, Text,xs+10 y+15 w100,  Warn When Below: 
			Gui, font, 
				Gui, Add, Edit, Number Right x+10 yp-2 w45 
					Gui, Add, UpDown, Range1-200 Vsub_middelta, %sub_middelta%
					
					
			Gui, Add, Text,xs+10 y+15 w100, Middle Range Cutoff:
				Gui, Add, Edit, Number Right x+10 yp-2 w45 
					Gui, Add, UpDown, Range1-200 Vsupplymid, %supplymid%

			Gui, font, italic 
			Gui, Add, Text,xs+10 y+15 w100, Warn When Below: 
			Gui, font, 
				Gui, Add, Edit, Number Right x+10 yp-2 w45 
					Gui, Add, UpDown, Range1-200 Vsub_upperdelta, %sub_upperdelta%
					

			Gui, Add, Text,xs+10 y+15 w100, Upper Range Cutoff:
				Gui, Add, Edit, Number Right x+10 yp-2 w45 
					Gui, Add, UpDown, Range1-200 Vsupplyupper, %supplyupper%		

			Gui, font, italic 
			Gui, Add, Text,xs+10 y+15 w100,  Warn When Below:
			Gui, font, 
				Gui, Add, Edit, Number Right x+10 yp-2 w45 
					Gui, Add, UpDown, Range1-200 Vabove_upperdelta, %above_upperdelta%					

					2XTabX := XTabX -10
		Gui, Add, GroupBox, ys x+30 w200 h260, Warnings
		
			Gui, Add, Text,xp+10 yp+25 w125 section, Silent If Supply Below:
			Gui, Add, Edit, Number Right x+10 yp-2 w45 
			Gui, Add, UpDown, Range1-200 Vminimum_supply, %minimum_supply%	

			Gui, Add, Text,xs y+15 w125, Secondary Warnings:
				Gui, Add, Edit, Number Right x+10 yp-2 w45 Vsec_supply
					Gui, Add, UpDown, Range0-200, %sec_supply%

			Gui, Add, Text,y+15 xs w125, Secondary Delay:
				Gui, Add, Edit, Number Right x+10 yp-2 w45 
					Gui, Add, UpDown, Range0-200 Vadditional_delay_supply, %additional_delay_supply%
		
			Gui, Add, Text,y+15 xs w125, Spoken Warning:
				Gui, Add, Edit, w180 Vw_supply center, %w_supply%

Gui, Tab, Macro	
	Gui, Add, GroupBox, w185 h175 section, Minerals
		Gui, Add, Checkbox, xp+10 yp+20  Vmineralon checked%mineralon%, Enable Alert
		Gui, Add, Text, y+10 section w105, Trigger Amount:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vmineraltrigger, %mineraltrigger%
				
		Gui, Add, Text,xs y+10 w105, Secondary Warnings:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range0-20000 Vsec_mineral, %sec_mineral%
				
		Gui, Add, Text,xs y+10 w105, Secondary Delay:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vadditional_delay_minerals, %additional_delay_minerals%
				
		Gui, Add, Text, X%XTabX% y+5 w125, Spoken Warning:
			Gui, Add, Edit, w165 Vw_mineral center, %w_mineral%		
				
	Gui, Add, GroupBox, x%OriginTabX% y+20  w185 h205, Gas
		Gui, Add, Checkbox, xp+10 yp+20  Vgas_on checked%gas_on%, Enable Alert
		
		Gui, Add, Text, y+10 section w105, Trigger Amount:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vgas_trigger, %gas_trigger%

		Gui, Add, Text,xs y+10 w105, Secondary Warnings:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range0-20000 Vsec_gas, %sec_gas%
				
		Gui, Add, Text,xs y+10 w105, Secondary Delay:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vadditional_delay_gas, %additional_delay_gas%
				
		Gui, Add, Text, xs y+5 w125, Spoken Warning:
			Gui, Add, Edit, w165 Vw_gas center, %w_gas%		
			
	Gui, Add, GroupBox, y%OriginTaby% X+35 w185 h175 section Vmacro_R_TopGroup, Idle Worker	;h185
	GuiControlGet, macro_R_TopGroup, Pos, macro_R_TopGroup
	
		Gui, Add, Checkbox, xp+10 yp+20  Vidleon checked%idleon%, Enable Alert
		Gui, Add, Text, y+10 section w105, Trigger Amount:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vidletrigger, %idletrigger%
				
		Gui, Add, Text,xs y+10 w105, Secondary Warnings:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range0-20000 Vsec_idle, %sec_idle%
				
		Gui, Add, Text,xs y+10 w105, Secondary Delay:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vadditional_idle_workers, %additional_idle_workers%
				
		Gui, Add, Text, xs y+5 w125, Spoken Warning:
			Gui, Add, Edit, w165 Vw_idle center, %w_idle%	
	
Gui, Tab, Macro2
	;Gui, Add, GroupBox, y+20 x%macro_R_TopGroupX% w185 h205, Worker Production	
	Gui, Add, GroupBox, w185 h270, Worker Production	
	
		Gui, Add, Checkbox, xp+10 yp+20  Vworkeron checked%workeron%, Enable Alert
		Gui, Add, Text, y+10 section w105, Time without Production - Zerg:
			Gui, Add, Edit, Number Right x+5 yp+2 w55 vTT_workerproduction_time
				Gui, Add, UpDown, Range1-20000 Vworkerproduction_time, %workerproduction_time%

		Gui, Add, Text, xs y+20 w105, Time without Production - T && P:
			Gui, Add, Edit, Number Right x+5 yp+2 w55 vTT_workerProductionTPIdle
				Gui, Add, UpDown, Range1-20000 VworkerProductionTPIdle, %workerProductionTPIdle%
				
		Gui, Add, Text,xs y+20 w105, Secondary Warnings:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_sec_workerprod
				Gui, Add, UpDown, Range0-20000 Vsec_workerprod, %sec_workerprod%
				
		Gui, Add, Text,xs y+10 w105, Secondary Delay:
			Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_additional_delay_worker_production
				Gui, Add, UpDown, Range1-20000 Vadditional_delay_worker_production, %additional_delay_worker_production%
				
		Gui, Add, Text, xs y+10 w85, Terran Warning:
			Gui, Add, Edit, yp x+0 W85 Vw_workerprod_T center, %w_workerprod_T%	
			
		Gui, Add, Text, xs y+5 w85,Protoss Warning:
			Gui, Add, Edit, yp x+0 W85 Vw_workerprod_P center, %w_workerprod_P%	
		
		Gui, Add, Text, xs y+5 w85,Zerg Warning:
			Gui, Add, Edit, yp x+0 W85 Vw_workerprod_Z center, %w_workerprod_Z%	

Gui, Tab, Warpgates
Gui, Add, GroupBox, y+20 w410 h135, Forgotten Gateway/Warpgate Warning
	
		Gui, Add, Checkbox,xp+10 yp+25 Vwarpgate_warn_on checked%warpgate_warn_on%, Enable Alert
		
		Gui, Add, Text, y+10 section w105, Warning Count:
			Gui, Add, Edit,  Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vsec_warpgate, %sec_warpgate%		

		Gui, Add, Text,  x%xtabx% y+10  w105, Warning Delay:
			Gui, Add, Edit,  Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vdelay_warpgate_warn, %delay_warpgate_warn%			

		Gui, Add, Text, x%xtabx% y+10  w105, Secondary Delay:
			Gui, Add, Edit,  Number Right x+5 yp-2 w55 
				Gui, Add, UpDown, Range1-20000 Vdelay_warpgate_warn_followup, %delay_warpgate_warn_followup%						
		
		Gui, Add, Text, x+30 ys section w75, Warning:
			Gui, Add, Edit, yp-2 x+10 w110 Vw_warpgate center, %w_warpgate%		

	
Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY% vMisc_TAB, Misc Abilities
	Gui, Add, GroupBox, w240 h150 section, Misc Hotkeys
		
		Gui, Add, Text, xp+10 yp+30 w80, Worker Count:
			Gui, Add, Edit, Readonly yp-2 x+5 w100  center Vworker_count_local_key , %worker_count_local_key%
				Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#worker_count_local_key,  Edit
				
		Gui, Add, Text, X%XTabX% yp+35 w80, Enemy Workers:
			Gui, Add, Edit, Readonly yp-2 x+5 w100  center Vworker_count_enemy_key , %worker_count_enemy_key%
				Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#worker_count_enemy_key,  Edit		
		
		Gui, Add, Text, X%XTabX% yp+35 w80, Trainer On/Off:
			Gui, Add, Edit, Readonly yp-2 x+5 w100  center Vwarning_toggle_key , %warning_toggle_key%
				Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#warning_toggle_key,  Edit

		Gui, Add, Text, X%XTabX% yp+35 w80, Ping Map:
			Gui, Add, Edit, Readonly yp-2 x+5 w100  center Vping_key , %ping_key%
				Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#ping_key,  Edit
	
	Gui, Add, GroupBox, x+20 ys w160 h150, Detect Spawning Races
		
		Gui, Add, Checkbox,xp+10 yp+30 Vrace_reading checked%race_reading%, Enable
		Gui, Add, Checkbox, y+10 vAuto_Read_Races checked%Auto_Read_Races%, Run on match start
		Gui, Add, Checkbox, y+10 Vrace_speech checked%race_speech%, Speak Races
		Gui, Add, Checkbox, y+10 Vrace_clipboard checked%race_clipboard%, Copy to Clipboard
		
		Gui, Add, Text, yp+25 w20, Hotkey:
			Gui, Add, Edit, Readonly yp-2 x+5 w65  center Vread_races_key , %read_races_key%
				Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#read_races_key,  Edit
				
	Gui, Add, GroupBox, xs ys+160 w410 h110, Auto Game Pause - Idle/AFK@Start
	
	Gui, Add, Checkbox,xp+10 yp+25 Vidle_enable checked%idle_enable%, Enable
	;	Gui, Add, Checkbox,xp+10 yp+25 Vidle_enable checked0 disabled, Enable
		
		Gui, Add, Text,xp y+10, User Idle Time:
			Gui, Add, Edit,  Number Right x+10 yp-2 w40 vTTidle_time  
				Gui, Add, UpDown, Range1-20000 Vidle_time , %idle_time%
		tmpX := XTabX+200
			Gui, Add, Text, X%tmpX% yp-25 w105, Don't Pause Before:
				Gui, Add, Edit,  Number Right x+5 yp-2 w40 vTTUserIdle_LoLimit 
					Gui, Add, UpDown, Range1-20000 VUserIdle_LoLimit , %UserIdle_LoLimit%
	
			Gui, Add, Text, X%tmpX% y+10 w105 vTTTUserIdle_HiLimit , Don't Pause After:
				Gui, Add, Edit,  Number Right x+5 yp-2 w40  vTTUserIdle_HiLimit 
					Gui, Add, UpDown, Range1-20000 VUserIdle_HiLimit , %UserIdle_HiLimit%					
				
		Gui, Add, Text, x%xtabx% y+10, Chat Message:
			Gui, Add, Edit, yp-2 x+10 w310 Vchat_text center, %chat_text%	
	
	Gui, Add, GroupBox, xs y+20 w410 h110, Misc		
		Gui, Add, Checkbox, x%xtabx% yp+25 VMaxWindowOnStart Checked%MaxWindowOnStart%, Maximise Starcraft on match start		
		Gui, Add, Checkbox, x%xtabx% yp+30 gHumanMouseWarning VHumanMouse Checked%HumanMouse%, Use human like mouse movements
		Gui, Add, Text,yp+20 xp+40, Time range for each mouse movement (ms):
		Gui, Add, Text,yp-10 x450, Lower limit:
		Gui, Add, Edit, Number Right x+25 yp-2 w45 
			Gui, Add, UpDown,  Range1-300 vHumanMouseTimeLo, %HumanMouseTimeLo%, ;these belong to the above edit		Gui, Add, Text,yp xp+10, Lower limit:
		Gui, Add, Text,yp+25 x450, Upper limit:
		Gui, Add, Edit, Number Right x+25 yp-2 w45 
			Gui, Add, UpDown,  Range1-300 vHumanMouseTimeHi, %HumanMouseTimeHi%, ;these belong to the above edit
		

Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY% vVolume_TAB, Volume
	Gui, Add, GroupBox, w265 h310 section, Volume
	
		Gui, Add, Text,X%XTabX% yp+30 w90, Speech:
			Gui, Add, Slider, ToolTip  NoTicks w125 x+2 yp-2  Vspeech_volume, %speech_volume%
				Gui, Add, Button, xp+123 0 yp w30 h23 vTest_VOL_Speech gTest_VOL, Test
		
		Gui, Add, Text,X%XTabX% y+15 w90, Overall Program:
			Gui, Add, Slider, ToolTip  NoTicks w125 x+2 yp-2  Voverall_program, %overall_program%
				Gui, Add, Button, xp+123 yp w30 h23 vTest_VOL_All gTest_VOL, Test
		
		Gui, Add, Text, X%XTabX% yp+35 w90, +Speaker Volume: 
			Gui, Add, Edit, Readonly yp-2 x+10 w105  center Vspeaker_volume_up_key , %speaker_volume_up_key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_hotkey v#speaker_volume_up_key,  Edit
				
		Gui, Add, Text, X%XTabX% yp+40 w90, -Speaker Volume:
			Gui, Add, Edit, Readonly yp-2 x+10 w105  center Vspeaker_volume_down_key , %speaker_volume_down_key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_hotkey v#speaker_volume_down_key,  Edit

		Gui, Add, Text, X%XTabX% yp+40 w90, +Speech Volume:
			Gui, Add, Edit, Readonly yp-2 x+10 w105  center Vspeech_volume_up_key , %speech_volume_up_key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_hotkey v#speech_volume_up_key,  Edit

		Gui, Add, Text, X%XTabX% yp+40 w90, -Speech Volume:
			Gui, Add, Edit, Readonly yp-2 x+10 w105  center Vspeech_volume_down_key , %speech_volume_down_key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_hotkey v#speech_volume_down_key,  Edit
				
		Gui, Add, Text, X%XTabX% yp+40 w90, +Program Volume:
			Gui, Add, Edit, Readonly yp-2 x+10 w105  center Vprogram_volume_up_key , %program_volume_up_key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_hotkey v#program_volume_up_key,  Edit

		Gui, Add, Text, X%XTabX% yp+40 w90, -Program Volume:
			Gui, Add, Edit, Readonly yp-2 x+10 w105  center Vprogram_volume_down_key , %program_volume_down_key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_hotkey v#program_volume_down_key,  Edit
				
			

Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY% vSettings_TAB, Settings				
	Gui, Add, GroupBox, xs ys+5 w161 h85 section, Misc. Settings
	
		Gui, Add, Text, xp+10 yp+30 w80, Input Method:
		if (input_method = "Input")
			droplist2_var :=3
		Else If (input_method = "Play")
			droplist2_var := 2
		Else ; If (input_method = "Event")
			droplist2_var := 1
			Gui, Add, DropDownList, x+5 yp-2 w55 Vinput_method Choose%droplist2_var%, Event|Play|Input
		
		Gui, Add, Checkbox,xs+10 yp+30 Vauto_check_updates checked%auto_check_updates%, Auto Check For Updates
	
	Gui, Add, GroupBox, xs yp+30 w161 h170, Key Blocking
		Gui, Add, Checkbox,xp+10 yp+25 vBlockingStandard checked%BlockingStandard%, Standard Keys	
		Gui, Add, Checkbox, y+10 vBlockingFunctional checked%BlockingFunctional%, Functional F-Keys 	
		Gui, Add, Checkbox, y+10 vBlockingNumpad checked%BlockingNumpad%, Numpad Keys	
		Gui, Add, Checkbox, y+10 vBlockingMouseKeys checked%BlockingMouseKeys%, Mouse Buttons	
		Gui, Add, Checkbox, y+10 vBlockingMultimedia checked%BlockingMultimedia%, Mutimedia Buttons	
		Gui, Add, Checkbox, y+10 vBlockingModifier checked%BlockingModifier%, Modifier Keys	
	
	Gui, Add, GroupBox, xs yp+30 w161 h60, Unit Deselection
		Gui, Add, Text, xp+10 yp+25, Sleep Time:
		Gui, Add, Edit, Number Right x+25 yp-2 w45 
			Gui, Add, UpDown,  Range0-300 vDeselectSleepTime, %DeselectSleepTime%,

	Gui, Add, GroupBox, Xs+171 ys w245 h85, Stealth Mode (Hide Icons/Menus)
		Gui, Add, Checkbox,xp+10 yp+25 VHideTrayIcon checked%HideTrayIcon%, Enable	
		Gui, Add, Text, yp+30 w80, Exit Hotkey:
			Gui, Add, Edit, Readonly yp-2 x+5 w100  center Vexit_hotkey , %exit_hotkey%
				Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#exit_hotkey,  Edit

	Gui, Add, GroupBox, Xs+171 yp+37 w245 h170, Debugging
		Gui, Add, Button, xp+10 yp+30  Gg_ListVars,  List Variables

		
Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY% vDetection_TAB, Detection List
	loop, parse, l_GameType, `,
	{
		BAS_on_%A_LoopField% := alert_array[A_LoopField, "Enabled"]
		BAS_copy2clipboard_%A_LoopField% := alert_array[A_LoopField, "Clipboard"]
	}
	Gui, Add, GroupBox, w130 h65 section, 1v1
		Gui, Add, Checkbox, X%XTabX% yp+20 vBAS_on_1v1 checked%BAS_on_1v1%, Enable Warnings
		Gui, Add, Checkbox, y+10 vBAS_copy2clipboard_1v1 checked%BAS_copy2clipboard_1v1%, Copy To Clipboard		
	Gui, Add, GroupBox, xs yp+45 w130 h65, 2v2
		Gui, Add, Checkbox, X%XTabX% yp+20 vBAS_on_2v2 checked%BAS_on_2v2%, Enable Warnings
		Gui, Add, Checkbox, y+10 vBAS_copy2clipboard_2v2 checked%BAS_copy2clipboard_2v2%, Copy To Clipboard
	Gui, Add, GroupBox, ys x+25 w130 h65 section, 3v3	
		Gui, Add, Checkbox, xp+10 yp+20 vBAS_on_3v3 checked%BAS_on_3v3%, Enable Warnings	 
		Gui, Add, Checkbox, y+10 vBAS_copy2clipboard_3v3 checked%BAS_copy2clipboard_3v3%, Copy To Clipboard
	Gui, Add, GroupBox, xs yp+45 w130 h65, 4v4
		Gui, Add, Checkbox,xp+10 yp+20 vBAS_on_4v4 checked%BAS_on_4v4%, Enable Warnings	
		Gui, Add, Checkbox, y+10 vBAS_copy2clipboard_4v4 checked%BAS_copy2clipboard_4v4%, Copy To Clipboard
	Gui, Add, GroupBox, ys x+25 w130 h65, FFA	
		Gui, Add, Checkbox, xp+10 yp+20 vBAS_on_FFA checked%BAS_on_FFA%, Enable Warnings	 
		Gui, Add, Checkbox, y+10 vBAS_copy2clipboard_FFA checked%BAS_copy2clipboard_FFA%, Copy To Clipboard
		tmp_xGUIlocation := XTabX - 10
	Gui, Add, GroupBox, X%tmp_xGUIlocation% y+120 w275 h55, Playback Last Alert			
		Gui, Add, Text, xp+10 yp+25 w40,Hotkey:
			Gui, Add, Edit, Readonly yp-2 x+5 w100  center vPlayback_Alert_Key , %Playback_Alert_Key%
				Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#Playback_Alert_Key,  Edit	
	Gui, Font, s10
	Gui, Add, Button, center xs-145 yp+50 w275 h60 gAlert_List_Editor vAlert_List_Editor, Launch Alert List Editor
	Gui, Font,
	
Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY% vBug_TAB, Report Bug
	Gui, Add, Text, y+30 section w100 , Your Email Address:`n%A_Space%%A_Space%%A_Space%%A_Space%%A_Space%(optional) 
	Gui, Add, Edit, x+20 yp w250 vReport_Email,
	Gui, Add, Text, xs ys+40 w100, Problem Description:
	Gui, Add, Edit, x+20 yp w250 h200 vReport_TXT,
	Gui, Add, Button, vB_Report gB_Report xp+80 y+20 w80 h50, Report
	
Gui, Add, Tab2, w440 h440 X%MenuTabX%  Y%MenuTabY% vChrono_Gate_TAB, WarpGates
	Gui, Add, GroupBox, w200 h220 section, Settings
		Gui, Add, Checkbox, xp+10 yp+25 vCG_Enable checked%CG_Enable%, Enable
		Gui, Add, Checkbox, y+15 vCG_Random_off checked%CG_Random_off%, Add Random Offset
		Gui, Add, Text, yp+35 w40,Hotkey:
			Gui, Add, Edit, Readonly yp-2 x+5 w100  center vCast_ChronoGate_Key , %Cast_ChronoGate_Key%
				Gui, Add, Button, yp-2 x+5 gEdit_hotkey v#Cast_ChronoGate_Key,  Edit				
		tmpx := MenuTabX + 25
		Gui, Add, Text, X%tmpx% yp+35, Sleep time (ms):
		Gui, Add, Edit, Number Right xp+120 yp-2 w45 vTT_Chrono_Gate_Sleep 
			Gui, Add, UpDown,  Range0-1000 vChrono_Gate_Sleep, %Chrono_Gate_Sleep%					
		Gui, Add, Text, X%tmpx% yp+35, Input Delay (ms):
		Gui, Add, Edit, Number Right xp+120 yp-2 w45 vTT_CG_KeyDelay
			Gui, Add, UpDown,  Range0-10 vCG_KeyDelay, %CG_KeyDelay%		
		Gui, Add, Text, X%tmpx% yp+35, Chrono Remainder:`n    (1 = 25 mana)
		Gui, Add, Edit, Number Right xp+120 yp-2 w45 vTT_CG_chrono_remainder 
			Gui, Add, UpDown,  Range0-1000 vCG_chrono_remainder, %CG_chrono_remainder%		
					
	Gui, Add, GroupBox, ys x+25  w200 h220 section, SC2 Keys && Control Groups
		Gui, Add, Text, xp+10 yp+25 , Stored Selection Control Group:
			Gui, Add, Edit, Readonly xp+25 y+10  w100  center vCG_control_group , %CG_control_group%
				Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#CG_control_group,  Edit				
		Gui, Add, Text, xs+10 yp+35 ,Nexus Control Group:
			Gui, Add, Edit, Readonly xp+25 y+10  w100  center vCG_nexus_Ctrlgroup_key , %CG_nexus_Ctrlgroup_key%
				Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#CG_nexus_Ctrlgroup_key,  Edit		
		Gui, Add, Text, xs+10 yp+35 ,Chrono Boost Key:
			Gui, Add, Edit, Readonly xp+25 y+10  w100  center vchrono_key , %chrono_key%
				Gui, Add, Button, yp-2 x+5 gEdit_SendHotkey v#chrono_key,  Edit	
		
		Gui, Add, Text, X%tmpx% y+85 cRed, Note:
		Gui, Add, Text, x+10 yp+0, If gateways exist, they will be chrono boosted after the warpgates. 
				

Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY% vAutoGroup_TAB, Terran||Protoss|Zerg|Delay|Info	
Short_Race_List := "Terr|Prot|Zerg"
loop, parse, Short_Race_List, |
{
	if (A_LoopField = "Terr")
	{	Gui, Tab, Terran
		Tmp_LongRace := "Terran"
	}
	Else if (A_LoopField = "Prot")
	{	Gui, Tab, Protoss
		Tmp_LongRace := "Protoss"
	}
	Else 
	{	Gui, Tab, Zerg
		Tmp_LongRace := "Zerg"
	}
	checked := A_UnitGroupSettings["AutoGroup", A_LoopField, "Enabled"]
	AGX := MenuTabX + 20, AGY := MenuTabY +50
	Gui, Add, Checkbox, X%AGX%  Y%AGY%  vAG_Enable_%A_LoopField% checked%checked%, Enable Auto Grouping
	checked := A_UnitGroupSettings["LimitGroup", Tmp_LongRace, "Enabled"]
;	Gui, Add, Checkbox, X%AGX% Y+10 v%Tmp_LongRace%_LimitGroup checked%checked%, Restrict Unit Grouping
	Gui, Add, Text, yp X540 Center, Restrict Unit`nGrouping:
	XLeft := XTabX - 10
	loop, 10
	{		
		if (10 = i := A_Index)	; done like this so 0 comes after 9
			i := 0
		Units := A_UnitGroupSettings[A_LoopField, i]
		 
		Gui, add, text, y+20 X%XLeft%, Group %i%
		Gui, Add, Edit, yp-2 x+10 w280  center r1 vAG_%A_LoopField%%i%, %Units%
		Gui, Add, Button, yp-2 x+10 gEdit_AG v#AG_%A_LoopField%%i%,  Edit
		checked := A_UnitGroupSettings["LimitGroup", Tmp_LongRace, i,"Enabled"]
		Gui, Add, Checkbox, yp+4 x+20 vLG_%Tmp_LongRace%%i% checked%checked%
	}	
}				
Gui, Tab, Info
	Gui, Font, s10
	Gui, add, text, x+25 y+15 w380,Auto Unit Grouping:`n`nThis function will add (shift + control group) selected units to their preselected control groups, providing:`n`n• One of the selected units in not in said control group.`n• All of the selected units 'belong'  in this (preselected) control group.`nUnits are added after the control, shift, alt, && windows keys are released.
	Gui, add, text, y+20 w380,Restrict Unit Grouping:`n`nIf units have been specified for a particular control group, only these preselected units can be added to that control group.`n`nThis prevents users erroneously adding units to control groups.`n`n• Any unit can be added to a blank control group.
	Gui, Font, s10 BOLD
	Gui, add, text, X%XTabX% y+8 cRED , Note:
	Gui, Font, s10 norm
	Gui, add, text, xp+45 yp+0 w340, Auto and Restrict Unit grouping functions are not exclusive, i.e. they can be used together or alone!
	Gui, Font, s10 BOLD
	Gui, add, text, X%XTabX% y+8 cRED , Note:
	Gui, Font, s7 norm
	Gui, add, text, xp+45 yp+0 w340, When using these functions, it is highly recommended that you set the method of artificial input to "Input" (under settings). (providing this is compatible with your system)
	Gui, Font
Gui, Tab, Delay
	Gui, Add, Text, x+25 y+35, Delay (ms):
	Gui, Add, Edit, Number Right x+20 yp-2 w45 vTT_AGDelay 
	Gui, Add, UpDown,  Range0-1500 vAG_Delay, %AG_Delay%	


Gui, Add, Tab2, w440 h440 X%MenuTabX%  Y%MenuTabY% vMiscAutomation_TAB, Select Army||Split|	
Gui, Tab, Select Army
	Gui, Add, Checkbox, y+25 x+15 vSelectArmyEnable Checked%SelectArmyEnable% , Enable Select Army Function		
	Gui, Add, Checkbox, yp+25 xp+15 section vModifierBeepSelectArmy Checked%ModifierBeepSelectArmy%, Beep if modifier is held down		
	Gui, Add, Text, yp+35, Hotkey:
	Gui, Add, Edit, Readonly yp-2 xs+85 center w65 vcastSelectArmy_key gedit_hotkey, %castSelectArmy_key%
	Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#castSelectArmy_key,  Edit ;have to use a trick eg '#' as cant write directly to above edit var, or it will activate its own label!

	Gui, Add, Text, Xs yp+35 w70, Select Army:
	Gui, Add, Edit, Readonly yp-2 xs+85 w65 center vSc2SelectArmy_Key , %Sc2SelectArmy_Key%
		Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#Sc2SelectArmy_Key,  Edit
		
	Gui, Add, Text, Xs yp+35, Sleep time (ms):
	Gui, Add, Edit, Number Right xp+145 yp-2 w45 vTT_SleepSelectArmy
	Gui, Add, UpDown,  Range0-100 vSleepSelectArmy, %SleepSelectArmy%
	Gui, Add, Checkbox, Xs yp+35 vSelectArmyControlGroupEnable Checked%SelectArmyControlGroupEnable%, Control group the units
	Gui, Add, Text, Xs+30 yp+20 w70, Ctrl Group:
	Gui, Add, Edit, Readonly yp-2 xs+85 w65 center vSc2SelectArmyCtrlGroup , %Sc2SelectArmyCtrlGroup%
		Gui, Add, Button, yp-2 x+10 gEdit_SendHotkey v#Sc2SelectArmyCtrlGroup,  Edit
	Gui, Add, Text, Xs yp+40, Deselect These Units:
	Gui, Add, Checkbox, Xs+30 yp+20 vSelectArmyDeselectXelnaga Checked%SelectArmyDeselectXelnaga%, Xelnaga (tower) units
	Gui, Add, Checkbox, Xs+30 yp+20 vSelectArmyDeselectPatrolling Checked%SelectArmyDeselectPatrolling%, Patrolling units
	Gui, Add, Checkbox, Xs+30 yp+20 vSelectArmyDeselectHoldPosition Checked%SelectArmyDeselectHoldPosition%, On hold position
	Gui, Add, Checkbox, Xs+30 yp+20 vSelectArmyDeselectFollowing Checked%SelectArmyDeselectFollowing%, On follow command
	Gui, add, text, Xs y+15, Units:
	Gui, Add, Edit, yp-2 x+10 w300 section  center r1 vl_DeselectArmy, %l_DeselectArmy%
	Gui, Add, Button, yp-2 x+10 gEdit_AG v#l_DeselectArmy,  Edit

Gui, Tab, Split
	Gui, Add, Checkbox, y+25 x+25 vSplitUnitsEnable Checked%SplitUnitsEnable% , Enable Split Unit Function	
	Gui, Add, Text, section yp+35, Hotkey:
	Gui, Add, Edit, Readonly yp-2 xs+85 center w65 vcastSplitUnit_key gedit_hotkey, %castSplitUnit_key%
	Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#castSplitUnit_key,  Edit
	Gui, Add, Text, Xs yp+35 w70, Ctrl Group Storage:
	Gui, Add, Edit, Readonly yp xs+85 w65 center vSplitctrlgroupStorage_key , %SplitctrlgroupStorage_key%
		Gui, Add, Button, yp x+10 gEdit_SendHotkey v#SplitctrlgroupStorage_key,  Edit
	Gui, Add, Text, Xs yp+35, Sleep time (ms):
	Gui, Add, Edit, Number Right xp+145 yp-2 w45 vTT_SleepSplitUnits
	Gui, Add, UpDown,  Range0-100 vSleepSplitUnits, %SleepSplitUnits%
	Gui, Add, Text, Xs yp+150, ****This is in a very beta stage and will be improved later***
				
Gui, Add, Tab2, w440 h440 X%MenuTabX%  Y%MenuTabY% vAutoMine_TAB, Settings||Hotkeys|
Gui, Tab, Settings	
	Gui, Add, GroupBox, y+20 w195 h300 section, Settings
		Gui, Add, Checkbox, xp+10 yp+30 vAuto_mine checked%auto_mine%, Enable
		Gui, Add, Checkbox, yp+25 vAuto_mineMakeWorker checked%Auto_mineMakeWorker%, Make Worker
		Gui, Add, Checkbox, yp+25 vAuto_Mine_Set_CtrlGroup checked%Auto_Mine_Set_CtrlGroup%, Set Base Ctrl Group
		
		Gui, Add, Text,y+20 w85, Split Type: 
		if WorkerSplitType
			droplist3_var := substr(WorkerSplitType, 0, 1)
		else droplist3_var := 1
		Gui, Add, DropDownList, x+35 yp-2 w45 vWorkerSplitType Choose%droplist3_var%, 6x1|3x2||2x3	
		
		Gui, Add, Text, X%XTabX% y+20 w65, Method:
		droplist3_var := AutoMineMethod = "MiniMap" ? 2 : 1		
		Gui, Add, DropDownList, x+35 yp-2 w65 gg_GuiSetupAutoMine vAutoMineMethod Choose%droplist3_var%, Normal||MiniMap	
		
		Gui, Add, Text, X%XTabX% y+20 w85, Sleep (ms):castSplitUnit_key
		Gui, Add, Edit, Number Right x+35 yp-2 w45 vAuto_Mine_Sleep2
			Gui, Add, UpDown, Range1-100000 vTT_Auto_Mine_Sleep2, %Auto_Mine_Sleep2%		
		
		Gui, Add, Text, X%XTabX% y+20 w85, Input Delay (ms):
			Gui, Add, Edit, Number Right X+35 yp-2 w45 vTT_AM_KeyDelay
				Gui, Add, UpDown,  Range0-10 vAM_KeyDelay, %AM_KeyDelay%			
					
		Gui, Add, Text,X%XTabX% y+20 w85, Start Mining at (s): 
		Gui, Add, Edit, Number Right x+35 yp-2 w45 vStart_Mine_Time
			Gui, Add, UpDown, Range0-100000, %Start_Mine_Time%	
		Gui, Font, s10
		Gui, Add, Text,Xs y+40 , Note: The "Normal" method will only function at 1920 x 1080 resolution.
		Gui, Font,
		XMenu := 390
		Gui, Add, GroupBox, ys x%XMenu% w195 h300 vAMGUI1, MiniMap Settings
		Gui, Font, underline
		Gui, Add, Text, xp+10 yp+20 vAMGUI2, Pixel Colour
		Gui, Font
		XMenu += 30
		Gui, Add, Text, x%XMenu% y+15 w55 vAMGUI3, Alpha:
			Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MiniMap_PixelColourAlpha, %AM_MiniMap_PixelColourAlpha%
		Gui, Add, Text, x%XMenu% y+15 w55 vAMGUI4, Red:
			Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MiniMap_PixelColourRed, %AM_MiniMap_PixelColourRed%
		Gui, Add, Text, x%XMenu% y+15 w55 vAMGUI5, Green:
			Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MiniMap_PixelColourGreen, %AM_MiniMap_PixelColourGreen%
		Gui, Add, Text, x%XMenu% y+15 w55 vAMGUI6, Blue:
			Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MinsiMap_PixelColourBlue, %AM_MinsiMap_PixelColourBlue%
	
		Gui, Add, Button, x%XMenu% y+15 w60 h23 gg_GuiSetupResetPixelColour v#ResetPixelColour,  Reset	
		Gui, Add, Button, x+30 yp  w60 h23 gg_FindTestPixelColourMsgbox v#FindPixelColour,  Find	

		XMenu -= 20
		Gui, Add, Text,  x%XMenu% y+20 w85 vAMGUI7, Variance:
			Gui, Add, Edit, Number Right x+35 yp-2 w45 vAM_MiniMap_PixelVariance
			Gui, Add, UpDown, Range0-100 vTT_AM_MiniMap_PixelVariance, %AM_MiniMap_PixelVariance%	
		Gui, Add, Button, xp-60 y+15 w60 h23 gg_PixelColourFinderHelpFile vAMGUI8,  About	
		gosub, g_GuiSetupAutoMine	;hide/show the minimap items
		
		
		
Gui, Tab, Hotkeys	
Gui, Add, GroupBox, xs y+20 w235 h210 section, SC2 HotKeys
		Gui, Add, Text, X%XTabX% yp+25  w80 , Idle Worker:
		Gui, Add, Edit, Readonly yp-2 x+10 w80  center vIdle_Worker_Key , %Idle_Worker_Key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Idle_Worker_Key,  Edit			
		Gui, Add, Text, X%XTabX% yp+30  w80, Gather Minerals:
		Gui, Add, Edit, Readonly yp-2 x+10 w80  center vGather_Minerals_key , %Gather_Minerals_key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Gather_Minerals_key,  Edit		
		Gui, Add, Text, X%XTabX% yp+30 w80 , Base Ctrl Group:
		Gui, Add, Edit, Readonly yp-2 x+10 w80  center vBase_Control_Group_Key , %Base_Control_Group_Key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Base_Control_Group_Key,  Edit	
		Gui, Add, Text, X%XTabX% yp+30  w80, Make SCV:
		Gui, Add, Edit, Readonly yp-2 x+10 w80  center vMake_Worker_T_Key , %Make_Worker_T_Key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Make_Worker_T_Key,  Edit			
		Gui, Add, Text, X%XTabX% yp+30  w80, Make Probe:
		Gui, Add, Edit, Readonly yp-2 x+10 w80  center vMake_Worker_P_Key , %Make_Worker_P_Key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Make_Worker_P_Key,  Edit						
		Gui, Add, Text, X%XTabX% yp+30  w80, Select Larva:
		Gui, Add, Edit, Readonly yp-2 x+10 w80  center vMake_Worker_Z1_Key , %Make_Worker_Z1_Key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Make_Worker_Z1_Key,  Edit							
		Gui, Add, Text, X%XTabX% yp+30  w80, Make Drone:
		Gui, Add, Edit, Readonly yp-2 x+10 w80  center vMake_Worker_Z2_Key , %Make_Worker_Z2_Key%
				Gui, Add, Button, yp-2 x+10 w30 h23 gEdit_SendHotkey v#Make_Worker_Z2_Key,  Edit	
		Gui, Font, s11
		Gui, Add, Text, X%XTabX% yp+60, Note:
		Gui, Add, Text, xp+40  w340, Ensure the correct ('backspace') base camera key is set in the "SC2 Keys Section" (below Auto Mine - on the left).
		Gui, Font, s10
		Gui, Font,
Gui, Add, Tab2, w440 h440 X%MenuTabX%  Y%MenuTabY% vHome_TAB, Home||Emergency

Gui, Tab, Home
		Gui, Add, Button, y+30 gTrayUpdate w150, Check For Updates
		Gui, Add, Button, y+20 gB_HelpFile w150, Read The Help File
		Gui, Add, Button, y+20 gB_ChangeLog w150, Read The ChangeLog
		Gui, Add, Checkbox,y+30 Vlaunch_settings checked%launch_settings%, Show this menu on startup	
		
		if ( input_method <> "input" )
		{
			Gui, Add, Text, y+25 cRED, Note:
			Gui, Add, Text, x+10 yp+0, It is highly recommended that you set the method of artificial input to "Input".`n(providing this is compatible with your system)`nThis setting can be found under " Settings --> Input Method "
		}
		Gui, Add, Picture, x170 y320 h90 w90 gP_Protoss_Joke vProtossPic, %A_Temp%\Protoss90.png
		Gui, Add, Picture, x+50 yp-20 h128 w128 gP_Terran_Joke vTerranPic , %A_Temp%\Terran90.png
		Gui, Add, Picture, x+50  yp+20 h90 w90 gP_zerg_Joke vZergPic, %A_Temp%\Zerg90.png
		
Gui, Tab, Emergency	
	Gui, Font, S16 CDefault bold UNDERLINE, Verdana
	Gui, Add, Text, x+20 y+30 center cRed, IMPORTANT
	Gui, Font, s10 norm 
	Gui, Add, Text, xp y+30 w405, This program blocks user input and simulates keystrokes.`nOn RARE occasions it is possible that you will lose keyboard and mouse input OR a key e.g. ctrl, shift, or alt becomes 'stuck' down.`n`nIn this event, use the EMERGENCY HOTKEY!`nWhen pressed it should release any 'stuck' key and restore user input.`n`nIf this fails, press the hotkey THREE times in quick succession to have the program restart.`nIf you're still having a problem, then the key is likely physically stuck down.
	Gui, Font, S18 CDefault bold, Verdana
	Gui, Add, Text,xp+10 y+25 cRed, Windows Key && Spacebar`n        (Left)
	Gui, Font, norm 
	Gui, Font,

Gui, Add, Tab2, w440 h440 X%MenuTabX%  Y%MenuTabY% vMiniMap_TAB, MiniMap||Overlays|Info

Gui, Tab, MiniMap
	
	Gui, Add, Checkbox, X%XTabX% Y+20 vDrawMiniMap Checked%DrawMiniMap% gG_GuiSetupDrawMiniMapDisable, Enable MiniMap
	Gui, Add, Checkbox, xp+20 Y+10 vDrawSpawningRaces Checked%DrawSpawningRaces%, Display Spawning Races
	Gui, Add, Checkbox, vDrawAlerts Checked%DrawAlerts%, Display Alerts
	Gui, Add, Checkbox, vBlendUnits Checked%BlendUnits%, Blend Units
		
	Gui, add, text, yp+30 X%XTabX%, Exclude Units:

		Gui, add, text, y+15 X%XTabX%, Units:
		Gui, Add, Edit, yp-2 x+10 w300  center r1 vUnitHighlightExcludeList, %UnitHighlightExcludeList%
		Gui, Add, Button, yp-2 x+10 gEdit_AG v#UnitHighlightExcludeList,  Edit 
	
	Gui, add, text, y+20 X%XTabX%, Highlight Units:
		Gui, add, text, y+15 X%XTabX%, Units:
		Gui, Add, Edit, yp-2 x+10 w300 section  center r1 vUnitHighlightList1, %UnitHighlightList1%
		Gui, Add, Button, yp-2 x+10 gEdit_AG v#UnitHighlightList1,  Edit
		Gui, add, text, y+9 X%XTabX%, Colour:
		Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList1Colour v#UnitHighlightList1Colour gColourSelector ;0xE required for GDI
		paintPictureControl(_UnitHighlightList1Colour, UnitHighlightList1Colour)	

		Gui, add, text, y+25 X%XTabX%, Units:
		Gui, Add, Edit, yp-2 x+10 w300  center r1 vUnitHighlightList2, %UnitHighlightList2%
		Gui, Add, Button, yp-2 x+10 gEdit_AG v#UnitHighlightList2,  Edit
		Gui, add, text, y+9 X%XTabX%, Colour:
		Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList2Colour v#UnitHighlightList2Colour gColourSelector ;0xE required for GDI
		paintPictureControl(_UnitHighlightList2Colour, UnitHighlightList2Colour)		
		Gui, add, text, y+25 X%XTabX%, Units:
		Gui, Add, Edit, yp-2 x+10 w300  center r1 vUnitHighlightList3, %UnitHighlightList3%
		Gui, Add, Button, yp-2 x+10 gEdit_AG v#UnitHighlightList3,  Edit
		Gui, add, text, y+9 X%XTabX%, Colour:
		Gui, Add, Picture, xs yp-4 w300 h22 0xE HWND_UnitHighlightList3Colour v#UnitHighlightList3Colour gColourSelector ;0xE required for GDI
		paintPictureControl(_UnitHighlightList3Colour, UnitHighlightList3Colour)
		Gui, Font, s8 
		Gui, add, text, x+5 yp+5, <--- Click Me
		Gui, Font, norm 
	
	
	Gui, Add, Text, Y70 x370, Refresh Rate (ms):
		Gui, Add, Edit, Number Right x+20 yp-2 w55 vTT_MiniMapRefresh
			Gui, Add, UpDown,  Range1-1500 vMiniMapRefresh, %MiniMapRefresh%	
	Gui, Add, Text, x370 yp+30, Hide MiniMap:
	Gui, Add, Edit, Readonly yp-2 xp+80 center w90 vTempHideMiniMapKey gedit_hotkey, %TempHideMiniMapKey%
	Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#TempHideMiniMapKey,  Edit 		
		

Gui, Tab, Overlays
		;Gui, add, text, y+20 X%XTabX%, Display Overlays:
		Gui, Add, GroupBox, y+15 X+5 w170 h165 section, Display Overlays:
		Gui, Add, Checkbox, X%XTabX% yp+30 vDrawIncomeOverlay Checked%DrawIncomeOverlay% , Income Overlay
		Gui, Add, Checkbox, X%XTabX% y+15 vDrawResourcesOverlay Checked%DrawResourcesOverlay% , Resource Overlay
		Gui, Add, Checkbox, X%XTabX% y+15 vDrawArmySizeOverlay Checked%DrawArmySizeOverlay% , Army Size Overlay
		Gui, Add, Checkbox, X%XTabX% y+15 vDrawWorkerOverlay Checked%DrawWorkerOverlay% , Local Harvester Count
		Gui, Add, Checkbox, X%XTabX% y+15 vDrawIdleWorkersOverlay Checked%DrawIdleWorkersOverlay%, Idle Worker Count
		
		Gui, Add, Text, X%XTabX% yp+40, Toggle Income:
		Gui, Add, Edit, Readonly yp-2 xp+120 center w85 vToggleIncomeOverlayKey gedit_hotkey, %ToggleIncomeOverlayKey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleIncomeOverlayKey,  Edit 		
		
		Gui, Add, Text, X%XTabX% yp+35, Toggle Resources:
		Gui, Add, Edit, Readonly yp-2 xp+120 center w85 vToggleResourcesOverlayKey gedit_hotkey, %ToggleResourcesOverlayKey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleResourcesOverlayKey,  Edit 		
		
		Gui, Add, Text, X%XTabX% yp+35, Toggle Army Size:
		Gui, Add, Edit, Readonly yp-2 xp+120 center w85 vToggleArmySizeOverlayKey gedit_hotkey, %ToggleArmySizeOverlayKey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleArmySizeOverlayKey,  Edit 		
		
		Gui, Add, Text, X%XTabX% yp+35, Toggle Workers:
		Gui, Add, Edit, Readonly yp-2 xp+120 center w85 vToggleWorkerOverlayKey gedit_hotkey, %ToggleWorkerOverlayKey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleWorkerOverlayKey,  Edit 		
		
		Gui, Add, Text, X%XTabX% yp+35, Cycle Overlays:
		Gui, Add, Edit, Readonly yp-2 xp+120 center w85 vCycleOverlayKey gedit_hotkey, %CycleOverlayKey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#CycleOverlayKey,  Edit 		
		
		Gui, Add, Text, X%XTabX% yp+35, Cycle Identifier:
		Gui, Add, Edit, Readonly yp-2 xp+120 center w85 vToggleIdentifierKey gedit_hotkey, %ToggleIdentifierKey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#ToggleIdentifierKey,  Edit 		
		gui, font, Underline
		Gui, Add, Text, X%XTabX% yp+35, Move/Resize Overlays:
		gui, font, Norm 
		Gui, Add, Edit, Readonly yp-2 xp+120 center w85 vAdjustOverlayKey gedit_hotkey, %AdjustOverlayKey%
		Gui, Add, Button, yp-2 x+10 gEdit_hotkey v#AdjustOverlayKey,  Edit 
		Gui, Add, Text, x+10 yp+5, * See 'Info' Tab for Instructions
		
		Gui, Add, GroupBox, ys XS+220 w170 h165, Overlays Misc:
		Gui, Add, Checkbox, yp+25 xp+10 vOverlayBackgrounds Checked%OverlayBackgrounds% , Show Icon Background		
		Gui, Add, Text, yp+30 w80, Player Identifier:
		if OverlayIdent in 0,1,2,3
			droplist3_var := OverlayIdent + 1
		Else droplist3_var := 3 
		Gui, Add, DropDownList, xp+20 yp+25 vOverlayIdent Choose%droplist3_var%, Hidden|Name (White)|Name (Coloured)|Coloured Race Icon
		Gui, Add, Text, yp+40 xp-20, Refresh Rate (ms):
			Gui, Add, Edit, Number Right x+5 yp-2 w55 vTT_OverlayRefresh
				Gui, Add, UpDown,  Range1-5000 vOverlayRefresh, %OverlayRefresh%	
		
		
Gui, Tab, Info
	Gui, Font, S11 CDefault bold UNDERLINE, Verdana
	Gui, Add, Text, x+20 y+30 center cRed, How to Move/Resize Overlays:	
	Gui, Font, s10 norm 
text = 
( 
HOLD down (&& do NOT release) the "Move/Resize" Hotkey 
	(Home is the default).
	
You will hear a beep - all the overlays are now adjustable.
 
Moving: Simply left click somewhere on the text or graphics 		of the overlay (not a blank area) and drag the 			overlay to its new position.

Resizing: Simply left click somewhere on the overlay and 			then rotate the mouse wheel forward/backward.

When you're done, release the "Move/Resize" Hotkey. 
You will hear a beep indicating that the new positions have been saved.
)	
	
	Gui, Add, Text, xp y+20 w405, %text%
	Gui, Font, S11 CDefault bold, Verdana
	Gui, Add, Text, xp y+35 w405 center cRed, The MiniMap and Overlays will only work when SC is in 'Windowed (fullscreen)' mode.
	Gui, Font, s10 norm 


		Gui, Font, S18 ;needs to be here for save spacing Im so very lazy!
Gui, Add, Tab2,w440 h440 X%MenuTabX%  Y%MenuTabY%, %A_Space% ;This is never hidden and helps slightly prevent blink on menu change (v. minor thing! lol)
		Gui, Font, s10
		Gui, Add, Button, x+249 y+410 w50 h25 gIni_settings_write, Save
		Gui, Add, Button, x+20 w50 h25 gOptionsGuiClose, Canel
		Gui, Add, Button, x+20 w50 h25 gIni_settings_write, Apply
		Gui, Font, 
	

	 
unhidden_menu := "Home_TAB"

GuiControl, Hide, Home_TAB 
GuiControl, Hide, Injects_TAB 
GuiControl, Hide, AutoGroup_TAB 
GuiControl, Hide, Chrono_Gate_TAB 
GuiControl, Hide, AutoMine_TAB 
GuiControl, Hide, MiscAutomation_TAB 
GuiControl, Hide, Keys_TAB
GuiControl, Hide, Warnings_TAB
GuiControl, Hide, Misc_TAB 
GuiControl, Hide, Volume_TAB
GuiControl, Hide, Detection_TAB
GuiControl, Hide, Settings_TAB
GuiControl, Hide, Bug_TAB
GuiControl, Hide, MiniMap_TAB

ZergPic_TT := "The OP race"
TerranPic_TT := "The artist formerly known as being OP"
ProtossPic_TT := "The slightly less OP race"
auto_inject_alert_TT := "This alert will sound X seconds after your last auto inject, prompting you to inject again."
auto_inject_time_TT := "This is in 'SC2' Seconds."
#cast_inject_key_TT := cast_inject_key_TT := "This Hotkey is ONLY active while playing as zerg!"
Auto_inject_sleep_TT := "Lower this to make the inject round faster, BUT this will make it more obvious that it is being automated!"
Simulation_speed_TT := "How fast the mouse moves during inject rounds. 0 = Fastest - try 1,2 or 3 if you're having problems."
Drag_origin_TT := "This sets the origin of the box drag to the top left or right corners. Hence making it compatible with observer panel hacks."
manual_inject_time_TT := "The time between alerts."
inject_start_key_TT := "The hotkey used to start or stop the timer."
inject_reset_key_TT := "The hotkey used to reset (or start) the timer."
Alert_List_Editor_TT := "Use this to edit and create alerts for any SC2 unit or building."
#base_camera_TT := base_camera_TT := "The key used to cycle between hatcheries/bases."
#control_group_TT := control_group_TT := "Set this to a control group you DON'T use - It stores your unit selection during an inject round."
create_camera_pos_x_TT := #create_camera_pos_x_TT := "The hotkey used to 'save' a camera location. - Ensure this isn't one you use."
#camera_pos_x_TT := camera_pos_x_TT := "The hotkey associated with the 'create/save' camera location above."
spawn_larva_TT := #spawn_larva_TT := Tspawn_larva_TT := "Please set the key or alternate key for ""spawn larvae"" in SC2 to "" e "". - This prevents problems!"
sub_lowerdelta_TT := "A warning will be heard when the 'free' supply drops below this number. (while your supply is below the 'Low Range Cutoff')."
sub_middelta_TT := "A warning will be heard when the 'free' supply drops below this number. (While your supply is greater than the 'Low Range Cutoff' but less than the 'Middle Range Cutoff')."
sub_upperdelta_TT := "A warning will be heard when the 'free' supply drops below this number. (While your supply is greater than the 'Middle Range Cutoff' but less than the 'Upper Range Cutoff')."
above_upperdelta_TT := "A warning will be heard when the 'free' supply drops below this number. (While your supply is greater than the 'Upper Range Cutoff')."
minimum_supply_TT := "Alerts are only active while your supply is above this number."

w_supply_TT := w_warpgate_TT := w_workerprod_T_TT := w_workerprod_P_TT := w_workerprod_Z_TT := w_gas_TT := w_idle_TT := w_mineral_TT := "This text is spoken during a warning."
TT_sec_workerprod_TT := sec_warpgate_TT := sec_workerprod_TT := sec_idle_TT := sec_gas_TT := sec_mineral_TT := sec_supply_TT := "Set how many additional warnings are to be given after the first initial warning (assuming the resource does not fall below the inciting value) - the warnings then turn off."
additional_delay_supply_TT := additional_delay_minerals_TT := additional_delay_gas_TT := additional_idle_workers_TT := "This sets the delay between the initial warning, and the additional/follow-up warnings. (in real seconds)"
TT_additional_delay_worker_production_TT := additional_delay_worker_production_TT := "This sets the delay between the initial warning, and the additional/follow-up warnings. (in SC2 seconds)"
TT_workerproduction_time_TT := workerproduction_time_TT := "This only applies to Zerg.`nA warning will be heard if a drone has not been produced in this amount of time (SC2 seconds)."
delay_warpgate_warn_TT := "If a gateway has been unconverted for this period of time (real seconds) then a warning will be made."
warpgate_warn_on_TT := "Enables warnings for unconverted gateways. Note: The warnings become active after your first gateway is converted."
idletrigger_TT := gas_trigger_TT := mineraltrigger_TT := "The required amount to invoke a warning."
supplylower_TT := supplymid_TT := supplyupper_TT := "Dictactes when the next or previous supply delta/threashold is used."
TT_workerProductionTPIdle_TT := workerProductionTPIdle_TT := "This only applies to Terran & protoss.`nIf all nexi/CC/Orbitals/PFs are idle for this amount of time (SC2 seconds), a warning will be made.`n`nNote: A main is considered idle if it has no worker in production and is not currently flying or morphing."

worker_count_local_key_TT := "This will read aloud your current worker count."
worker_count_enemy_key_TT := "This will read aloud your enemy's worker count. (only in 1v1)"
warning_toggle_key_TT := "Pauses and resumes the program."
ping_key_TT := "This hotkey will ping the map at the current mouse cursor location."
race_reading_TT := "Reads aloud the enemys' spawning races."
idle_enable_TT := "If the user has been idle for longer than a set period of time (real seconds) then the game will be paused."
TTidle_time_TT := idle_time_TT := "How long the user must be idle for (in real seconds) before the game is paused.`nNote: This value can be higher than the ""Don't Pause After"" parameter!"
TTUserIdle_LoLimit_TT  := UserIdle_LoLimit_TT := "The game can't be paused before this (in game/SC2) time."
TTUserIdle_HiLimit_TT := UserIdle_HiLimit_TT := "The game will not be paused after this (in game/SC2) time."

speech_volume_TT := "The relative volume of the speech engine."
overall_program_TT := "The overall program volume. This affects both the speech volume and the 'beeps'."
speaker_volume_up_key_TT := speaker_volume_down_key_TT := "Changes the windows master volume."
speech_volume_down_key_TT := speech_volume_up_key_TT := "Changes the programs TTS volume."
program_volume_up_key_TT := program_volume_down_key_TT := "Changes the programs overall volume."
input_method_TT := "Sets the method of artificial input.`n""Event"" is the most 'reliable' across systems, but ""Input"" offers better performance and key buffering.`n Hence, use ""Input"" if it works."

auto_check_updates_TT := "While enabled the program will automatically check for new versions during startup."
launch_settings_TT := "Display the options menu on startup."

HideTrayIcon_TT := "Hides the tray icon and all popups/menus."
exit_hotkey_TT := "Can be used to exit the program while stealth mode is enabled."
TT2_MI_QueenDistance_TT := MI_QueenDistance_TT := "The edge of the hatchery creep is approximately 14`nThis helps prevent queens injecting on remote hatches - It works better with lower numbers"
TT_F_Max_Injects_TT := F_Max_Injects_TT := "The max. number of 'forced' injects which can occur after a user 'F5'/auto-inject.`nSet this to a high number if you want the program to inject for you."
TT_F_Alert_PreTime_TT := F_Alert_PreTime_TT := "The alert will sound X seconds before the forced inject."
TT_F_Sleep_Time_TT := F_Sleep_Time_TT := "The amount of time between injecting each hatch.`nThis should be set as low as reliably possible so that the inject rounds are shorter and there is less chance of it affecting your gameplay."
TT_AM_KeyDelay_TT := AM_KeyDelay_TT := TT_I_KeyDelay_TT := I_KeyDelay_TT := TT_CG_KeyDelay_TT := CG_KeyDelay_TT := "This sets the delay between key/mouse events`nLower numbers are faster, but they may cause problems.`n0-10`n`nWith regards to speed, changing the 'sleep' time will generally have a larger impact."
TT_Chrono_Gate_Sleep_TT := Chrono_Gate_Sleep_TT  := Auto_inject_sleep_TT := Edit_pos_var_TT := Auto_Mine_Sleep2_TT := TT_Auto_Mine_Sleep2_TT := "Sets the amount of time that the program sleeps for during each automation cycle.`nThis has a large effect on the speed, and hence how 'human' the automation appears'."
CG_chrono_remainder_TT := TT_CG_chrono_remainder_TT := "This is how many full chronoboosts will remain afterwards between all your nexi.`nA setting of 1 will leave 1 full chronoboost (or 25 energy) on one of your nexi."
CG_control_group_TT := Inject_control_group_TT := #CG_control_group_TT := #Inject_control_group_TT := "This stores the currently selected units into a temporary control group, so that the current unit selection may be restored after the automated cycle.`nNote: Ensure that this is set to a control group you do not use."
WorkerSplitType_TT := "Defines how many workers are rallied to each mineral patch."

AM_MiniMap_PixelColourAlpha_TT := AM_MiniMap_PixelColourRed_TT := AM_MiniMap_PixelColourGreen_TT := AM_MinsiMap_PixelColourBlue_TT := "The ARGB pixel colour of the mini map mineral field."
#ResetPixelColour_TT := "Resets the pixel colour and variance to their default settings."
#FindPixelColour_TT := "This sets the pixel colour for your exact system."
AM_MiniMap_PixelVariance_TT := TT_AM_MiniMap_PixelVariance_TT := "A match will result if  a pixel's colour lies within the +/- variance range.`n`nThis is a percent value 0-100%"
TT_AGDelay_TT := AG_Delay_TT := "The program will wait this period of time before adding the select units to a control group.`nUse this if you want the function to look more 'human'.`n`nNote: An additional delay of up to 15ms is always present (even when set to 0)."
TempHideMiniMapKey_TT := #TempHideMiniMapKey_TT := "This will temporarily disable the minimap overlay,`nthereby allowing you to determine if you have seen a unit or building legitimately."
TT_UserMiniMapXScale_TT := TT_UserMiniMapYScale_TT := UserMiniMapYScale_TT := UserMiniMapXScale_TT := "Adjusts the relative size of units on the minimap."
TT_MiniMapRefresh_TT := MiniMapRefresh_TT := "Dictates how frequently the minimap is redrawn"
BlendUnits_TT := "This will draw the units 'blended together', like SC2 does.`nIn other words, units/buildings grouped together will only have one border around all of them"


SleepSplitUnit_TT := TT_SleepSplitUnits_TT := TT_SleepSelectArmy_TT := SleepSelectArmy_TT := "Increase this value if the function doesn't work properly`nTime between deselecting Units."
Sc2SelectArmy_Key_TT := #Sc2SelectArmy_Key_TT := "The in game (SC2) button used to select your entire army.`nDefault is F2"
ModifierBeepSelectArmy_TT := "Will play a beep if a modifer key is being held down.`nModifiers include the ctrl, alt, shift and windows keys."
castSelectArmy_key_TT := #castSelectArmy_key_TT := "The button used to invoke this function."
SelectArmyDeselectXelnaga_TT := "Units controlling the xelnaga watch towers will be removed from the selection group."
SelectArmyDeselectPatrolling_TT := "Patrolling units will be removed from the selection group.`nThis is very useful if you dont want to select some units e.g. banes/lings at your base or a drop ship waiting outside a base!`nJust set them to patrol and they will not be selected with your army.`n`n**Note:Units set to follow (and are moving) will also me removed."
SelectArmyDeselectHoldPosition_TT := "Units on hold position will be removed from the selection group."
SelectArmyDeselectFollowing_TT := "Units on a follow command will be removed from the selection group."

castSplitUnit_key_TT := #castSplitUnit_key_TT := "The hotkey used to invoke this function."
SplitctrlgroupStorage_key_TT := #SplitctrlgroupStorage_key_TT := "This ctrl group is used during the function.`nAssign it to a control group you DON'T use!"
DeselectSleepTime_TT := "Time between deselecting units from the unit panel.`nThis is used by the split and select army, and deselect unit functions"

#Sc2SelectArmyCtrlGroup_TT := Sc2SelectArmyCtrlGroup_TT := "The control Group (key) in which to store the army.`nE.G. 1,2,3-0"
l_DeselectArmy_TT := #l_DeselectArmy_TT := "These unit types will be deselected."

F_Inject_ModifierBeep_TT := "If the modifier keys (Shift, Ctrl, or Alt) or Windows Keys are held down when an Inject is attempted, a beep will heard.`nRegardless of this setting, the inject round will not begin until after these keys have been released."
BlockingStandard_TT := BlockingFunctional_TT := BlockingNumpad_TT := BlockingMouseKeys_TT := BlockingMultimedia_TT := BlockingMultimedia_TT := BlockingModifier_TT := "During certain automations these keys will be buffered or blocked to prevent interruption to the automation and your game play."

#UnitHighlightList1Colour_TT := #UnitHighlightList2Colour_TT := #UnitHighlightList3Colour_TT := "Click Me!`n`nUnits of this type will appear this colour."
Short_Race_List := "Terr|Prot|Zerg"
loop, parse, l_races, `,
	while (10 > i := A_index-1)
		LG_%A_LoopField%%i%_TT := "Only the specified units below can be bound to their respective control groups.`nAny unit can be grouped to a blank group.`nThis can be used with or without 'Auto Grouping'."

	loop, parse, Short_Race_List, |
	AG_Enable_%A_LoopField%_TT := "Selected units will be automatically added to their set control groups."


OnMessage(0x200, "WM_MOUSEMOVE")
GuI, Options:Show, w615 h485, Macro Trainer V%version% Settings
Return

HumanMouseWarning:
	GuiControlGet, Checked, ,HumanMouse 
	if Checked
		msgbox, 16, Human Mouse Movement Warning, The only reason to possibly use this setting, is if you are streaming your games and want your viewers to think you're legit.`n`nThis affects injects and chronoboost movements.`nThis setting moves the mouse in a somewhat random arc/line.`n`nThe 'Time' setting dictates the duration of each individual mouse movement. For each movement, a random move time is generated using the upper and lower time bounds.`n`nI repeat DO NOT USE this unless you're a streamer! It offers no advantages!
Return
g_GuiSetupDrawMiniMapDisable:
	GuiControlGet, Checked, ,DrawMiniMap 
	if !Checked
	{	GUIControl, Disable, DrawSpawningRaces
		GUIControl, Disable, DrawAlerts		
		GUIControl, Disable, UnitHighlightExcludeList
		GUIControl, Disable, #UnitHighlightExcludeList
		GUIControl, Disable, UnitHighlightList1
		GUIControl, Disable, #UnitHighlightList1
		GUIControl, Disable, UnitHighlightList2
		GUIControl, Disable, #UnitHighlightList2
	}
	Else
	{	GUIControl, Enable, DrawSpawningRaces
		GUIControl, Enable, DrawAlerts
		GUIControl, Enable, UnitHighlightExcludeList
		GUIControl, Enable, #UnitHighlightExcludeList
		GUIControl, Enable, UnitHighlightList1
		GUIControl, Enable, #UnitHighlightList1
		GUIControl, Enable, UnitHighlightList2
		GUIControl, Enable, #UnitHighlightList2
	}
Return	
g_GuiSetupResetPixelColour:
	guicontrol, Options:, AM_MiniMap_PixelColourAlpha, 255
	guicontrol, Options:, AM_MiniMap_PixelColourRed, 126
	guicontrol, Options:, AM_MiniMap_PixelColourGreen, 191
	guicontrol, Options:, AM_MinsiMap_PixelColourBlue, 241
	guicontrol, Options:, AM_MiniMap_PixelVariance, 0
return

g_GuiSetupAutoMine:
	GuiControlGet, Item, ,AutoMineMethod 
	if (item = "Normal")
		state := 1
	else state := 0
	l_control = AMGUI1,AMGUI2,AMGUI3,AMGUI4,AMGUI5,AMGUI6,AMGUI7,AMGUI8,AM_MiniMap_PixelColourAlpha,AM_MiniMap_PixelColourRed,AM_MiniMap_PixelColourGreen,AM_MinsiMap_PixelColourBlue,#ResetPixelColour,#FindPixelColour,AM_MiniMap_PixelVariance,TT_AM_MiniMap_PixelVariance
	loop, parse, l_control, `,
		GuiControl, Hide%state%, %A_LoopField%
return
	

P_Protoss_Joke:	
	DSpeak("Baby's first Race.")
	return
P_Terran_Joke:	
	DSpeak("The defenders of freedom and all round good guys")
	return
P_zerg_Joke:
	DSpeak("The OPee Race")
	return	

B_HelpFile:
	IfWinExist, MT Help File
	{	WinActivate
		Return 					
	}
	Gui, New 
	Gui Add, ActiveX, xm w980 h640 vWB, Shell.Explorer
	WB.Navigate(url.HelpFile)
	Gui, Show,, MT Help File
	Return
	

B_ChangeLog:
	IfWinExist, ChangeLog Vr: %version%
	{
		WinActivate
		Return 									
	}
	Gui, New 
	Gui Add, ActiveX, xm w980 h640 vWB, Shell.Explorer
	WB.Navigate(url.changelog)
	Gui, Show,,ChangeLog Vr: %version%
Return
	
B_Report:
	GuiControlGet, Report_Email,
	GuiControlGet, Report_TXT,
	R_check:= ltrim(Report_TXT, "`n `t") ;remove tabs and new lines (and spaces)
	R_length := StrLen(R_check)
	if (R_check = "")
		msgbox, 48, Why Spam?, You didn't write anything.`nPlease don't spam this function.
	Else if ( R_length < 18 )
		msgbox, 32, Don't Spam, Please provide more information.
	Else
	{
		GuiControl, Disable, B_Report
		SendEmail("Macro.Trainer@gmail.com", "Bug Report", "Return Email: " Report_Email "`n" "Problem: `n`n" Report_TXT )
		msgbox, 64, , Report Sent, 10
		GuiControl, ,Report_Email,
		GuiControl, ,Report_TXT, `n`n`n`n`n`n%a_tab%%a_tab%Thank You!
	}
	return

OptionsTree:
	TV_GetText(Menu_TXT, TV_GetSelection())
	;could hide everything each time, then unhide once, but that causes every so slightly more blinking on gui changes
	GUIcontrol, Hide, %unhidden_menu%
	IF ( Menu_TXT = "Home" )
	{
		GUIcontrol, Show, Home_TAB
		unhidden_menu := "Home_TAB"
	}
	ELSE IF ( Menu_TXT = "Detection List" )
	{
		GUIcontrol, Show, Detection_TAB
		unhidden_menu := "Detection_TAB"
	}	
	ELSE IF ( Menu_TXT = "MiniMap/Overlays" )
	{
		GUIcontrol, Show, MiniMap_TAB
		unhidden_menu := "MiniMap_TAB"
	}
	ELSE IF ( Menu_TXT = "Injects" )
	{
		GUIcontrol, Show, Injects_TAB
		unhidden_menu := "Injects_TAB"
	}	
	ELSE IF ( Menu_TXT = "Unit Grouping" )
	{
		GUIcontrol, Show, AutoGroup_TAB
		unhidden_menu := "AutoGroup_TAB"
	}
	ELSE IF ( Menu_TXT = "Chrono Boost" )
	{
		GUIcontrol, Show, Chrono_Gate_TAB
		unhidden_menu := "Chrono_Gate_TAB"
	}
	ELSE IF ( Menu_TXT = "Auto Mine" )
	{
		GUIcontrol, Show, AutoMine_TAB
		unhidden_menu := "AutoMine_TAB"
	}	
	ELSE IF ( Menu_TXT = "Misc Automation" )
	{
		GUIcontrol, Show, MiscAutomation_TAB
		unhidden_menu := "MiscAutomation_TAB"
	}
	ELSE IF ( Menu_TXT = "SC2 Keys" )
	{
		GUIcontrol, Show, Keys_TAB
		unhidden_menu := "Keys_TAB"
	}	
	ELSE IF ( Menu_TXT = "Warnings" )
	{
		GUIcontrol, Show, Warnings_TAB
		unhidden_menu := "Warnings_TAB"
	}
	ELSE IF ( Menu_TXT = "Misc Abilities" )
	{
		GUIcontrol, Show, Misc_TAB 
		unhidden_menu := "Misc_TAB"
	}
	ELSE IF ( Menu_TXT = "Volume" )
	{
		GUIcontrol, Show, Volume_TAB
		unhidden_menu := "Volume_TAB"
	}	
	ELSE IF ( Menu_TXT = "Settings" )
	{
		GUIcontrol, Show, Settings_TAB
		unhidden_menu := "Settings_TAB"
	}	
	ELSE IF ( Menu_TXT = "Report Bug" )
	{
		GUIcontrol, Show, Bug_TAB
		unhidden_menu := "Bug_TAB"
	}
	Else	RETURN
 	Return
 	

Test_VOL:
	original_overall_program := overall_program
	original_speech_volume := speech_volume
	GuiControlGet, TmpSpeechVol,, speech_volume
	speech_volume:= TmpSpeechVol := Round(TmpSpeechVol, 0)
	GuiControlGet, TmpTotalVolume,, overall_program
	overall_program := Round(TmpTotalVolume, 0)
	
	If ( A_GuiControl = "Test_VOL_All")
	{
		SoundSet, overall_program
		loop, 2
		{
			SoundPlay, %A_Temp%\Windows Ding.wav  ;SoundPlay *-1
			sleep 150
		}
	}	
	SAPI.volume := TmpSpeechVol
	;Random, Rand_joke, 1, 8
	Rand_joke ++
	If ( Rand_joke = 1 )
		DSpeak("Protoss is OPee")
	Else If ( Rand_joke = 2 )
		DSpeak("A templar comes back to base with a terrified look on his face. The zealots asks - what happened? You look like you've seen a ghost")
	Else If ( Rand_joke = 3 )
	{
	
		DSpeak("A Three Three Protoss army walks into a bar and asks")
		sleep 50
		DSpeak("Where is the counter?")
	}
	Else If ( Rand_joke = 4 )
	{
		DSpeak("What computer does IdrA use?")
		sleep 1000
		DSpeak("An EYE BM")
	}
	Else If ( Rand_joke = 5 )
	{
		DSpeak("Why did the Cullosus fall over ?")
		sleep 1000
		DSpeak("because it was imbalanced ")
	}
	Else If ( Rand_joke = 6 )
	{
		DSpeak("How many Zealots does it take to change a lightbulb?")
		sleep 1000
		DSpeak("None, as they cannot hold")	
	}
	Else If ( Rand_joke = 7 )
	{
		DSpeak("How many Infestors does it take to change a lightbulb?")
		sleep 1000
		DSpeak("One, you just have to make sure he doesn't over-power it")	
	}
	Else
	{
		DSpeak("How many members of the Starcraft 2 balance team does it take to change a lightbulb?")
		sleep 1000
		DSpeak("All three of them, and Ten patches")	
		rand_joke := 0
	}
	overall_program := original_overall_program
	speech_volume := original_speech_volume
	SoundSet, %overall_program%
	SAPI.volume := speech_volume
return

Edit_SendHotkey:
	if (SubStr(A_GuiControl, 1, 1) = "#") ;this is a method to prevent launching 
	{
		hotkey_name := SubStr(A_GuiControl, 2)	;this label (and sendgui) for a 2nd time 
		hotkey_var := SendGUI("Options",%hotkey_name%,,,"Select Key:   " hotkey_name) ;the hotkey
		if (hotkey_var <> "")
			GUIControl,, %hotkey_name%, %hotkey_var%
	}
Return

edit_hotkey:
	if (SubStr(A_GuiControl, 1, 1) = "#") ;this is a method to prevent launching 
	{
		hotkey_name := SubStr(A_GuiControl, 2)	;this label (and hotkeygui) for a 2nd time 
		if (hotkey_name = "AdjustOverlayKey")		
			hotkey_var := HotkeyGUI("Options",%hotkey_name%,2046,True, "Select Hotkey:   " hotkey_name)  ;as due to toggle keywait cant use modifiers
		Else hotkey_var := HotkeyGUI("Options",%hotkey_name%,,True, "Select Hotkey:   " hotkey_name) ;the hotkey
		if (hotkey_var <> "")
			GUIControl,, %hotkey_name%, %hotkey_var%
	}
return


Alert_List_Editor:
Gui, New 
alert_array := [] ; [1v1, unit#, parameter] - [A_LoopField, "list", "size"] alert_array[A_LoopField, "list", "size"] := temp_count
alert_list_fields :=  "Name,DWB,DWA,Repeat,Code"
SetupUnitIDArray(A_unitID)
gosub iniread_alert_list
Gui -MaximizeBox
Gui, Add, GroupBox,  w220 h370 section, Current Detection List
Gui, Add, TreeView, xp+20 yp+20 gMyTree r20 w180

loop, parse, l_GameType, `,
{
	p%A_Index% := TV_Add(A_LoopField)	;p1 = 1v1, p2 =2v2 etc	
	P# := A_Index 						;set var p# for inner loop	
	loop, % alert_array[A_LoopField, "list", "size"]				;loop their names
	{
		p_LvL_2 = p%P#%c%A_Index%							;child number
		%p_LvL_2% := TV_Add(alert_array[A_LoopField, A_Index, "Name"], p%P#%)	;building name
	}			
}

Gui, Add, GroupBox, ys x+30 w245 h185 vOriginTabRAL, Parameters
GuiControlGet, OriginTabRAL, Pos
	Gui, Add, Text,xp+10 yp+20 section, Name/Warning:
	Gui, Add, Text,y+10 w80, Don't Warn if Exists Before (s):
	Gui, Add, Text,y+10 w80, Don't Warn if Made After (s):
	Gui, Add, Text,y+12, Repeat on New?
	Gui, Add, Text,y+16, ID Code:
	
	Gui, Add, Edit, Right ys xs+85 section w135 vEdit_Name	
	Gui, Add, Edit, Number Right y+11 w135 
		Gui, Add, UpDown,  Range0-100000 vEdit_DWB, 0
	Gui, Add, Edit, Number Right y+11 w135
		Gui, Add, UpDown,  Range1-100000 vEdit_DWA, 54000

	Gui, Add, DropDownList, xs+90  y+8 w45 right VEdit_RON, Yes||No|	
	DetectionUnitListNames := 	"ID List||" l_UnitNames	;get the ID List Txt first in the shared list
	Gui, Add, DropDownList, xs y+10 w135 Vdrop_ID sort, %DetectionUnitListNames%

Gui, Add, GroupBox, y+30 x%OriginTabRALX% w245 h175, Alert Submission	
	Gui, Add, Button, xp+10 yp+20 w225 section vB_Modify_Alert gB_Modify_Alert, Modify Alert
	Gui, Add, Text,xs ys+27 w225 center, OR
	Gui, Add, Button, xs y+5 w225 section gDelete_Alert vB_Delete_Alert Center, Delete Alert
	gui, Add, Text, Readonly yp+5 x+15 w90 center vCurrent_Selected_Alert2, `n`n
	Gui, Add, Text,xs ys+27 w225 center, OR
	
Gui, Add, GroupBox, y+5 xs-5 w235 h55 section, New Alert	
	Gui, Add, Button, xs+5 yp+20 w120 vB_Add_New_Alert gB_Add_New_Alert, Add This Alert to List
	Gui, Add, Checkbox, checked x+10 yp-5 section vC_Add_1v1, 1v1
	Gui, Add, Checkbox, checked x+10 vC_Add_3v3, 3v3
	Gui, Add, Checkbox, checked yp+20 vC_Add_4v4, 4v4
	Gui, Add, Checkbox, checked xs yp vC_Add_2v2, 2v2

Gui, Add, Button, xp-100 y+30 vB_ALert_Cancel gGuiClose w100 h50, Cancel
Gui, Add, Button, xp-200 yp vB_ALert_Save gB_ALert_Save w100 h50, Save Changes
	
Gui, Show, w490 h455  ; Show the window and its TreeView.
OnMessage(0x200, "WM_MOUSEMOVE")

	Edit_Name_TT := "This text is read aload during the warning"
	Edit_DWB_TT := "If the unit/building exists before this time, no warning will be made - this is helpful for creating multiple warnings for the same unit"
	Edit_DWA_TT := "If the unit is made after this time, no warning will be made -  this is helpful for creating multiple warnings for the same unit"
	Edit_RON_TT := "If ''Yes'' this SPECIFIC warning will be heard for each new unit/building (of this type)."
	Edit_ID_TT := "This value is used to identify buildings and units within SC2 (the list below can be used)"
	drop_ID_TT := "Use this list to find a units ID"
	B_Modify_Alert_TT := "This updates the currently selected alert with the above parameters."
	Delete_Alert_TT := "Removes the currently selected alert."
	B_Add_New_Alert_TT := "Creates an alert using the above parameters for the selected game modes."
	B_ALert_Cancel_TT := "Disregard changes"
;	B_ALert_Save_TT := "This will save any changes made"
return

Drop_ID:
	GuiControlGet, Edit_Unit_name,, drop_ID ;get txt of selection
	Edit_ID := A_unitID[Edit_Unit_name]	;look up the associated ID by unit Title
	GUIControl,, Edit_ID, %Edit_ID%	;set the edit box
return

Delete_Alert:
	TV_item := TV_CountP()
	TV_GetText(GameTypeTV,TV_GetParent(TV_GetSelection()))
	del_correction := alert_array[GameTypeTV, "list", "size"] - TV_item
	loop, parse, alert_list_fields, `, ;comma is the separator
	{
		loop, % del_correction
		{
			TV_item_next := TV_item + A_Index
			TV_item_previous := TV_item_next - 1
			
			alert_array[GameTypeTV, TV_item_previous, A_LoopField] :=  alert_array[GameTypeTV, TV_item_next, A_LoopField]	;copy data back 1 space
			if ( (A_Index + TV_item) = alert_array[GameTypeTV, "list", "size"])
			{
				alert_array[GameTypeTV, alert_array[GameTypeTV, "list", "size"], A_LoopField] := ""
				Break
			}
		}
	}
	alert_array[GameTypeTV, "list", "size"] -= 1	;decrease list size by 1
	TV_Delete(TV_GetSelection())
	GUIControl,, B_Delete_Alert, Delete Alert - %GameTypeTV% %ItemTxt% ;update tne name on button
	GUIControl,, B_Modify_Alert, Modify Alert - %GameTypeTV% %ItemTxt%
	
Return

B_Modify_Alert:

	Gui, Submit, NoHide
	if ( Edit_Name = "" OR Edit_DWB = "" OR Edit_DWA = "" OR  drop_ID = "ID List" ) ; Edit_RON cant be blank
		MsgBox Blank parameters are not acceptable.
	Else
	{
		TV_item := TV_CountP()
		TV_GetText(GameTypeTV,TV_GetParent(TV_GetSelection()))
		TV_Modify(TV_GetSelection(), %Space%, Edit_Name) ; update name in tree view - %Space% workaround for blank option bug
		alert_array[GameTypeTV, TV_item, "Name"] := Edit_Name
		alert_array[GameTypeTV, TV_item, "DWB"] := Edit_DWB
		alert_array[GameTypeTV, TV_item, "DWA"] := Edit_DWA
		if (Edit_RON = "Yes")
			alert_array[GameTypeTV, TV_item, "Repeat"] := 1
		Else alert_array[GameTypeTV, TV_item, "Repeat"] := 0
		alert_array[GameTypeTV, TV_item, "IDName"] := drop_ID	
	}
	Return
  
B_Add_New_Alert:
	Gui, Submit, NoHide
	if ( Edit_Name = "" OR Edit_DWB = "" OR Edit_DWA = "" OR  drop_ID = "ID List" ) ; Edit_RON cant be blank
		MsgBox Blank parameters are not acceptable.
	Else if ((C_Add_1v1 + C_Add_2v2 + C_Add_3v3 + C_Add_4v4) = 0)
		msgbox You must select at least one game mode. 
	Else
	{
		Add_to_GameType := []
		loop, parse, l_GameType, `,
		{
			if C_Add_%A_LoopField%
				Add_to_GameType[A_Index] := A_LoopField
		}

		For index, game_mode in Add_to_GameType
		{	
			New_Item_Pos := alert_array[game_mode, "list", "size"] += 1
			alert_array[game_mode, New_Item_Pos, "Name"] := Edit_Name
			alert_array[game_mode, New_Item_Pos, "DWB"] := Edit_DWB
			alert_array[game_mode, New_Item_Pos, "DWA"] := Edit_DWA
			if (Edit_RON = "Yes")
				alert_array[game_mode, New_Item_Pos, "Repeat"] := 1
			Else alert_array[game_mode, New_Item_Pos, "Repeat"] := 0
			alert_array[game_mode, New_Item_Pos, "IDName"] := drop_ID	
		
			loop, parse, l_GameType, `, ; 1s,2s,3s,4s
			{		
				if ( game_mode = A_LoopField )
					TV_Add(Edit_Name, p%a_index%) ; TV p1 = 1v1, p2 =2v2 etc
			}	
		}
	}
	Return


MyTree:
	TV_GetText(GameTypeTV,TV_GetParent(TV_GetSelection()))
	If (GameTypeTV = "1v1" or GameTypeTV = "2v2" or GameTypeTV = "3v3" or GameTypeTV = "4v4" or GameTypeTV = "FFA") ;your in the unit name/list
	{
		GUIControl, Enable, B_Delete_Alert
		GUIControl, Enable, B_Modify_Alert
		ItemID := TV_GetChild(TV_GetParent(TV_GetSelection()))
		TV_GetText(ItemTxt, (TV_GetSelection()))
		Count_TVItem := 0, OutputTxt := "" ;blank OutputTxt to prevent error when clicking on unit with same name in different gamemode list
		Loop
		{
			If (ItemID = 0 OR ItemTxt = OutputTxt) ; No more items in tree. (FUNCTIONS RETURNS 0 LAST ONE)
				break
			TV_GetText(OutputTxt, ItemID)
			ItemID := TV_GetNext(ItemID)
			Count_TVItem ++
		}
		GUIControl,, Edit_Name,% alert_array[GameTypeTV, Count_TVItem, "Name"]

		GUIControl,, Edit_DWB,% alert_array[GameTypeTV, Count_TVItem, "DWB"]
		GUIControl,, Edit_DWA,% alert_array[GameTypeTV, Count_TVItem, "DWA"]
		if (alert_array[GameTypeTV, Count_TVItem, "Repeat"])
			GUIControl, ChooseString, Edit_RON, Yes
		Else GUIControl, ChooseString, Edit_RON, No
		GUIControl,, Edit_ID,% alert_array[GameTypeTV, Count_TVItem, "IDName"]
		GUIControl,ChooseString, drop_ID, % alert_array[GameTypeTV, Count_TVItem, "IDName"]
		GUIControl,, B_Delete_Alert, Delete Alert - %GameTypeTV% %ItemTxt%
		GUIControl,, B_Modify_Alert, Modify Alert - %GameTypeTV% %ItemTxt%

	}
	Else ; youre in the gamemode part of the list
	{
		GUIControl,, B_Delete_Alert, Delete Alert
		GUIControl,, B_Modify_Alert, Modify Alert
		GUIControl, Disable, B_Delete_Alert
		GUIControl, Disable, B_Modify_Alert
		
	}
	return
Alert_Array_General_Write: ; I.e. coming from general ini write not alert list editor
B_ALert_Save:
	loop, parse, l_GameType, `, 
	{
		IniDelete, %config_file%, Building & Unit Alert %A_LoopField% ;clear the list - prevent problems if now have less keys than b4
		IniWrite, % alert_array[A_LoopField, "Enabled"], %config_file%, Building & Unit Alert %A_LoopField%, enable	;alert system on/off
		IniWrite, % alert_array[A_LoopField, "Clipboard"], %config_file%, Building & Unit Alert %A_LoopField%, copy2clipboard
		loop, % alert_array[A_LoopField, "list", "size"]  ;loop 1v1 etc units
		{
			IniWrite, % alert_array[A_LoopField, A_Index, "Name"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_name_warning
			Iniwrite, % alert_array[A_LoopField, A_Index, "DWB"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_Dont_Warn_Before_Time
			IniWrite, % alert_array[A_LoopField, A_Index, "DWA"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_Dont_Warn_After_Time
			IniWrite, % alert_array[A_LoopField, A_Index, "Repeat"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_repeat_on_new
			IniWrite, % alert_array[A_LoopField, A_Index, "IDName"], %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_IDName
		}
	}
	If (A_ThisLabel <> "Alert_Array_General_Write")
		Gui, Destroy
Return

iniread_alert_list:
	alert_array := [] ; [1v1, unit#, parameter] - [A_LoopField, "list", "size"] alert_array[A_LoopField, "list", "size"]
	loop, parse, l_GameType, `, ;comma is the separator
	{
		IniRead, BAS_on_%A_LoopField%, %config_file%, Building & Unit Alert %A_LoopField%, enable, 1	;alert system on/off
		IniRead, BAS_copy2clipboard_%A_LoopField%, %config_file%, Building & Unit Alert %A_LoopField%, copy2clipboard, 1
		alert_array[A_LoopField, "Enabled"] := BAS_on_%A_LoopField% ;this style name, so it matches variable name for update
		alert_array[A_LoopField, "Clipboard"] := BAS_copy2clipboard_%A_LoopField%
		loop,	;loop thru the building list sequentialy
		{
			IniRead, temp_name, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_name_warning
			if (  temp_name = "ERROR" ) ;ERROR default return
			{
				alert_array[A_LoopField, "list", "size"] := A_Index-1
				break	
			}
			IniRead, temp_DWB, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_Dont_Warn_Before_Time, 0 ;get around having blank keys in ini)=
			IniRead, temp_DWA, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_Dont_Warn_After_Time, 54000 ;15 hours - get around having blank keys in ini		
			IniRead, Temp_repeat, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_repeat_on_new, 0
			IniRead, Temp_IDName, %config_file%, Building & Unit Alert %A_LoopField%, %A_Index%_IDName
			alert_array[A_LoopField, A_Index, "Name"] := temp_name
			alert_array[A_LoopField, A_Index, "DWB"] := temp_DWB
			alert_array[A_LoopField, A_Index, "DWA"] := temp_DWA
			alert_array[A_LoopField, A_Index, "Repeat"] := Temp_repeat
			alert_array[A_LoopField, A_Index, "IDName"] := Temp_IDName
		}
	}
	Return

TV_CountP()
{
	ItemID := TV_GetChild(TV_GetParent(TV_GetSelection()))
	TV_GetText(ItemTxt, (TV_GetSelection()))
	Loop
	{
		If (ItemID = 0 OR ItemTxt = OutputTxt) ; No more items in tree. (FUNCTIONS RETURNS 0 LAST ONE)
			break
		TV_GetText(OutputTxt, ItemID)
		ItemID := TV_GetNext(ItemID)
		Count_Item ++
	}
	Return Count_Item
}

WM_MOUSEMOVE()
{
	static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
	
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 400
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:

    SetTimer, DisplayToolTip, Off
	Try	ToolTip % %CurrControl%_TT  ; try guards against illegal character error
    SetTimer, RemoveToolTip, 6000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

warp_gate_chrono(ByRef a_Result, ByRef F_baselist_var, ByRef F_chronocount_var)	
{	global A_unitID, DeadFilterFlag
	a_warpgates := [], a_gateways := [],
	a_WarpgatesOnCoolDown := [], F_baselist_var := [], a_Result := []
	While (A_index <= getHighestUnitIndex())
	{
		unit := A_Index - 1
		Filter := getUnitTargetFilter(unit)	
		type := getUnitType(unit)
		If (Filter & DeadFilterFlag) || (type = "Fail")
			Continue
		If !isUnitLocallyOwned(Unit)
			continue
		IF ( type = A_unitID["WarpGate"] && !isUnitChronoed(unit)) && (cooldown := getWarpGateCooldown(unit))
				a_WarpgatesOnCoolDown.insert({"Unit": unit, "Cooldown": cooldown})
		Else IF (type = A_unitID["Gateway"] AND !isUnderConstruction(unit) && !isUnitChronoed(unit)) ; 0 means its completed 
			a_gateways.insert(unit)
		Else If (type = A_unitID["Nexus"] AND !isUnderConstruction(unit))
		{ 
			F_baselist_var.insert(unit)
			nexus_chrono_count += Floor(getUnitEnergy(unit)/25)	
		}
	}
	if a_WarpgatesOnCoolDown.MaxIndex()
		Sort2DArray(a_WarpgatesOnCoolDown, "Cooldown", 0)	;so warpgates with longest cooldown get chronod first
	if a_gateways.MaxIndex()	
		RandomiseSimpleArray(a_gateways)
	
	for index, Warpgate in a_WarpgatesOnCoolDown
		a_Result.insert(Warpgate.Unit)	
	for index, Gateways in a_gateways
		a_Result.insert(Gateways)

	If IsByRef(F_chronocount_var)
		F_chronocount_var := nexus_chrono_count
	Return 
}



local_minerals(ByRef Return_Base_index, SortBy="Index") ;Returns a list of [Uints] index position for minerals And optionaly the [unit] index for the local base
{	;	Nexus = 90 CommandCenter = 48 Hatchery = 117
	;sc2_unit_count := getUnitCount()		;can put the count outside the loop for this
	while ( A_Index <= getUnitCount()) 
	{
		unit := A_Index - 1
		type := getUnitType(unit)
		IF isUnitLocallyOwned(unit)
		AND ( type = 90 OR type = 48 OR type = 117 )
			Base_loc_index := unit	;
		Else IF type = 253 ; 253 = Normal Mineral patch
			MineraList .= unit "|"  ; x|x|
	}
	MineraList := SubStr(MineraList, 1, -1)	;remove the trailing |
	loop, parse, MineraList, | 
	{
		IF areUnitsNearEachOther( A_LoopField, Base_loc_index, 8, 8) ; 1 if near
			Result .= A_LoopField "|"
	}
	MineraList := RTrim(Result, "| ")
	If (SortBy = "Distance")
		MineraList := sortUnitsByDistance(Base_loc_index, MineraList) 
	IF IsByRef(Return_Base_index)
		Return_Base_index := Base_loc_index
	Return MineraList
}

sortUnitsByDistance(Base, unitlist="", units*)
{ 	; accepts a "|" delimeter list, OR a variadic list
	List := []		;used to sort mineral patches by closest
	if unitlist		;but still doesnt find the 3 relative closest patches
	{				;probably due to where 'nexus' is - look at this later.
		units := []	;actually unit x,y seems to be from the centre of the unit.
		loop, parse, unitlist, |
			units[A_index] := A_LoopField
	}	
	for index, unit in units
	{
		Base_x := getUnitPositionX(Base), Base_y := getUnitPositionY(Base)
		unit_x := getUnitPositionX(unit), unit_y := getUnitPositionY(unit)
		List[A_Index] := {Unit:unit,Distance:Abs(Base_x - unit_x) + Abs(Base_y - unit_y)}	
	}
	Sort2DArray(List, "Distance")
	For index, obj in List
		SortedList .= List[index].Unit "|"
	return RTrim(SortedList, "|")
} 

SortUnitsByMapOrder(unitlist="", units*)
{ 	; accepts a "|" delimeter list, OR a variadic list
	List := []		;used to sort mineral patches by from left to right, or top to bottom
	if unitlist		
	{			
		units := []
		loop, parse, unitlist, |
			units[A_index] := A_LoopField
	}	
	for index, unit in units
		List[A_Index] := {Unit:unit, X: getUnitPositionX(unit), Y: getUnitPositionY(unit)}	
				
	Sort2DArray(List, "X") ;3rd param def 1 OR ascending
	For index, obj in List
	{
		If (index = List.minindex())
			X_Min := List[index].X
		If (index = List.MaxIndex())
			X_Max := List[index].X
	}
	Sort2DArray(List, "Y")
	For index, obj in List
	{
		If (index = List.minindex())
			Y_Min := List[index].Y
		If (index = List.MaxIndex())
			Y_Max := List[index].Y
	}		 
	If (X_Delta := Abs(X_Max-X_Min)) > (Y_Delta := Abs(Y_Max-Y_Min))
	{
		Sort2DArray(List, "X")
		For index, obj in List
			SortedList .= List[index].Unit "|"
	}
	else 
	{
		Sort2DArray(List, "Y")
		For index, obj in List
			SortedList .= List[index].Unit "|"	
	}
	return RTrim(SortedList, "|")
} 


areUnitsNearEachOther(unit1, unit2, x_max_dist = "", y_max_dist = "", compareZ = 1)
{
	if !(x_max_dist || y_max_dist)
		Return "One max distance is required!"
	Else If  !y_max_dist
		y_max_dist := x_max_dist
	Else x_max_dist := y_max_dist
	
	x_dist := Abs(getUnitPositionX(unit1) - getUnitPositionX(unit2))
	y_dist := Abs(getUnitPositionY(unit1) - getUnitPositionY(unit2))
																										;round Height Z to 1 decimal place, as there is a small amount of variation in 'flat ground'
	Return Result := (x_dist > x_max_dist) || (y_dist > y_max_dist) || (compareZ && round(getUnitPositionZ(unit1), 1) != round(getUnitPositionZ(unit2), 1)) ? 0 : 1 ; 0 Not near
}

getMapLeft()
{	global
	return ReadMemory(O_mLeft, GameIdentifier) / 4096
}
getMapBottom()
{	global
	return ReadMemory(O_mBottom, GameIdentifier) / 4096
}
getMapRight()
{	global
	return ReadMemory(O_mRight, GameIdentifier) / 4096
}
getMapTop()
{	global
	return ReadMemory(O_mTop, GameIdentifier) / 4096
}

Get_Bmap_pixel(u_array_index_number, ByRef Xvar, ByRef Yvar)
{
local u_x, u_y, tx, ty

	P_Xcam := getPlayerCameraPositionX()
	P_Ycam := getPlayerCameraPositionY() + (7142/4096)

	u_x := getUnitPositionX(u_array_index_number)
	u_y := getUnitPositionY(u_array_index_number)

	
	X_Bmap_conv := 950/(61954/4096)  ; pixel/map_X
	if (u_x >= P_Xcam)
	{
		u_x := u_x - P_Xcam 	; Hence relative to camera
		tx := u_x * X_Bmap_conv
		tx := 960 + tx
	}
	Else
	{
		u_x := P_Xcam  - u_x
		tx := u_x * X_Bmap_conv
		tx := 960 - tx
	}
	
	if (u_y >= P_Ycam)
	{
	;	SoundPlay *-1
		u_y := u_y - P_Ycam
	;	Y_Bmap_conv_T := 375/(41661/4096)		 ; (for top)
	;	Y_Bmap_conv := (375/7.89) *.7
	;	Y_Bmap_conv := (u_y/(41661/4096)) *	375/(41661/4096) *1.3
		Y_Bmap_conv :=  375/ (10.17114 - (5.6 + (u_y/(41661/4096)))*.1)
		
		ty := u_y * Y_Bmap_conv	
		ty := 375 - ty
	}
	Else
	{
		u_y := P_Ycam - u_y
		Y_Bmap_conv := 375/ (7.89 - (5.6 - (u_y/(22976/4096)) *	3.5 ))
		ty := u_y * Y_Bmap_conv	
		ty := 375 + ty
	}
	If IsByRef(Xvar)
		Xvar := Round(tx)
	IF IsByRef(Yvar)
		Yvar := Round(ty)
	if (Xvar < 15 || Xvar > A_ScreenWidth-15) || (Yvar < 15) ; the mouse will push on/move the screen 
		Return 1
}
getBuildingList(F_building_var*)	
{ global DeadFilterFlag
	;unitcount:= getUnitCount()
	While (A_index <= getHighestUnitIndex())
	{	unit := A_Index - 1
		type := getUnitType(Unit)
		Filter := getUnitTargetFilter(Unit)		
		If (Filter & DeadFilterFlag) || (type = "Fail")
			Continue
			
		For index, building_type in F_building_var
		{	IF (type = building_type) And (isUnitLocallyOwned(Unit))
			AND (isUnderConstruction(Unit) = 0 ) ; 0 means its completed 
				List .= unit "|"  ; x|x|	
		}
	}
	List := SubStr(List, 1, -1)	
	sort list, D| Random
	Return List
}

isUserCastingOrBuilding()	;note auto casting e.g. swarm host will always activate this. There are separate bool values indicating buildings at certain spells
{	global
	return pointer(GameIdentifier, P_IsUserCasting, O1_IsUserCasting, O2_IsUserCasting, O3_IsUserCasting, O4_IsUserCasting)
}

	
filterSlectionTypeByEnergy(EnergyFilter="", F_utype*) ;Returns the [Unit] index number
{	
	selection_i := getSelectionCount()
	while (A_Index <= selection_i)		;loop thru the units in the selection buffer	
	{	
		unit := getSelectedUnitIndex(A_Index -1)
		type := getUnitType(Unit)
		If (EnergyFilter = "")
			For index, F_Found in F_utype
			{
				If (F_Found = type)
					Result .= unit "|"		;  selctio buffer refers to 0 whereas my [unit] did begin at 1
			}		
		Else
			For index, F_Found in F_utype
			{
				If (F_Found = type) AND (EnergyFilter <= getUnitEnergy(unit))
					Result .= unit "|"	
			}	
	}	
	Return Result := SubStr(Result, 1, -1)		
}

Edit_AG:	;AutoGroup and Unit include/exclude come here
	TMP_AG_ControlName := SubStr(A_GuiControl, 2)
	GuiControlGet, TMP_EditAG_Units,, %TMP_AG_ControlName%

	
	IfInString, A_GuiControl, UnitHighlight
		TMP_EditAG_Units .= AG_GUI_ADD("", TMP_EditAG_Units ? 1 : 0)
	Else
		TMP_EditAG_Units .= AG_GUI_ADD(SubStr(A_GuiControl, 0, 1), TMP_EditAG_Units ? 1 : 0) ;retrieve the last character of name ie control number 0/1/2 etc		
	GUIControl,, %TMP_AG_ControlName%, %TMP_EditAG_Units%
Return
AG_GUI_ADD(Control_Group = "", comma=1)
{
	static F_drop_Name 
	global l_UnitNames
	If (Control_Group = "")
		Title := "Select Unit"
	else Title := "Auto Group " Control_Group
	
	Gui, Add2AG:Add, Text, x5 y+10, Select Unit Type:
	Gui, Add2AG:Add, ListBox, x5 y+10 w150 h280 VF_drop_Name  sort, %l_UnitNames%
	Gui, Add2AG:Add, Button, y+20 x5 w60 h35 gB_ADD, Add
	Gui, Add2AG:Add, Button, yp+0 x95 w60 h35  gB_close, Close
	GUI, Add2AG:+AlwaysOnTop +ToolWindow
	GUI, Add2AG:Show, w160 h380, %Title%
	Gui, Add2AG:+OwnerOptions
	Gui, Options:+Disabled
 	;return ;cant use return here, otherwise script will continue running immeditely after the functionc call
	pause	
						; ****also note, the function will jump to bclose but aftwards will continue from here linearly down
	B_ADD:				;hence have to check whether to return any value
	Gui, Options:-Disabled
	Gui, Options:Show		;required to keep from minimising
	Gui, Add2AG:Submit
	Gui Add2AG:Destroy
	;GuiControlGet, Edit_Unit_name,, F_drop_Name
	pause off

	if (close <> 1)
		Return comma = 1 ? ", " F_drop_Name : F_drop_Name
	Return 

	B_Close:
	Add2AGGUIEscape:
    Add2AGGUIClose:
	Close := 1
	Gui, Options:-Disabled
	Gui Add2AG:Destroy
	pause off
	Return ;this is needed to for the above if (if the canel/escape gui)

}

SetupUnitIDArray(byref A_unitID)
{
	#include %A_ScriptDir%\Included Files\l_UnitTypes.AHK
	A_unitID := []
	loop, parse, l_UnitTypes, `,
	{
		StringSplit, Item , A_LoopField, = 		; Format "Colossus = 38"
		name := trim(Item1, " `t `n"), UnitID := trim(Item2, " `t `n")
		A_unitID[name] := UnitID
	}
	Return
}

setupTargetFilters(byref Array)
{
	#include %A_ScriptDir%\Included Files\a_UnitTargetFilter.AHK
	Array := a_UnitTargetFilter
	return
}

SetupColourArrays(ByRef HexColour, Byref MatrixColour)
{ 	
	If IsByRef(HexColour)
		HexColour := [] 
	If IsByRef(MatrixColour)	
		MatrixColour := []
	HexCoulourList := "White=FFFFFF|Red=B4141E|Blue=0042FF|Teal=1CA7EA|Purple=540081|Yellow=EBE129|Orange=FE8A0E|Green=168000|Light Pink=CCA6FC|Violet=1F01C9|Light Grey=525494|Dark Green=106246|Brown=4E2A04|Light Green=96FF91|Dark Grey=232323|Pink=E55BB0|Black=000000"
	loop, parse, HexCoulourList, |  
	{
		StringSplit, Item , A_LoopField, = ;Format "White = FFFFFF"
		If IsByRef(HexColour)
			HexColour[Item1] := Item2 ; White, FFFFFF - hextriplet R G B
		If IsByRef(MatrixColour)
		{
			colour := Item2
			colourRed := "0x" substr(colour, 1, 2) ;theres a way of doing this with math but im lazy
			colourGreen := "0x" substr(colour, 3, 2)
			colourBlue := "0x" substr(colour, 5, 2)	
			colourRed := Round(colourRed/0xFF,2)
			colourGreen := Round(colourGreen/0xFF,2)
			colourBlue := Round(colourBlue/0xFF,2)		
			Matrix =
		(
0		|0		|0		|0		|0
0		|0		|0		|0		|0
0		|0		|0		|0		|0
0		|0		|0		|1		|0
%colourRed%	|%colourGreen%	|%colourBlue%	|0		|1
		)
			MatrixColour[Item1] := Matrix
		}
	}
	Return
}

isInControlGroup(group, unit) 
{	; group# = 1, 2,3-0  
	global  
	loop, % getControlGroupCount(Group)
		if (unit = getCtrlGroupedUnitIndex(Group,  A_Index - 1))
			Return 1	;the unit is in this control group
	Return 0			
}	;	ctrl_unit_number := ReadMemory(B_CtrlGroupStructure + S_CtrlGroup * (group - 1) + O_scUnitIndex +(A_Index - 1) * S_scStructure, GameIdentifier, 2)/4

getCtrlGroupedUnitIndex(group, i=0)
{	global
	Return ReadMemory(B_CtrlGroupStructure + S_CtrlGroup * (group - 1) + O_scUnitIndex + i * S_scStructure, GameIdentifier) >> 18
}


getControlGroupCount(Group)
{	global
	Return	ReadMemory(B_CtrlGroupStructure + S_CtrlGroup * (Group - 1), GameIdentifier, 2)
}	

ReleaseAllModifiers(Mode="") 
{ 
	If (Mode = "BlockAll")
		BlockInput, On 			;BlockInput, MouseMove not required
	KeyDelay := A_KeyDelay
	MouseDelay := A_MouseDelay
	SetKeyDelay 10
	SetMouseDelay 10
	list = LControl|RControl|LShift|RShift|LAlt|RAlt|LButton|RButton|MButton 
	Loop Parse, list, | 
	{ 
		if (GetKeyState(A_LoopField)) 	;fix sticky key problem
		send {Blind}{%A_LoopField% up}       ; {Blind} is added.
	} 
	SetKeyDelay %KeyDelay%
	SetMouseDelay %MouseDelay%   
} 

RestoreModifierPhysicalState(Mode="")
{
	If (Mode = "Unblock")
		BlockInput, off
	KeyDelay := A_KeyDelay
	MouseDelay := A_MouseDelay
	SetKeyDelay 10
	SetMouseDelay 10	
	list = LControl|RControl|LShift|RShift|LAlt
	Loop Parse, list, |
	{
		if (GetKeyState(A_LoopField) != GetKeyState(A_LoopField, "P")) ;if logical and physical state do not match
		 {
			if (GetKeyState(A_LoopField, "P")) ;send an event to restore the physical key state
				send {Blind}{%A_LoopField% down}
			else
				send {Blind}{%A_LoopField% up} ;trying blind here to see if it works
		 }
	 }
	SetKeyDelay %KeyDelay%
	SetMouseDelay %MouseDelay%   
}





GetEnemyTeamSize()
{	global a_Player, a_LocalPlayer
	For slot_number in a_Player
		If a_LocalPlayer["Team"] <> a_Player[slot_number, "Team"]
			EnemyTeam_i ++
	Return EnemyTeam_i
}

GetEBases()
{	global a_Player, a_LocalPlayer, A_unitID, DeadFilterFlag
	EnemyBase_i := GetEnemyTeamSize()
	;UnitCount := getUnitCount()
	While (A_index <= getHighestUnitIndex()) 
						AND (Found_i < EnemyBase_i)  
	{	unit := A_Index - 1
		type := getUnitType(Unit)
		Filter := getUnitTargetFilter(Unit)	
		Owner := getUnitOwner(Unit)		

		If (Filter & DeadFilterFlag) || (type = "Fail")
			Continue
		Else
		{	
			IF (( type = A_unitID["Nexus"] ) OR ( type = A_unitID["CommandCenter"] ) OR ( type = A_unitID["Hatchery"] )) AND (a_Player[Owner, "Team"] <> a_LocalPlayer["Team"])
			{
				Found_i ++
				list .=  unit "|"
			}
		}
	}
	Return SubStr(list, 1, -1)	; remove last "|"	
}



dSpeak(Message, fSapi_vol="", fOverall_vol="")
{	global overall_program, speech_volume
	if (fSapi_vol = "")
		fSapi_vol := speech_volume
	if (fOverall_vol = "")
		fOverall_vol := overall_program
	DynaRun(CreateScript("<DSpeak:Dspeak>", "overall_program := """ fOverall_vol """", "speech_volume := """ fSapi_vol """", "Message := """ Message """"), "MT_Speech.AHK", A_Temp "\AHK.exe")
	Return ; the below lines cant take spaces at start or comments at end

<DSpeak:
#NoTrayIcon 
_Replace_line1_:
_Replace_line2_:
_Replace_line3_:
SAPI := ComObjCreate("SAPI.SpVoice")
SAPI.volume := speech_volume
SoundSet, %overall_program%
Try SAPI.Speak(Message)
ExitApp
Dspeak>:
}

getTime()
{	global 
	Return Round(ReadMemory(B_Timer, GameIdentifier)/4096, 1)
}

getSelectionType(units*) 
{
	if !units.MaxIndex() ;no units passed to function
		loop % getSelectionCount()				
			list .= getUnitType(getSelectedUnitIndex(A_Index - 1)) "|"
	Else
		for key, unit in units
			list .= getUnitType(getSelectedUnitIndex(A_Index - 1)) "|"
	Return SubStr(list, 1, -1)
}

getSelectedUnitIndex(i=0) ;IF Blank just return the first selected unit (at position 0)
{	global
	Return ReadMemory(B_SelectionStructure + O_scUnitIndex + i * S_scStructure, GameIdentifier) >> 18	;how the game does it
	; returns the same thing ; Return ReadMemory(B_SelectionStructure + O_scUnitIndex + i * S_scStructure, GameIdentifier, 2) /4
}

getSelectionTypeCount()	; begins at 1
{	global
	Return	ReadMemory(B_SelectionStructure + O_scTypeCount, GameIdentifier, 2)
}
getSelectionHighlightedGroup()	; begins at 0 
{	global
	Return ReadMemory(B_SelectionStructure + O_scTypeHighlighted, GameIdentifier, 2)
}

getSelectionCount()
{ 	global 
	Return ReadMemory(B_SelectionStructure, GameIdentifier, 2)
}
getIdleWorkers()
{	global 	
	return pointer(GameIdentifier, P_IdleWorker, O1_IdleWorker, O2_IdleWorker)
}
getPlayerSupply(player="")
{ global
	If (player = "")
		player := a_LocalPlayer["Slot"]
	Return round(ReadMemory(((B_pStructure + O_pSupply) + (player-1)*S_pStructure), GameIdentifier)  / 4096)		
	; Round Returns 0 when memory returns Fail
}
getPlayerSupplyCap(player="")
{ global 
	If (player = "")
		player := a_LocalPlayer["Slot"]
	Return round(ReadMemory(((B_pStructure + O_pSupplyCap) + (player-1)*S_pStructure), GameIdentifier)  / 4096)
}
getPlayerWorkerCount(player="")
{ global
	If (player = "")
		player := a_LocalPlayer["Slot"]
	Return ReadMemory(((B_pStructure + O_pWorkerCount) + (player-1)*S_pStructure), GameIdentifier)
}
getUnitType(Unit) ;starts @ 0 i.e. first unit at 0
{ global 
	Return ReadMemory(((ReadMemory(B_uStructure + (Unit * S_uStructure) 
				+ O_uModelPointer, GameIdentifier)) << 5) + O_mUnitID, GameIdentifier, 2) ; note the pointer is 4byte, but the unit type is 2byte/word
}
getUnitName(unit)
{	global 
	Return substr(ReadMemory_Str(ReadMemory(ReadMemory(((ReadMemory(B_uStructure + (Unit * S_uStructure) 
			+ O_uModelPointer, GameIdentifier)) << 5) + 0x6C, GameIdentifier), GameIdentifier) + 0x29, ,GameIdentifier), 6)
	;	pNameDataAddress := ReadMemory(unit_type + 0x6C, "StarCraft II")
	;	NameDataAddress  := ReadMemory(pNameDataAddress, "StarCraft II") + 0x29 ; ie its a pointer 
	;	Name := ReadMemory_Str(NameDataAddress, , "StarCraft II")
	;	NameLength := ReadMemory(NameDataAddress, "StarCraft II") 		
}

getUnitOwner(Unit) ;starts @ 0 i.e. first unit at 0 - 2.0.4 starts at 1?
{ 	global
	Return	ReadMemory((B_uStructure + (Unit * S_uStructure)) + O_uOwner, GameIdentifier, 1) ; note the 1 to read 1 byte
}
getUnitTargetFilter(Unit) ;starts @ 0 i.e. first unit at 0
{	global 
	Return	ReadMemory((B_uStructure + (Unit * S_uStructure)) + O_uTargetFilter, GameIdentifier, 8) ; note the 8 to read 8 byte
}

getMiniMapRadius(Unit)
{	global
	Return ReadMemory(((ReadMemory(B_uStructure + (unit * S_uStructure) + O_uModelPointer, GameIdentifier) << 5) & 0xFFFFFFFF) + O_mMiniMapSize, GameIdentifier) /4096
}
getSubGroupPriority(Unit)	;this is a messy workaround fix
{	local Filter := getUnitTargetFilter(unit)	
	local Priority := ReadMemory(((ReadMemory(B_uStructure + (unit * S_uStructure) + O_uModelPointer, GameIdentifier) << 5) & 0xFFFFFFFF) + O_mSubgroupPriority, GameIdentifier, 2)
	local type := getunittype(unit)
	
	if (type = A_unitID.SwarmHostBurrowed)
		Priority += .2		;can't use .5 as then if 1 is 18 and other 17 can both equal 17.5 which isnt right
else if (Filter & BuriedFilterFlag) && (type != A_unitID.WidowMineBurrowed)	; as this doesnt effect where the widow mine is in its subgroup
		Priority -= .2		;this is a work around, as burrowed units are a lower priority (come later in the selection group) except for swarm host which is higher!! :(
	Return Priority
}
getUnitCount()
{ local count 	
	if (!count := ReadMemory(B_uCount, GameIdentifier))
		count := 1	;so dont get stuck with dividing by 0 and infinite loop in iterations
	Return count
}
getHighestUnitIndex() 	; this is the highest alive units index - note its out by 1
{	global				; if 1 unit is alive it will return 1 (NOT 0)
	Return ReadMemory(B_uHighestIndex, GameIdentifier)	
}
getPlayerName(i) ; start at 0
{	global
	Return ReadMemory_Str((B_pStructure + O_pName) + (i-1) * S_pStructure, , GameIdentifier) 
}
getPlayerRace(i) ; start at 0
{	global
	local Race
	; Race := ReadMemory_Str((B_rStructure + (i-1) * S_rStructure), ,GameIdentifier) ;old easy way
	Race := ReadMemory_Str(ReadMemory(ReadMemory(B_pStructure + O_pRacePointer + (i-1)*S_pStructure, GameIdentifier) + 4, GameIdentifier), , GameIdentifier) 
	If (Race == "Terr")
		Race := "Terran"
	Else if (Race == "Prot")
		Race := "Protoss"
	Else If (Race == "Zerg")
		Race := "Zerg"	
	Else If (Race == "Neut")
		Race := "Neutral"
	Else 
		Race := "Error"
	Return Race
}

getPlayerType(i)
{	global
	Return ReadMemory((B_pStructure + O_pType) + (i-1) * S_pStructure, GameIdentifier, 1)
}

getPlayerTeam(player="") ;team begins at 0
{	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory((B_pStructure + O_pTeam) + (player-1) * S_pStructure, GameIdentifier, 1)
}
getPlayerColour(i)
{	local A_Player_Colour, Colour_List
	A_Player_Colour := []
	Colour_List := "White|Red|Blue|Teal|Purple|Yellow|Orange|Green|Light Pink|Violet|Light Grey|Dark Green|Brown|Light Green|Dark Grey|Pink"
	Loop, Parse, Colour_List, |
		A_Player_Colour[a_index - 1] := A_LoopField
	Return A_Player_Colour[ReadMemory((B_pStructure + O_pColour) + (i-1) * S_pStructure, GameIdentifier)]
}
getLocalPlayerNumber() ;starts @ 1
{	global
	Return ReadMemory(B_LocalPlayerSlot, GameIdentifier, 1) ;Local player slot is 1 Byte!!
}
getBaseCameraCount(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory((B_pStructure + O_pBaseCount) + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerMineralIncome(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pMineralIncome + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerGasIncome(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pGasIncome + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerArmySizeMinerals(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pArmyMineralSize + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerArmySizeGas(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pArmyGasSize + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerMinerals(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pMinerals + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerGas(player="")
{ 	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + O_pGas + (player-1) * S_pStructure, GameIdentifier)
}
getPlayerCameraPositionX(Player="")
{	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pXcam, GameIdentifier) / 4096
}
getPlayerCameraPositionY(Player="")
{	global
	If (player = "")
		player := a_LocalPlayer["Slot"]	
	Return ReadMemory(B_pStructure + (Player - 1)*S_pStructure + O_pYcam, GameIdentifier) / 4096
}

isUnderConstruction(building) ; starts @ 0 and only for BUILDINGS!
{ 	global  ; 0 means its completed
;	Return ReadMemory(B_uStructure + (building * S_uStructure) + O_uBuildStatus, GameIdentifier) ;- worked fine
	return getunittargetfilter(building) & a_UnitTargetFilter.UnderConstruction
}

getUnitEnergy(unit)
{	global
	Return Floor(ReadMemory(B_uStructure + (unit * S_uStructure) + O_uEnergy, GameIdentifier) / 4096)
}

getUnitPositionX(unit)
{	global
	Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uX, GameIdentifier) /4096
}
getUnitPositionY(unit)
{	global
	Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uY, GameIdentifier) /4096
}

getUnitPositionZ(unit)
{	global
	Return ReadMemory(B_uStructure + (unit * S_uStructure) + O_uZ, GameIdentifier) /4096
}


getUnitMoveState(unit)
{	local CmdQueue, BaseCmdQueStruct
	if (CmdQueue := ReadMemory(B_uStructure + unit * S_uStructure + O_P_uCmdQueuePointer, GameIdentifier)) ; points if currently has a command - 0 otherwise
	{
		BaseCmdQueStruct := ReadMemory(CmdQueue, GameIdentifier) & -2
		return ReadMemory(BaseCmdQueStruct + O_cqMoveState, GameIdentifier, 2) ;current state
	}
	else return -1 ;cant return 0 as that ould indicate A-move
}

isUnitPatrolling(unit)
{	global
	return uMovementFlags.Patrol & getUnitMoveState(unit)
}


arePlayerColoursEnabled()
{	global
	Return pointer(GameIdentifier, P_PlayerColours, O1_PlayerColours, O2_PlayerColours)
}

isMenuOpen()
{ 	global
	Return  pointer(GameIdentifier, P_MenuFocus, O1_MenuFocus)
}

isChatOpen()
{ 	global
	Return  pointer(GameIdentifier, P_ChatFocus, O1_ChatFocus, O2_ChatFocus)
}
GetEnemyRaces()
{	global a_Player, a_LocalPlayer
	For slot_number in a_Player
	{	If ( a_LocalPlayer["Team"] <>  team := a_Player[slot_number, "Team"] )
		{
			If ( EnemyRaces <> "")
				EnemyRaces .= ", "
			EnemyRaces .= a_Player[slot_number, "Race"]
		}
	}
	return EnemyRaces .= "."
}

GetGameType(a_Player)
{	
	For slot_number in a_Player
	{	team := a_Player[slot_number, "Team"]
		TeamsList .= Team "|"
		Player_i ++
	}
	Sort, TeamsList, D| N U
	TeamsList := SubStr(TeamsList, 1, -1)
	Loop, Parse, TeamsList, |
		Team_i := A_Index
	If (Team_i > 2)
		Return "FFA" 
	Else	 ;sets game_type to 1v1,2v2,3v3,4v4 ;this helps with empty player slots - round up to the next game type
		Return Round(Player_i/Team_i) "v" Round(Player_i/Team_i)
}

isUnitLocallyOwned(Unit) ; 1 its local player owned
{	global a_LocalPlayer
	Return a_LocalPlayer["Slot"] = getUnitOwner(Unit) ? 1 : 0
}


setupAutoGroup(Race, ByRef A_AutoGroup, A_unitID, A_UnitGroupSettings)
{
	A_AutoGroup := []
	loop, 10
	{	
		ControlGroup := A_index - 1		;for control group 0			
		Race := substr(Race, 1, 4)	;cos used Terr in ini
		List := A_UnitGroupSettings[Race, ControlGroup]				
		StringReplace, List, List, %A_Space%, , All ; Remove Spaces
		StringReplace, List, List, |, `,, All ;replace | with ,
		List := Rtrim(List, "`, |") ;checks the last character
		If (List <> "")
		{
			loop, parse, List, `, 
			A_AutoGroup[ControlGroup] .= A_unitID[A_LoopField] ","	;assign the unit ID based on name from iniFile	
			A_AutoGroup[ControlGroup] := RTrim(A_AutoGroup[ControlGroup], ",") 
		}		 
	}
	Return
}


DrawMiniMap()
{	global
	local UnitRead_i, unit, type, Owner, Radius, Filter, EndCount, colour, ResourceOverlay_i, unitcount
	, DrawX, DrawY, Width, height, i, hbm, hdc, obm, G,  pBitmap, PlayerColours, A_MiniMapUnits
	static Overlay_RunCount
	Overlay_RunCount ++
	if (ReDraw and WinActive(GameIdentifier))
	{
		Try Gui, MiniMapOverlay: Destroy
		Overlay_RunCount := 1
		ReDraw := 0
	}
	If (Overlay_RunCount = 1)
	{
		; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
		; Create a layered window ;E0x20 click thru (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption		
		Gui, MiniMapOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		; Show the window
		Gui, MiniMapOverlay: Show, NA
		; Get a handle to this window we have created in order to update it later
	;	hwnd1 := WinExist()
	}
		; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
		hbm := CreateDIBSection(A_ScreenWidth/4, A_ScreenHeight) ;only draw on left side of the screen
		; Get a device context compatible with the screen
		hdc := CreateCompatibleDC()
		; Select the bitmap into the device context
		obm := SelectObject(hdc, hbm)
	; Get a pointer to the graphics of the bitmap, for use with drawing functions
	G := Gdip_GraphicsFromHDC(hdc) ;needs to be here
	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	
	if DrawMiniMap
	{
		setDrawingQuality(G)
		A_MiniMapUnits := []
		PlayerColours := arePlayerColoursEnabled()
		
		While (A_index <= getHighestUnitIndex()) 
		{	unit := A_Index - 1
			type := getUnitType(Unit)
			Filter := getUnitTargetFilter(Unit)	
			If (Filter & DeadFilterFlag) || (type = "Fail")
				Continue
			Else 
			{		
				Owner := getUnitOwner(Unit)			
				If type in %ActiveUnitHighlightExcludeList% ; cant use or/expressions with type in
					Continue
				if  (a_Player[Owner, "Team"] <> a_LocalPlayer["Team"] AND Owner) ; Owner 0 = neutral
				{ 					
					Radius := getMiniMapRadius(Unit)
					if (Radius < minimap.UnitMinimumRadius ) ; probes and such ;|| (Radius > minimap.UnitMaximumRadius ) I DONT believe this occurs for actual units
						Radius := minimap.UnitMinimumRadius 
				;	Radius += (minimap.AddToRadius/2)
					getMiniMapPos(unit, DrawX, DrawY)
					if type in %ActiveUnitHighlightList1%
						Colour := UnitHighlightList1Colour
					Else If type in %ActiveUnitHighlightList2%
						Colour := UnitHighlightList2Colour						
					Else If type in %ActiveUnitHighlightList3%
						Colour := UnitHighlightList3Colour				
					Else if PlayerColours
						Colour := 0xcFF HexColour[a_Player[Owner, "Colour"]]   ;FF=Transparency
					Else Colour := 0xcFF HexColour["Red"]	
					A_MiniMapUnits.insert({"X": DrawX, "Y": DrawY, "Colour": Colour, "Radius": Radius*2})						
				}
			}
		} 
		if !blendunits
			for index, unit in A_MiniMapUnits
			{
				drawUnitRectangle(G, unit.X, unit.Y, unit.Radius + minimap.AddToRadius, unit.Radius + minimap.AddToRadius)	;draw rectangles first
				FillUnitRectangle(G, unit.X, unit.Y,  unit.Radius, unit.Radius, unit.Colour)
			}
		else
		{
			for index, unit in A_MiniMapUnits
				drawUnitRectangle(G, unit.X, unit.Y, unit.Radius + minimap.AddToRadius, unit.Radius + minimap.AddToRadius)	;draw rectangles first
			for index, unit in A_MiniMapUnits
				FillUnitRectangle(G, unit.X, unit.Y,  unit.Radius, unit.Radius, unit.Colour)
		}
	}
	If (DrawSpawningRaces) && (Time - round(TimeReadRacesSet) <= 14) ;round used to change undefined var to 0 for resume so dont display races
	{	Gdip_SetInterpolationMode(G, 7)				;TimeReadRacesSet gets set to 0 at start of match
		loop, parse, EnemyBaseList, |
		{		
			type := getUnitType(A_LoopField)
			getMiniMapMousePos(A_LoopField, BaseX, BaseY)
			if ( type = A_unitID["Nexus"]) 		
			{	pBitmap := a_pBitmap["Protoss","RacePretty"]
				Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)	
				Gdip_DrawImage(G, pBitmap, (BaseX - Width/5), (BaseY - Height/5), Width//2.5, Height//2.5, 0, 0, Width, Height)
			}
			Else if (type = A_unitID["CommandCenter"] || type =  A_unitID["PlanetaryFortress"] || type =  A_unitID["OrbitalCommand"])
			{
				pBitmap := a_pBitmap["Terran","RacePretty"]
				Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
				Gdip_DrawImage(G, pBitmap, (BaseX - Width/10), (BaseY - Height/10), Width//5, Height//5, 0, 0, Width, Height)
			}
			Else if (type = A_unitID["Hatchery"] || type =  A_unitID["Lair"] || type =  A_unitID["Hive"])
			{	pBitmap := a_pBitmap["Zerg","RacePretty"]
				Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
				Gdip_DrawImage(G, pBitmap, (BaseX - Width/6), (BaseY - Height/6), Width//3, Height//3, 0, 0, Width, Height)
			}
		}

	}
	if DrawAlerts
	{
		While (A_index <= MiniMapWarning.MaxIndex())
		{	
			If (Time - MiniMapWarning[A_index,"Time"] >= 20) ;display for 20 seconds
			{	MiniMapWarning.Remove(A_index)
				continue
			}
			owner := getUnitOwner(MiniMapWarning[A_index,"Unit"])	
			If (a_Player[owner, "Team"] <> a_LocalPlayer["Team"])
			{
				If (arePlayerColoursEnabled() AND a_Player[Owner, "Colour"] = "Green")
					pBitmap := a_pBitmap["PurpleX16"] 
				Else pBitmap := a_pBitmap["GreenX16"]
			}
			Else 
				pBitmap := a_pBitmap["RedX16"]
			getMiniMapMousePos(MiniMapWarning[A_index,"Unit"], X, Y)
			Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)	
			Gdip_DrawImage(G, pBitmap, (X - Width/2), (Y - Height/2), Width, Height, 0, 0, Width, Height)	
		} 
	}
	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc, 0, 0, A_ScreenWidth/4, A_ScreenHeight) ;only draw on left side of the screen
	SelectObject(hdc, obm) ; needed else eats ram ; Select the object back into the hdc
	DeleteObject(hbm)   ; needed else eats ram 	; Now the bitmap may be deleted
	DeleteDC(hdc) ; Also the device context related to the bitmap may be deleted
Return
}

HiWord(number)
{
	if (number & 0x80000000)
		return (number >> 16)
	return (number >> 16) & 0xffff	
}	
	
OverlayResize_WM_MOUSEWHEEL(wParam) 		;(wParam, lParam) 0x20A =mousewheel
{ local WheelMove, ActiveTitle, newScale, Scale
	WheelMove := wParam > 0x7FFFFFFF ? HiWord(-(~wParam)-1)/120 :  HiWord(wParam)/120 ;get the higher order word & /120 = number of rotations
	WinGetActiveTitle, ActiveTitle 			;downard rotations are -negative numbers
	if ActiveTitle in IncomeOverlay,ResourcesOverlay,ArmySizeOverlay,WorkerOverlay,IdleWorkersOverlay,UnitOverlay ; here cos it can get non overlay titles
	{	
		newScale := %ActiveTitle%Scale + WheelMove*.05
		if (newScale >= .5)
			%ActiveTitle%Scale := newScale
		else newScale := %ActiveTitle%Scale := .5	
		IniWrite, %newScale%, %config_file%, Overlays, %ActiveTitle%Scale
	}
} 

OverlayMove_LButtonDown()
{
    PostMessage, 0xA1, 2
}

DrawIdleWorkersOverlay(ByRef Redraw, UserScale=1,Drag=0, expand=1)
{	global a_LocalPlayer, GameIdentifier, config_file, IdleWorkersOverlayX, IdleWorkersOverlayY, a_pBitmap
	static Font := "Arial", Overlay_RunCount, hwnd1, DragPrevious := 0				

	Overlay_RunCount ++	
	DestX := DestY := 0
	idleCount := getIdleWorkers()
	If (Redraw = -1 || !idleCount)		;only draw overlay when idle workers present
	{
		Try Gui, idleWorkersOverlay: Destroy
		Overlay_RunCount := 0
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier) && idleCount)
	{
		Try Gui, idleWorkersOverlay: Destroy
		Overlay_RunCount := 1
		Redraw := 0
	}	
	If (Overlay_RunCount = 1)
	{
		Gui, idleWorkersOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, idleWorkersOverlay: Show, NA X%idleWorkersOverlayX% Y%idleWorkersOverlayY% W400 H400, idleWorkersOverlay
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, idleWorkersOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, idleWorkersOverlay: +E0x20 +LastFound
		WinGetPos,idleWorkersOverlayX,idleWorkersOverlayY		
		IniWrite, %idleWorkersOverlayX%, %config_file%, Overlays, idleWorkersOverlayX
		Iniwrite, %idleWorkersOverlayY%, %config_file%, Overlays, idleWorkersOverlayY
	}
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	
	
	pBitmap := a_pBitmap[a_LocalPlayer["Race"],"Worker"]
	SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
	
	expandOnIdle := 4
	if expand
	{
		increased := floor(idlecount / expandOnIdle)/8
		if (increased > .5)		; insreases size every 4 idle workers until 16 workers ie 4x
			increased := .5
		UserScale += increased
	}
	Options := " cFFFFFFFF r4 s" 18*UserScale
	Width *= UserScale *.5, Height *= UserScale *.5
	Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
	Gdip_TextToGraphics(G, idleCount, "x"(DestX+Width+2*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight, TextWidthHeight)
	Gdip_DeleteGraphics(G)	
	UpdateLayeredWindow(hwnd1, hdc)
	SelectObject(hdc, obm) 
	DeleteObject(hbm)  
	DeleteDC(hdc) 
	Return
}
DrawIncomeOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global a_LocalPlayer, HexColour, a_Player, GameIdentifier, IncomeOverlayX, IncomeOverlayY, config_file, MatrixColour, a_pBitmap
	static Font := "Arial", Overlay_RunCount, hwnd1, DragPrevious := 0
	Overlay_RunCount ++
	DestX := i := 0
	Options := " cFFFFFFFF r4 s" 17*UserScale					;these cant be static	
	If (Redraw = -1)
	{
		Try Gui, IncomeOverlay: Destroy
		Overlay_RunCount := 0
		Redraw := 0
		Return
	}		
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, IncomeOverlay: Destroy
		Overlay_RunCount := 1
		Redraw := 0
	}	
	If (Overlay_RunCount = 1)
	{
		Gui, IncomeOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, IncomeOverlay: Show, NA X%IncomeOverlayX% Y%IncomeOverlayY% W400 H400, IncomeOverlay
	;	hwnd1 := WinExist()
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, IncomeOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, IncomeOverlay: +E0x20 +LastFound
		WinGetPos,IncomeOverlayX,IncomeOverlayY,w,h		
		IniWrite, %IncomeOverlayX%, %config_file%, Overlays, IncomeOverlayX
		Iniwrite, %IncomeOverlayY%, %config_file%, Overlays, IncomeOverlayY		
	}		
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	
	For slot_number in a_Player
	{
		If ( a_LocalPlayer["Team"] <> a_Player[slot_number, "Team"] )
		{				
			DestY := i ? i*Height : 0

			If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
			{	
				IF (PlayerIdentifier = 2)
					OptionsName := " Bold cFF" HexColour[a_Player[slot_number, "Colour"]] " r4 s" 17*UserScale
				Else IF (PlayerIdentifier = 1)
					OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale	
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)
				if !LongestNameSize
				{
					LongestNameData :=	gdip_TextToGraphics(G, getLongestEnemyPlayerName(a_Player), "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale	, Font) ; text is invisible ;get string size	
					StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
					LongestNameSize := LongestNameSize3
				}
				DestX := LongestNameSize+10*UserScale
			}
			Else If (PlayerIdentifier = 3)
			{		
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"RaceFlat"]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight, MatrixColour[a_Player[slot_number, "Colour"]])
				;Gdip_DisposeImage(pBitmap)
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				DestX := Width+10*UserScale
			}
			Else 
			{
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
			}
			
			Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			Gdip_TextToGraphics(G, getPlayerMineralIncome(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				
				
			pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Gas",Background]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			Gdip_TextToGraphics(G, getPlayerGasIncome(slot_number), "x"(DestX+(85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				

			pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Worker"]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
			TextData := Gdip_TextToGraphics(G, getPlayerWorkerCount(slot_number), "x"(DestX+(2*85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				
			StringSplit, TextSize, TextData, | ;retrieve the length of the string
			if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3)
				WindowWidth := CurrentWidth
			i++ 
		}
	}
	WindowHeight := DestY+Height
	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc,,,WindowWidth,WindowHeight)
	SelectObject(hdc, obm) ; needed else eats ram ; Select the object back into the hdc
	DeleteObject(hbm)   ; needed else eats ram 	; Now the bitmap may be deleted
	DeleteDC(hdc) ; Also the device context related to the bitmap may be deleted
	Return
}	

DrawResourcesOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global a_LocalPlayer, HexColour, a_Player, GameIdentifier, config_file, ResourcesOverlayX, ResourcesOverlayY, MatrixColour, a_pBitmap
	static Font := "Arial", Overlay_RunCount, hwnd1, DragPrevious := 0		
	Overlay_RunCount ++	
	DestX := i := 0
	Options := " cFFFFFFFF r4 s" 17*UserScale					;these cant be static	
	If (Redraw = -1)
	{
		Try Gui, ResourcesOverlay: Destroy
		Overlay_RunCount := 0
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, ResourcesOverlay: Destroy
		Overlay_RunCount := 1
		Redraw := 0
	}
	If (Overlay_RunCount = 1)
	{
		Gui, ResourcesOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, ResourcesOverlay: Show, NA X%ResourcesOverlayX% Y%ResourcesOverlayY% W400 H400, ResourcesOverlay

	;	hwnd1 := WinExist()
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
	}	
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, ResourcesOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, ResourcesOverlay: +E0x20 +LastFound
		WinGetPos,ResourcesOverlayX,ResourcesOverlayY		
		IniWrite, %ResourcesOverlayX%, %config_file%, Overlays, ResourcesOverlayX
		Iniwrite, %ResourcesOverlayY%, %config_file%, Overlays, ResourcesOverlayY		
	}
	
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)		

	For slot_number in a_Player
	{
		If ( a_LocalPlayer["Team"] <> a_Player[slot_number, "Team"] )
		{	DestY := i ? i*Height : 0
			
			If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
			{	
				IF (PlayerIdentifier = 2)
					OptionsName := " Bold cFF" HexColour[a_Player[slot_number, "Colour"]] " r4 s" 17*UserScale
				Else IF (PlayerIdentifier = 1)
					OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale		
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)		
				Width *= UserScale *.5, Height *= UserScale *.5
				gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font) ;get string size	
				if !LongestNameSize
				{
					LongestNameData :=	gdip_TextToGraphics(G, getLongestEnemyPlayerName(a_Player), "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale	, Font) ; text is invisible ;get string size	
					StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
					LongestNameSize := LongestNameSize3
				}
				DestX := LongestNameSize+10*UserScale
			}
			Else If (PlayerIdentifier = 3)
			{	pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"RaceFlat"]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight, MatrixColour[a_Player[slot_number, "Colour"]])
				;Gdip_DisposeImage(pBitmap)
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				DestX := Width+10*UserScale
			}
			Else
			{
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
			}
			
			Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			;Gdip_DisposeImage(pBitmap)
			Gdip_TextToGraphics(G, getPlayerMinerals(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight, TextWidthHeight)				
			pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Gas",Background]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			;Gdip_DisposeImage(pBitmap)
			Gdip_TextToGraphics(G, getPlayerGas(slot_number), "x"(DestX+(85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight,TextWidthHeight)				
				
			pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Supply",Background]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
			;Gdip_DisposeImage(pBitmap)
			TextData := Gdip_TextToGraphics(G, getPlayerSupply(slot_number)"/"getPlayerSupplyCap(slot_number), "x"(DestX+(2*85*UserScale)+Width+3*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight, TextWidthHeight)				
			StringSplit, TextSize, TextData, |			
			if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3)
				WindowWidth := CurrentWidth	
			Height += 5*userscale	;needed to stop the edge of race pic overlap'n due to Supply pic -prot then zerg
			i++ 
		}
	}
	WindowHeight := DestY+Height
	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc,,,WindowWidth,WindowHeight)
	SelectObject(hdc, obm)
	DeleteObject(hbm)
	DeleteDC(hdc)
	Return
}

DrawArmySizeOverlay(ByRef Redraw, UserScale=1, PlayerIdentifier=0, Background=0,Drag=0)
{	global a_LocalPlayer, HexColour, a_Player, GameIdentifier, config_file, ArmySizeOverlayX, ArmySizeOverlayY, MatrixColour, a_pBitmap
	static Font := "Arial", Overlay_RunCount, hwnd1, DragPrevious := 0	
	Overlay_RunCount ++	
	DestX := i := 0
	Options := " cFFFFFFFF r4 Bold s" 17*UserScale					;these cant be static
	If (Redraw = -1)
	{
		Try Gui, ArmySizeOverlay: Destroy
		Overlay_RunCount := 0
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, ArmySizeOverlay: Destroy
		Overlay_RunCount := 1
		Redraw := 0
	}	
	If (Overlay_RunCount = 1)
	{	; Create a layered window ;E0x20 click thru (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption		
		Gui, ArmySizeOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, ArmySizeOverlay: Show, NA X%ArmySizeOverlayX% Y%ArmySizeOverlayY% W400 H400, ArmySizeOverlay
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, ArmySizeOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, ArmySizeOverlay: +E0x20 +LastFound
		WinGetPos,ArmySizeOverlayX,ArmySizeOverlayY		
		IniWrite, %ArmySizeOverlayX%, %config_file%, Overlays, ArmySizeOverlayX
		Iniwrite, %ArmySizeOverlayY%, %config_file%, Overlays, ArmySizeOverlayY	
	}
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)
	For slot_number in a_Player
	{	
		If ( a_LocalPlayer["Team"]  <> a_Player[slot_number, "Team"] )
		{	
		;	DestY := i ? i*Height + 5*UserScale : 0
			DestY := i ? i*Height : 0
			
			If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 )
			{	
				IF (PlayerIdentifier = 2)
					OptionsName := " Bold cFF" HexColour[a_Player[slot_number, "Colour"]] " r4 s" 17*UserScale
				Else IF (PlayerIdentifier = 1)
					OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale	
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font)		
				if !LongestNameSize
				{
					LongestNameData :=	gdip_TextToGraphics(G, getLongestEnemyPlayerName(a_Player), "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale	, Font) ; text is invisible ;get string size	
					StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
					LongestNameSize := LongestNameSize3
				}
				DestX := LongestNameSize+10*UserScale
			}
			Else If (PlayerIdentifier = 3)
			{		
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"RaceFlat"] 
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight, MatrixColour[a_Player[slot_number, "Colour"]])
				;Gdip_DisposeImage(pBitmap)
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				DestX := Width+10*UserScale
			}
			Else
			{
				pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Mineral",Background]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
			}
			Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			;Gdip_DisposeImage(pBitmap)
			Gdip_TextToGraphics(G, ArmyMinerals := getPlayerArmySizeMinerals(slot_number), "x"(DestX+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				
			pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Gas",Background]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
			;Gdip_DisposeImage(pBitmap)
			Gdip_TextToGraphics(G, getPlayerArmySizeGas(slot_number), "x"(DestX+(85*UserScale)+Width+5*UserScale) "y"(DestY+(Height//4)) Options, Font)				
				
		

			pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"Army"]
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5
			Gdip_DrawImage(G, pBitmap, DestX + (2*85*UserScale), DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
			;Gdip_DisposeImage(pBitmap)
			TextData := Gdip_TextToGraphics(G, (ArmyMinerals ? getPlayerSupply(slot_number)-getPlayerWorkerCount(slot_number) : 0)"/"getPlayerSupply(slot_number), "x"(DestX+(2*85*UserScale)+Width+3*UserScale) "y"(DestY+(Height//4)) Options, Font)				
			StringSplit, TextSize, TextData, |
			if (WindowWidth < CurrentWidth := DestX+(2*85*UserScale)+Width+5*UserScale + TextSize3)
				WindowWidth := CurrentWidth				
			i++ 
		}
	}
	WindowHeight := DestY+Height	
	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc,,, WindowWidth, WindowHeight)
	SelectObject(hdc, obm) 
	DeleteObject(hbm)  
	DeleteDC(hdc) 
	Return
}
DrawWorkerOverlay(ByRef Redraw, UserScale=1,Drag=0)
{	global a_LocalPlayer, GameIdentifier, config_file, WorkerOverlayX, WorkerOverlayY, a_pBitmap
	static Font := "Arial", Overlay_RunCount, hwnd1, DragPrevious := 0				
	Options := " cFFFFFFFF r4 s" 18*UserScale
	Overlay_RunCount ++	
	DestX := DestY := 0
	If (Redraw = -1)
	{
		Try Gui, WorkerOverlay: Destroy
		Overlay_RunCount := 0
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, WorkerOverlay: Destroy
		Overlay_RunCount := 1
		Redraw := 0
	}	
	If (Overlay_RunCount = 1)
	{
		Gui, WorkerOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, WorkerOverlay: Show, NA X%WorkerOverlayX% Y%WorkerOverlayY% W400 H400, WorkerOverlay
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
	}
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, WorkerOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, WorkerOverlay: +E0x20 +LastFound
		WinGetPos,WorkerOverlayX,WorkerOverlayY		
		IniWrite, %WorkerOverlayX%, %config_file%, Overlays, WorkerOverlayX
		Iniwrite, %WorkerOverlayY%, %config_file%, Overlays, WorkerOverlayY
	}
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)	
	
	pBitmap := a_pBitmap[a_LocalPlayer["Race"],"Worker"]
	SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
	Width *= UserScale *.5, Height *= UserScale *.5
	Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)	
	;Gdip_DisposeImage(pBitmap)
	Gdip_TextToGraphics(G, getPlayerWorkerCount(a_LocalPlayer["Slot"]), "x"(DestX+Width+2*UserScale) "y"(DestY+(Height//4)) Options, Font, TextWidthHeight, TextWidthHeight)
	Gdip_DeleteGraphics(G)	
	UpdateLayeredWindow(hwnd1, hdc)
	SelectObject(hdc, obm) 
	DeleteObject(hbm)  
	DeleteDC(hdc) 
	Return
}
	
DestroyOverlays()
{	
	Try Gui, MiniMapOverlay: Destroy ;destroy minimap when alttabed out
	Try Gui, IncomeOverlay: Destroy
	Try Gui, ResourcesOverlay: Destroy
	Try Gui, ArmySizeOverlay: Destroy
	Try Gui, WorkerOverlay: Destroy			
	Try Gui, idleWorkersOverlay: Destroy			
	Try Gui, UnitOverlay: Destroy			
}

setDrawingQuality(G)
{	static lastG
	if (lastG <> G)		;as setting these each time is slow
	{	lastG := G
		Gdip_SetSmoothingMode(G, 4)
		Gdip_SetCompositingMode(G, 0) ; 0 = blended, 1= overwrite 
	}
}
Draw(G,x,y,l=11,h=11,colour=0x880000ff, Mode=0) ;use mode 3 to draw rectangle then fill it
{	; Set the smoothing mode to antialias = 4 to make shapes appear smother (only used for vector drawing and filling)
	static pPen, a_pBrush := []
	if Mode	
	{
		if !pPen
			pPen := Gdip_CreatePen(0xFF000000, 1)
		addtorad := 1/minimap.ratio
		;Gdip_DrawRectangle(G, pPen, (x - l/2), (y - h/2), l, h) 	;Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
		Gdip_DrawRectangle(G, pPen, (x - l/2), (y - h/2), l * addtorad , h * addtorad) 	;Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
	}
	if (Mode = 0) || (Mode = 3)
	{
		if !a_pBrush[colour]	;faster than creating same colour again 
			a_pBrush[colour] := Gdip_BrushCreateSolid(colour)
		Gdip_FillRectangle(G, a_pBrush[colour], (x - l/2), (y - h/2), l, h) ;Gdip_FillRectangle(G, pBrush, x, y, l, h)
	}
}

CreatepBitmaps(byref a_pBitmap, a_unitID)
{
	a_pBitmap := []
	l_Races := "Terran,Protoss,Zerg"
	loop, parse, l_Races, `,
	{
		loop, 2
		{
			Background := A_index - 1
			a_pBitmap[A_loopfield,"Mineral",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Mineral_" Background A_loopfield ".png")
			a_pBitmap[A_loopfield,"Gas",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Gas_" Background A_loopfield ".png")			
			a_pBitmap[A_loopfield,"Supply",Background] := Gdip_CreateBitmapFromFile(A_Temp "\Supply_" Background A_loopfield ".png")
		}
		a_pBitmap[A_loopfield,"Worker"] := Gdip_CreateBitmapFromFile(A_Temp "\Worker_0" A_loopfield ".png")
		a_pBitmap[A_loopfield,"Army"] := Gdip_CreateBitmapFromFile(A_Temp "\Army_" A_loopfield ".png")
		a_pBitmap[A_loopfield,"RaceFlat"]  := Gdip_CreateBitmapFromFile(A_Temp "\Race_" A_loopfield "Flat.png")
		a_pBitmap[A_loopfield,"RacePretty"] := Gdip_CreateBitmapFromFile(A_Temp "\" A_loopfield "90.png")
	}
	Loop, %A_Temp%\UnitPanelMacroTrainer\*.png
	{
		StringReplace, FileTitle, A_LoopFileName, .%A_LoopFileExt% ;remove the .ext
		if a_unitID[FileTitle]	;have a 2 pics which arnt in the unit array - bunkerfortified & thorsiegemode
			a_pBitmap[a_unitID[FileTitle]] := Gdip_CreateBitmapFromFile(A_LoopFileFullPath)
	}
	a_pBitmap["PurpleX16"] := Gdip_CreateBitmapFromFile(A_Temp "\PurpleX16.png")
	a_pBitmap["GreenX16"] := Gdip_CreateBitmapFromFile(A_Temp "\GreenX16.png")
	a_pBitmap["RedX16"] := Gdip_CreateBitmapFromFile(A_Temp "\RedX16.png")
}






CreateHotkeys()
{	global
	Hotkeys:	 
	If (input_method = "Event")
		SendMode Event
	Else If (input_method = "play")
		SendMode Play	; causes problems 
	Else ;If (input_method = "input")
		SendMode Input 
	#If, WinActive(GameIdentifier) 
	#If, WinActive(GameIdentifier) && (a_LocalPlayer["Race"] = "Zerg") && !isMenuOpen() && time 
	#If, WinActive(GameIdentifier) && (a_LocalPlayer["Race"] = "Zerg") && (auto_inject <> "Disabled") && time  
	#If, WinActive(GameIdentifier) && (a_LocalPlayer["Race"] = "Protoss") && CG_Enable && time
	#If, WinActive(GameIdentifier) && time && !isMenuOpen() && SelectArmyEnable
	#If, WinActive(GameIdentifier) && time && !isMenuOpen() && SplitUnitsEnable
	#If, WinActive(GameIdentifier) && !isMenuOpen() && time
	#If, WinActive(GameIdentifier) && time
	#If
	if HideTrayIcon
		Hotkey,	%exit_hotkey%, Stealth_Exit, on 
	Hotkey, If, WinActive(GameIdentifier) 														
		hotkey, %speaker_volume_up_key%, speaker_volume_up, on		
		hotkey, %speaker_volume_down_key%, speaker_volume_down, on
		hotkey, %speech_volume_up_key%, speech_volume_up, on
		hotkey, %speech_volume_down_key%, speech_volume_down, on
		hotkey, %program_volume_up_key%, program_volume_up, on
		hotkey, %program_volume_down_key%, program_volume_down, on
		hotkey, %warning_toggle_key%, mt_pause_resume, on		
		hotkey, *~LButton, g_LbuttonDown, on
		hotkey, Lwin, g_DoNothing, on		
	Hotkey, If, WinActive(GameIdentifier) && !isMenuOpen() && time
		hotkey, %ping_key%, ping, on									;on used to re-enable hotkeys as were 
	Hotkey, If, WinActive(GameIdentifier) && time						;turned off during save to allow for swaping of keys
		hotkey, %worker_count_local_key%, worker_count, on
		hotkey, %worker_count_enemy_key%, worker_count, on
		hotkey, %Playback_Alert_Key%, g_PrevWarning, on					
		hotkey, %TempHideMiniMapKey%, g_HideMiniMap, on
		hotkey, %AdjustOverlayKey%, Adjust_overlay, on
		hotkey, %ToggleIdentifierKey%, Toggle_Identifier, on
		hotkey, %ToggleIncomeOverlayKey%, Overlay_Toggle, on
		hotkey, %ToggleResourcesOverlayKey%, Overlay_Toggle, on
		hotkey, %ToggleArmySizeOverlayKey%, Overlay_Toggle, on
		hotkey, %ToggleWorkerOverlayKey%, Overlay_Toggle, on
		hotkey, %CycleOverlayKey%, Overlay_Toggle, on

	
	if race_reading 
		hotkey, %read_races_key%, find_races, on
	if manual_inject_timer
	{	
		hotkey, %inject_start_key%, inject_start, on
		hotkey, %inject_reset_key%, inject_reset, on
	}	
	Hotkey, If, WinActive(GameIdentifier) && time && !isMenuOpen() && SelectArmyEnable
		hotkey, %castSelectArmy_key%, g_SelectArmy, on
	Hotkey, If, WinActive(GameIdentifier) && time && !isMenuOpen() && SplitUnitsEnable
		hotkey, %castSplitUnit_key%, g_SplitUnits, on	
	Hotkey, If, WinActive(GameIdentifier) && (a_LocalPlayer["Race"] = "Zerg") && (auto_inject <> "Disabled") && time
		hotkey, %cast_inject_key%, cast_inject, on	
		hotkey, %F_InjectOff_Key%, Cast_DisableInject, on			
	Hotkey, If, WinActive(GameIdentifier) && (a_LocalPlayer["Race"] = "Protoss") && CG_Enable && time
		hotkey, %Cast_ChronoGate_Key%, Cast_ChronoGates, on		
	Hotkey, If, WinActive(GameIdentifier) && !isMenuOpen() && time
	while (10 > i := A_index - 1)
	{
		if A_UnitGroupSettings["LimitGroup", a_LocalPlayer["Race"], i,"Enabled"] 
			status := "on"
		else status := "off"
		hotkey, ^%i%, g_LimitGrouping, % status
		hotkey, +%i%, g_LimitGrouping, % status
		hotkey, ^+%i%, g_LimitGrouping, % status
	}
	Hotkey, If	
	Return
}

IsInList(Var, items*)
{
	for key, item in items
	{
		If (var = item)
			Return 1
	}
	return 0
}

IniRead(File, Section, Key="", DefaultValue="")
{
	IniRead, Output, %File%, %Section%, %Key%, %DefaultValue%
	Return Output
}

class c_Player
{
	__New(i) 
	{	
		this.Slot := i
		this.Type := getPlayerType(i)
		this.Name := getPlayerName(i)
		this.Team := getPlayerTeam(i)
		this.Race := getPlayerRace(i)
		this.Colour := getPlayerColour(i)
	}
} 

Class c_EnemyUnit
{
	__New(unit) 
	{	
		this.Radius := getMiniMapRadius(Unit)
		this.Owner := getUnitOwner(Unit)
		this.Type := getUnitType(Unit)
		this.X := getUnitPositionX(unit)
		this.Y := getUnitPositionY(unit)
		this.TargetFilter := getUnitTargetFilter(Unit)	
	}
}

;ParseEnemyUnits(ByRef a_LocalUnits, ByRef a_EnemyUnits, ByRef a_Player)
ParseEnemyUnits(ByRef a_EnemyUnits, ByRef a_Player)
{ global DeadFilterFlag
	LocalTeam := getPlayerTeam(), a_EnemyUnitsTmp := []
	While (A_Index <= getUnitCount()) ; Read +10% blanks in a row
	{
		unit := A_Index -1
		Filter := getUnitTargetFilter(unit)	
		If (Filter & DeadFilterFlag) || (type = "Fail")
			Continue
		Owner := getUnitOwner(unit)
		if  (a_Player[Owner, "Team"] <> LocalTeam AND Owner) 
			a_EnemyUnitsTmp[Unit] := new c_EnemyUnit(Unit)
	}
	a_EnemyUnits := a_EnemyUnitsTmp
}



	
getCamCenteredUnit(UnitList) ; |delimited ** ; needs a minimum of 70+ ms to update cam location
{
	CamX := getPlayerCameraPositionX(), CamY := getPlayerCameraPositionY()
	loop, parse, UnitList, |
	{
		delta := Abs(CamX-getUnitPositionX(A_loopfield)) + Abs(CamY-getUnitPositionY(A_loopfield))
		if (delta < delta_closest || A_index = 1)
		{
			delta_closest := delta
			unit_closest := A_loopfield
		}
	}
	StringReplace, UnitList, UnitList,|%unit_closest%
	if !ErrorLevel ;none found
		StringReplace, UnitList, UnitList,%unit_closest%|	
	return unit_closest
}



castInjectLarva(Method="Backspace", ForceInject=0, sleepTime=80)	;SendWhileBlocked("^" CG_control_group)
{	global
	LOCAL HighlightedGroup := getSelectionHighlightedGroup()
;	Send, ^%Inject_control_group%
	send % "^" Inject_control_group
	if (Method="MiniMap" OR ForceInject)
	{

		local xNew, yNew
	;	Send, %MI_Queen_Group%
		if ForceInject
			send % BI_create_camera_pos_x 	;just incase it stuffs up and moves the camera
		send % MI_Queen_Group
		SkipUsedQueen := [] ; blank the queen list
		HatchIndex := getBuildingList(A_unitID["Hatchery"], A_unitID["Lair"], A_unitID["Hive"]) 
		if ((QueenIndex := filterSlectionTypeByEnergy(25, A_unitID["Queen"]))) ; 25=Energy Filter
		{
			loop, parse, HatchIndex, | 
			{	
				CurrentHatch := A_LoopField
				loop, parse, QueenIndex, | 
				{
					IF SkipUsedQueen[A_LoopField] ;This queen has already Injected
						Continue
					Else If areUnitsNearEachOther(A_LoopField, CurrentHatch, MI_QueenDistance, MI_QueenDistance) && isInControlGroup(MI_Queen_Group, A_LoopField) 		
					{
						SkipUsedQueen[A_LoopField] := 1
						Queenused := SkipUsedQueen[A_LoopField]
						getMiniMapMousePos(CurrentHatch, click_x, click_y)	
						Random, Random , -1, 1
						random := 0
					;	Send, %Inject_spawn_larva%
						send % Inject_spawn_larva
						
						click_x := click_x + Random , click_y := click_y + Random 	
						If HumanMouse
							MouseMoveHumanSC2("x" click_x "y" click_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
						send {click Left %click_x%, %click_y%}
						; send {click  %start_x%, %start_y%, 0}

						Sleep, %sleepTime% 

						If ForceInject 		; this will update cursos position if user moves it during a force inject
						{
							MouseGetPos, xNew, yNew
							start_x += xNew - click_x , start_y += yNew - click_y
						}
						Break
					}
				}	
			}	
		}
		if ForceInject
			send % BI_camera_pos_x
	}	
	else if (Method="Backspace Adv") || (Method = "Backspace CtrlGroup") ;cos i changed the name in an update
	{		
		send % BI_create_camera_pos_x
		send % MI_Queen_Group
		HatchIndex := getBuildingList(A_unitID["Hatchery"], A_unitID["Lair"], A_unitID["Hive"]) 
		click_x := A_ScreenWidth/2 , click_y := A_ScreenHeight/2
		If HumanMouse
		{	click_x += rand((-75/1920)*A_ScreenWidth,(75/1080)*A_ScreenHeight), click_y -= 100+rand((-75/1920)*A_ScreenWidth,(75/1080)*A_ScreenHeight)
			MouseMoveHumanSC2("x" click_x  "y" click_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
		}
		else
		{	click_x := A_ScreenWidth/2 , click_y := A_ScreenHeight/2
			MouseMove, click_x, click_y
		}		
		if (QueenIndex := filterSlectionTypeByEnergy(25, A_unitID["Queen"]))
			loop, % getBaseCameraCount()	
			{
				Hatch_i := A_index
				send % base_camera
				if (A_Index = 1)
				{
					HatchList := []
					sleep, 600 ; give time for cam to update slower since WOL 2.04
					CurrentHatch := getCamCenteredUnit(HatchIndex) ;get centered hatch ID
					HatchIndex := SortBasesByBaseCam(HatchIndex, CurrentHatch) ; sort the Hatches by age(to agree with camera list)
					loop, parse, HatchIndex, |
						HatchList[A_Index] := A_loopfield
				}
				else Sleep, %sleepTime%	;sleep needs to be here (to give time to update selection buffer?)				
				loop, parse, QueenIndex, |  	;like this to re-check energy if she injects a macro hatch - checking queen index was previouosly here
				{
					If areUnitsNearEachOther(A_LoopField, HatchList[Hatch_i] , MI_QueenDistance, MI_QueenDistance)
					{
						send % Inject_spawn_larva 	;when # hatches > queens (ie queens going walkabouts)		
						send {click Left %click_x%, %click_y%}				
						Break
					}
				}
			}			
		send % BI_camera_pos_x
	}
	else ; if (Method="Backspace")
	{
		HatchIndex := getBuildingList(A_unitID["Hatchery"], A_unitID["Lair"], A_unitID["Hive"])
		send % BI_create_camera_pos_x
		If (drag_origin = "Right" OR drag_origin = "R") And !HumanMouse ;so left origin - not case sensitive
			Dx1 := A_ScreenWidth-25, Dy1 := 45, Dx2 := 35, Dy2 := A_ScreenHeight-240	
		Else ;left origin
			Dx1 := 25, Dy1 := 25, Dx2 := A_ScreenWidth-40, Dy2 := A_ScreenHeight-240
		loop, % getBaseCameraCount()	
		{
			send % base_camera
			Sleep, sleepTime/2	;need a sleep somerwhere around here to prevent walkabouts...sc2 not registerings box drag?
			If (drag_origin = "Right" OR drag_origin = "R") And HumanMouse ;so left origin - not case sensitive
				Dx1 := A_ScreenWidth-15-rand(0,(360/1920)*A_ScreenWidth), Dy1 := 45+rand(5,(200/1080)*A_ScreenHeight), Dx2 := 40+rand((-5/1920)*A_ScreenWidth,(300/1920)*A_ScreenWidth), Dy2 := A_ScreenHeight-240-rand((-5/1080)*A_ScreenHeight,(140/1080)*A_ScreenHeight)
			Else If (drag_origin = "Left" OR drag_origin = "L") AND HumanMouse ;left origin
				Dx1 := 25+rand((0/1920)*A_ScreenWidth,(360/1920)*A_ScreenWidth), Dy1 := 25+rand((-5/1080)*A_ScreenHeight,(200/1080)*A_ScreenHeight), Dx2 := A_ScreenWidth-40-rand((-5/1920)*A_ScreenWidth,(300/1920)*A_ScreenWidth), Dy2 := A_ScreenHeight-240-rand((-5/1080)*A_ScreenHeight,(140/1080)*A_ScreenHeight)					
			If HumanMouse
			{
				MouseMoveHumanSC2("x" Dx1 "y" Dy1 "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
				send {click down}
				MouseMoveHumanSC2("x" Dx2 "y" Dy2 "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
				send {click up}
			}
			Else 
				send {click down %Dx1%, %Dy1%}{click up, %Dx2%, %Dy2%} 
			Sleep, sleepTime/2	;sleep needs to be here (to give time to update selection buffer?)		
			if (QueenIndex := filterSlectionTypeByEnergy(25, A_unitID["Queen"]))
			{																	
				send % Inject_spawn_larva							;have to think about macro hatch though
				click_x := A_ScreenWidth/2 , click_y := A_ScreenHeight/2		;due to not using Shift - must have 2 queens if on same screen
																				;as will inject only 1 (as it will go to 1 hatch, then get the order to go the other before injecting the 1s)
				If HumanMouse
				{	click_x += rand((-75/1920)*A_ScreenWidth,(75/1080)*A_ScreenHeight), click_y -= 100+rand((-75/1920)*A_ScreenWidth,(75/1080)*A_ScreenHeight)
					MouseMoveHumanSC2("x" click_x  "y" click_y "t" rand(HumanMouseTimeLo, HumanMouseTimeHi))
					send {click Left %click_x%, %click_y%}
				}
				Else send {click Left %click_x%, %click_y%}
				send % Escape ; (deselects queen larva) (useful on an already injected hatch) this is actually a variable
			}	
			
		}
		send % BI_camera_pos_x
	}
	;	Send, %Inject_control_group%
		send % Inject_control_group
		while (A_Index <= HighlightedGroup)
			send {Tab}
}


SortUnitsByAge(unitlist="", units*)
{
	List := []		
	if unitlist		
	{				
		units := []	
		loop, parse, unitlist, |
			units[A_index] := A_LoopField
	}	
	for index, unit in units
		List[A_Index] := {Unit:unit,Age:getUnitTimer(unit)}
	Sort2DArray(List, "Age", 0) ; 0 = descending
	For index, obj in List
		SortedList .= List[index].Unit "|"
	return RTrim(SortedList, "|")
}

getUnitTimer(unit)
{	global 
	return ReadMemory(B_uStructure + unit * S_uStructure + O_uTimer, GameIdentifier)
}

isUnitHoldingXelnaga(unit)
{	global
	if (256 = ReadMemory(B_uStructure + unit * S_uStructure + O_XelNagaActive, GameIdentifier))
		return 1
	else return 0
}

getBaseCamIndex() ; begins at 0
{	global 	
	return pointer(GameIdentifier, B_CurrentBaseCam, P1_CurrentBaseCam)
}

SortBasesByBaseCam(BaseList, CurrentHatchCam)
{
	BaseList := SortUnitsByAge(BaseList)	;getBaseCameraCount()
	loop, parse, BaseList, |
		if (A_loopfield <> CurrentHatchCam)
			if CurrentIndex
				list .= A_LoopField "|"
			else
				LoList .= A_LoopField "|"
		else 
		{
			CurrentIndex := A_index
			list .= A_LoopField "|"
		}

	if LoList
		list := list LoList 
	return RTrim(list, "|")
}

WriteOutWarningArrays() ; this is used to 'save' the current warning arrays to config during a reload
{	global Alert_TimedOut, Alerted_Buildings, Alerted_Buildings_Base, config_file
	l_WarningArrays := "Alert_TimedOut,Alerted_Buildings,Alerted_Buildings_Base"
	loop, parse, l_WarningArrays, `,
	{
		For index, Object in %A_loopfield%
		{
			if (A_index <> 1)
				l_AlertShutdown .= ","
			if (A_loopfield = "Alert_TimedOut")
				For PlayerNumber, object2 in Object	;index = player name
					For Alert, warned_base in Object2
						l_AlertShutdown .= PlayerNumber " " Alert " " warned_base
			else
				For PlayerNumber, warned_base in Object	;index = player number
					l_AlertShutdown .= PlayerNumber " " warned_base	;use the space as the separator - not allowed in sc2 battletags	
		}
		Iniwrite, %l_AlertShutdown%, %config_file%, Resume Warnings, %A_loopfield%		
		l_AlertShutdown := ""
	}
	Iniwrite, 1, %config_file%, Resume Warnings, Resume
}

ParseWarningArrays() ;synchs the warning arrays from the config file after a reload
{	global Alert_TimedOut, Alerted_Buildings, Alerted_Buildings_Base, config_file
	l_WarningArrays := "Alert_TimedOut,Alerted_Buildings,Alerted_Buildings_Base"
	Iniwrite, 0, %config_file%, Resume Warnings, Resume
	loop, parse, l_WarningArrays, `,
	{
		ArrayName := A_loopfield
		%ArrayName% := []
		Iniread, string, %config_file%, Resume Warnings, %ArrayName%, %A_space%
		if string
			loop, parse, string, `,
			{
				StringSplit, VarOut, A_loopfield, %A_Space%
				if (ArrayName = "Alert_TimedOut")
					%ArrayName%[A_index, VarOut1, VarOut2] := VarOut3
				else
					%ArrayName%[A_index, VarOut1] := VarOut2	
			}
	}
	IniDelete, %config_file%, Resume Warnings
}
LoadMemoryAddresses(SC2EXE)
{	global
	;	[Memory Addresses]
	B_LocalPlayerSlot := SC2EXE + 0x10E29C8 	; note 1byte and has a second copy just after +1byte eg LS =16d=10h, hex 1010 (2bytes)
	B_pStructure := SC2EXE + 0x2577EC0			;0x02578EE0 
	S_pStructure := 0xCE0
		O_pName := 0x58
		O_pSupply := 0x848
		O_pSupplyCap := 0x830
		O_pWorkerCount := 0x770
		O_pMinerals := 0x880
		O_pGas := 0x888
		O_pBaseCount := 0x7E0
		O_pColour := 0x158
		O_pTeam := 0x1C
		O_pType := 0x1D
		O_pXcam := 0x8
		O_pYcam := 0xC
		O_pRacePointer := 0x150
		O_pMineralIncome := 0x900, O_pGasIncome := 0x908
		O_pArmyMineralSize := 0xB68, O_pArmyGasSize := 0xB88
	P_IdleWorker := SC2EXE + 0x020AB1B4		
		O1_IdleWorker := 0x194
		O2_IdleWorker := 0x268
	B_Timer := SC2EXE + 0x24C531C				;0x24C633C -1020h
	B_rStructure := SC2EXE + 0x1EC8E00	;old
		S_rStructure := 0x10

	P_ChatFocus := SC2EXE + 0x02097818		;Just when chat box is in focus
		O1_ChatFocus := 0x3D0 
		O2_ChatFocus := 0x198
	
	P_MenuFocus := SC2EXE + 0x03F03C14		;this is all menus and includes chat box when in focus ; old 0x3F04C04
		O1_MenuFocus := 0x1A0
		
	B_uCount := SC2EXE + 0x2CF4588		; This is the units alive (and includes missiles) ;0x02CF5588			
	B_uHighestIndex := SC2EXE + 0x25F4700		;this is actually the highest currently alive unit (includes missiles while alive)
	B_uStructure := SC2EXE + 0x25F4740			 ;0x25F5740	
	S_uStructure := 0x1C0
		O_uModelPointer := 0x8
		O_uTargetFilter := 0x14
		O_uBuildStatus := 0x18		; buildstatus is really part of the 8 bit targ filter!
		O_uOwner := 0x3D
		O_uX := 0x48
		O_uY := 0x4C
		O_uZ := 0x50
		O_P_uCmdQueuePointer := 0xD0
		O_P_uAbilityPointer := 0xD8
		O_uChronoState := 0xE2

		O_uEnergy := 0x118
		O_uTimer := 0x168
		O_XelNagaActive := 0x34
	;CommandQue
	O_cqMoveState := 0x40
	
	; Unit Model Structure	
	O_mUnitID := 0x6	
	O_mMiniMapSize := 0x39C
	O_mSubgroupPriority := 0x398
	; selection and ctrl groups
	B_SelectionStructure := SC2EXE + 0x0215AF90 	
	B_CtrlGroupStructure := SC2EXE + 0x021601B8 
	S_CtrlGroup := 0x1B60
	S_scStructure := 0x4	; Unit Selection & Ctrl Group Structures
		O_scTypeCount := 0x2
		O_scTypeHighlighted := 0x4
		O_scUnitIndex := 0x8
	P_PlayerColours := SC2EXE + 0x03D23EC4 ; 0 when enemies red  1 when player colours
		O1_PlayerColours := 0x4
		O2_PlayerColours := 0x17c
		
	P_SelectionPage := SC2EXE + 0x02097818 ;theres one other 3 lvl pointer
		O1_SelectionPage := 0x35C			;this is for the currently selected unit portrait page ie 1-6 in game (really starts at 0-5)
		O2_SelectionPage := 0x180			;might actually be a 2 or 1 byte value....but works fine as 4
		O3_SelectionPage := 0x170
		
	DeadFilterFlag := 0x0000000200000000	
	BuriedFilterFlag :=	0x0000000010000000
	
	B_MapStruct := SC2EXE + 0x024C52B4   ;-1020h
		O_mLeft := B_MapStruct + 0xDC	                                   
		O_mBottom := B_MapStruct + 0xE0	                                   
		O_mRight := B_MapStruct + 0xE4	                                    
		O_mTop := B_MapStruct + 0xE8	   

	uMovementFlags := {Amove: 0
	, Patrol: 1
	, HoldPosition: 2
	, Move: 256
	, Follow: 512
	, FollowNoAttack: 515} ; This is used by unit spell casters such as infestors and High temps which dont have a real attack 
	; note I have Converted these hex numbers from their true decimal conversion 
	; so that they can be used as bit flags with bit wise &

	P_IsUserCasting := SC2EXE + 0x02097818	; this is probably something to do with the cursor icon or control card
		O1_IsUserCasting := 0x364 			; 1 indicates user is casting a spell e.g. fungal, snipe, or is trying to place a structure
		O2_IsUserCasting := 0x19C 			; auto casting e.g. swarm host displays 1 always 
		O3_IsUserCasting := 0x228
		O4_IsUserCasting := 0x168

		
		
	return	
	
	
/* Not Currently used
	B_CameraBounds := SC2EXE + 0x209A094
		O_x0Bound := 0x0
		O_XmBound := 0x8
		O_Y0Bound := 0x04
		O_YmBound := 0x0C
	
	B_CurrentBaseCam := 0x017AB3C8	;not current
		P1_CurrentBaseCam := 0x25C		;not current
*/	
}

g_SplitUnits:
	BufferInput(aButtons.List, "Buffer", 0)
	SplitUnits(SplitctrlgroupStorage_key, SleepSplitUnits)
	BufferInput(aButtons.List) ;re-enable keys without sending buffer
	return
	
g_SelectArmy:
	ReleaseModifiers(ModifierBeepSelectArmy)
	BufferInput(aButtons.List, "Buffer", 0)
	send %Sc2SelectArmy_Key%
	sleep SleepSelectArmy ; every now and then it needs a few ms to update
	mousegetpos, Xarmyselect, Yarmyselect
	BlockInput, MouseMove
	a_RemoveUnits := []
	findUnitsToRemoveFromArmy(a_RemoveUnits, SelectArmyDeselectXelnaga, SelectArmyDeselectPatrolling
		, SelectArmyDeselectHoldPosition, SelectArmyDeselectFollowing, l_ActiveDeselectArmy)
	if a_RemoveUnits.MaxIndex()
	{
		Sort2DArray(a_RemoveUnits, "Unit", 0) ;clicks highest units first, so dont have to calculate new click positions due to the units moving down one spot in the panel grid	
		Sort2DArray(a_RemoveUnits, "Priority", 1)	; sort in ascending order so select units lower down 1st		
		DeselectUnitsFromPanel(a_RemoveUnits, DeselectSleepTime)
		send {click  %Xarmyselect%, %Yarmyselect%, 0}
	}
	if SelectArmyControlGroupEnable
		send ^%Sc2SelectArmyCtrlGroup%
	BlockInput, MouseMoveOff
	BufferInput(aButtons.List) ;re-enable keys without sending buffer
return

getScreenAspectRatio()
{
	if ((AspectRatio := A_ScreenWidth / A_ScreenHeight) = 1680/1050)
		AspectRatio := "16:10"
	else if (AspectRatio = 1920/1080)
		AspectRatio := "16:9"
	else if (AspectRatio = 1280/1024)
		AspectRatio := "5:4"
	else if (AspectRatio = 1600/1200)
		AspectRatio := "4:3"
	else AspectRatio := "Unkown"
	return AspectRatio
}
findUnitsToRemoveFromArmy(byref a_Units, DeselectXelnaga = 1, DeselectPatrolling = 1, DeselectHoldPosition = 0, DeselectFollowing = 0, l_Types = "")
{ global uMovementFlags
	while (A_Index <= getSelectionCount())		;loop thru the units in the selection buffer	
	{		
		unit := getSelectedUnitIndex(A_Index -1)
		state := getUnitMoveState(unit)	
		if (DeselectXelnaga && isUnitHoldingXelnaga(unit))
		|| (DeselectPatrolling && state = uMovementFlags.Patrol)
		|| (DeselectHoldPosition && state = uMovementFlags.HoldPosition)
		|| (DeselectFollowing && (state = uMovementFlags.Follow || state = uMovementFlags.FollowNoAttack)) ;no attack follow is used by spell casters e.g. HTs & infests which dont have and attack
			a_Units.insert({"Unit": unit, "Priority": getSubGroupPriority(unit)})
		if l_Types  
		{
			type := getunittype(unit)
			If type in %l_Types%
				a_Units.insert({"Unit": unit, "Priority": getSubGroupPriority(unit)})
		}
	}
	return
}



SortSelectedUnits(byref a_Units)
{
	a_Units := []
	i := getSelectionCount()
	while (A_index  <= i)
		a_Units.insert({"Unit": unit := getSelectedUnitIndex(A_Index-1), "Priority": getSubGroupPriority(unit)})
	Sort2DArray(a_Units, "Unit") ; sort in ascending order
	Sort2DArray(a_Units, "Priority", 0)	; sort in descending order
	return
}	

DeselectUnitsFromPanel(a_RemoveUnits, sleep=20)	
{
	if a_RemoveUnits.MaxIndex()
	{
		SortSelectedUnits(a_SelectedUnits)
		for Index, objRemove in a_RemoveUnits
			for SelectionIndex, objSelected in a_SelectedUnits
				if (objRemove.unit = objSelected.unit && SelectionIndex < 144 ) ;can only deselect up to unitselectionindex 143 (as thats the maximun on the card)
				{
					if ClickUnitPortrait(SelectionIndex - 1, X, Y, Xpage, Ypage) ; -1 as selection index begins at 0 i.e 1st unit at pos 0 top left
						send {click Left %Xpage%, %Ypage%} ;clicks on the page number				
					send +{click Left %X%, %Y%} 	;shift clicks the unit
					sleep, sleep
				}
	}
	if getUnitSelectionPage()	;ie slection page is not 0 (hence its not on 1 (1-1))
	{
		ClickUnitPortrait(blank,X,Y, Xpage, Ypage, 1) ; this selects page 1 when done
		send {click Left %Xpage%, %Ypage%}
	}	
	return
}

ClickUnitPortrait(SelectionIndex=0, byref X=0, byref Y=0, byref Xpage=0, byref Ypage=0, ClickPageTab = 0) ;SelectionIndex begins at 0 topleft unit
{
	AspectRatio := getScreenAspectRatio()
	If (AspectRatio = "16:10")
	{
		Xu0 := (578/1680)*A_ScreenWidth, Yu0 := (888/1050)*A_ScreenHeight	;X,Yu0 = the middle of unit portrait 0 ( the top left unit)
		Size := (56/1680)*A_ScreenWidth										;the unit portrait is square 56x56
		Xpage1 := (528/1680)*A_ScreenWidth, Ypage1 := (877/1050)*A_ScreenHeight, Ypage6 := (1016/1050)*A_ScreenHeight	;Xpage1 & Ypage6 are locations of the Portrait Page numbers 1-5 
	}	
	Else If (AspectRatio = "5:4")
	{	
		Xu0 := (400/1280)*A_ScreenWidth, Yu0 := (876/1024)*A_ScreenHeight
		Size := (51.57/1280)*A_ScreenWidth
		Xpage1 := (352/1280)*A_ScreenWidth, Ypage1 := (864/1024)*A_ScreenHeight, Ypage6 := (992/1024)*A_ScreenHeight
	}	
	Else If (AspectRatio = "4:3")
	{	
		Xu0 := (400/1280)*A_ScreenWidth, Yu0 := (812/960)*A_ScreenHeight
		Size := (51.14/1280)*A_ScreenWidth
		Xpage1 := (350/1280)*A_ScreenWidth, Ypage1 := (800/960)*A_ScreenHeight, Ypage6 := (928/960)*A_ScreenHeight
	}
	Else if (AspectRatio = "16:9")
	{
		Xu0 := (692/1920)*A_ScreenWidth, Yu0 := (916/1080)*A_ScreenHeight
		Size := (57/1920)*A_ScreenWidth	;its square
		Xpage1 := (638/1920)*A_ScreenWidth, Ypage1 := (901/1080)*A_ScreenHeight, Ypage6 := (1044/1080)*A_ScreenHeight

	}
	YpageDistance := (Ypage6 - Ypage1)/5		;because there are 6 pages - 6-1
	
	if ClickPageTab	;use this to return the selection back to page 1
	{
		PageIndex := ClickPageTab - 1
		Xpage := Xpage1, Ypage := Ypage1 + (PageIndex * YpageDistance)
		return 1
	}
	
	PageIndex := Offset_y := Offset_x := 0
	while (SelectionIndex > 24 * A_index - 1)
		PageIndex++
	SelectionIndex -= 24 * PageIndex
	while (SelectionIndex > 8 * A_index - 1)
		Offset_y++
	Offset_x := SelectionIndex -= 8 * Offset_y		
	x := Xu0 + (Offset_x *Size), Y := Yu0 + (Offset_y *Size)
	if (PageIndex <> getUnitSelectionPage())
	{
		Xpage := Xpage1, Ypage := Ypage1 + (PageIndex * YpageDistance)
		return 1 ; indicating that you must left click the index page first
	}
	return 0	
}
		
FindSelectedUnitsOnXelnaga(byref a_Units)
{
	while (A_Index <= getSelectionCount())		;loop thru the units in the selection buffer	
		if isUnitHoldingXelnaga(unit := getSelectedUnitIndex(A_Index -1))
			a_Units.insert({"Unit": unit, "Priority": getSubGroupPriority(unit)})
	return
}

FindSelectedPatrollingUnits(byref a_Units)
{
	while (A_Index <= getSelectionCount())		;loop thru the units in the selection buffer	
		if isUnitPatrolling(unit := getSelectedUnitIndex(A_Index -1))
			a_Units.insert({"Unit": unit, "Priority": getSubGroupPriority(unit)})
	return
}
sortSelectedUnitsByDistance(byref a_SelectedUnits, Amount = 3)	;takes a simple array which contains the selection indexes (begins at 0)
{ 													; the 0th selection index (1st in this array) is taken as the base unit to measure from
	a_SelectedUnits := []
	sIndexBaseUnit := rand(0, getSelectionCount() -1) ;randomly pick a base unit 
	uIndexBase := getSelectedUnitIndex(sIndexBaseUnit)
	Base_x := getUnitPositionX(uIndexBase), Base_y := getUnitPositionY(uIndexBase)
	a_SelectedUnits.insert({"Unit": uIndexBase, "Priority": getSubGroupPriority(uIndexBase), "Distance": 0})
	
	while (A_Index <= getSelectionCount())	
	{
		unit := getSelectedUnitIndex(A_Index -1)
		if (sIndexBaseUnit = A_Index - 1)
			continue 
		else
		{
			unit_x := getUnitPositionX(unit), unit_y := getUnitPositionY(unit)
			a_SelectedUnits.insert({"Unit": unit, "Priority": getSubGroupPriority(unit), "Distance": Abs(Base_x - unit_x) + Abs(Base_y - unit_y)})
		}
	}
	Sort2DArray(a_SelectedUnits, "Distance", 1)
	while (a_SelectedUnits.MaxIndex() > Amount)
		a_SelectedUnits.Remove(a_SelectedUnits.MaxIndex()) 	
	Sort2DArray(a_SelectedUnits, "Unit", 0) ;clicks highest units first, so dont have to calculate new click positions due to the units moving down one spot in the panel grid	
	Sort2DArray(a_SelectedUnits, "Priority", 1)	; sort in ascending order so select units lower down 1st	
	return 
} 


getUnitSelectionPage()	;0-5 indicates which unit page is currently selected (in game its 1-6)
{	global 	
	return pointer(GameIdentifier, P_SelectionPage, O1_SelectionPage, O2_SelectionPage, O3_SelectionPage)
}

debugData()
{ 	global a_Player
	Player := getLocalPlayerNumber()
	return data := "GetGameType: " GetGameType(a_Player) "`n"
	. "Enemy Team Size: " getEnemyTeamsize() "`n"
	. "Time: " gettime() "`n"
	. "Idle Workers: " getIdleWorkers() "`n"
	. "Supply/Cap: " getPlayerSupply() "/" getPlayerSupplyCap() "`n"
	. "Gas: " getPlayerGas() "`n"
	. "Money: " getPlayerMinerals() "`n"
	. "GasIncome: " getPlayerGasIncome() "`n"
	. "MineralIncome: " getPlayerMineralIncome() "`n"
	. "BaseCount: " getBaseCameraCount() "`n"
	. "LocalSlot: " getLocalPlayerNumber() "`n"
	. "Colour: " getplayercolour(Player) "`n"
	. "Team: " getplayerteam(Player) "`n"
	. "Type: " getPlayerType(Player) "`n"
	. "Local Race: " getPlayerRace(Player) "`n"
	. "Local Name: " getPlayerName(Player) "`n"
	. "Unit Count: " getUnitCount() "`n"
	. "Selected Unit: `n"
	. A_Tab "Index u1: " getSelectedUnitIndex() "`n"
	. A_Tab "Type u1: " getunittype(getSelectedUnitIndex()) "`n"
	. A_Tab "Priority u1: " getSubGroupPriority(getSelectedUnitIndex()) "`n"
	. A_Tab "Count: " getSelectionCount() "`n"
	. A_Tab "Owner: " getUnitOwner(getSelectedUnitIndex()) "`n"
	. A_Tab "Timer: " getUnitTimer(getSelectedUnitIndex()) "`n"
	. A_Tab "Mmap Radius: " getMiniMapRadius(getSelectedUnitIndex()) "`n" 
	. A_Tab "Energy: " getUnitEnergy(getSelectedUnitIndex()) "`n" 
	. "Chat Focus: " isChatOpen() "`n"
	. "Menu Focus: " isMenuOpen() "`n"
	. "Map: `n"
	. A_Tab "Map Left: " getMapLeft() "`n"
	. A_Tab "Map Right: " getMapRight() "`n"
	. A_Tab "Map Bottom: " getMapBottom() "`n"
	. A_Tab "Map Top: " getMapTop() "`n"
}

SplitUnits(SplitctrlgroupStorage_key, SleepSplitUnits)
{
	uSpacing := 4
	sleep, % SleepSplitUnits
	send ^%SplitctrlgroupStorage_key%
	BlockInput, MouseMove
	mousegetpos, Xorigin, Yorigin
	a_SelectedUnits := []
	xSum := ySum := 0
	while (A_Index <= getSelectionCount())	
	{
		unit := getSelectedUnitIndex(A_Index -1)
		getMiniMapMousePos(unit, mX, mY)
		a_SelectedUnits.insert({"Unit": unit, "mouseX": mX, "mouseY": mY, absDistance: ""})
	}

	for index, unit in a_SelectedUnits
		xSum += unit.mouseX, ySum += unit.mouseY
	xAvg := xSum/a_SelectedUnits.MaxIndex(), yAvg := ySum/a_SelectedUnits.MaxIndex()	
	while (a_SelectedUnits.MaxIndex() > squareSpots := A_Index * A_Index)
		continue	
;	botLeftUnitX := xAvg-(sqrt(squareSpots)*uSpacing)/2 , botLeftUnitY := yAvg-(sqrt(squareSpots)*uSpacing)/2 ; should /2?? but is betr without it
	botLeftUnitX := xAvg-sqrt(squareSpots) , botLeftUnitY := yAvg-sqrt(squareSpots) ; should /2?? but is betr without it
	
;	clipboard := ""

	while (getSelectionCount() > 1)
	{
		Sort2DArray(a_SelectedUnits, "absDistance", 1) 
		unit := a_SelectedUnits[1] ;grab the closest unit
		boxSpot := A_Index
		X_offsetbox := y_offsetbox := 0
		while (boxSpot > floor(sqrt(squareSpots) * A_Index))
			y_offsetbox ++
			
		X_offsetbox := (boxSpot - 1) - sqrt(squareSpots) * y_offsetbox
		
		x := X_offsetbox*uSpacing + botLeftUnitX, Y := y_offsetbox*uSpacing + botLeftUnitY
		;x := round(x), y := round(y)	;cos mousemove ignores decimal 
		x := round(x + rand(-.5,.5)), y := round(y + rand(-.5,.5)) 	;cos mousemove ignores decimal 
		for index, unit in a_SelectedUnits
			unit.absDistance := Abs(x - unit.mouseX) + Abs(y - unit.mouseY)
;		clipboard .= "(" x ", " y ")`n"
		
		Sort2DArray(a_SelectedUnits, "absDistance", 1)		
		tmpObject := []
		tmpObject.insert(a_SelectedUnits[1])
		send {click right %X%, %Y%}
		DeselectUnitsFromPanel(tmpObject, DeselectSleepTime)		;might not have enough time to update the selections?
		a_SelectedUnits.remove(1)
		if (a_SelectedUnits.MaxIndex() <= 1)
			break
	}
;	clipboard .= "avg (" xavg ", " yavg ")`n"
;	clipboard .= "BL (" botLeftUnitX ", " botLeftUnity ")`n"
;	clipboard .= "Squarespots: " squareSpots "`n"
	send %SplitctrlgroupStorage_key%
	BlockInput, MouseMoveOff
	send {click %Xorigin%, %Yorigin%, 0}
		return
}



SplitUnitsWorking(SplitctrlgroupStorage_key, SleepSplitUnits)
{
	send ^%SplitctrlgroupStorage_key%
	mousegetpos, Xorigin, Yorigin
	a_SelectedUnits := []
	xSum := ySum := 0
	while (A_Index <= getSelectionCount())	
	{
		unit := getSelectedUnitIndex(A_Index -1)
		getMiniMapMousePos(unit, mX, mY)
		a_SelectedUnits.insert({"Unit": unit, "mouseX": mX, "mouseY": mY})
	}
	Sort2DArray(a_SelectedUnits, "Unit", 0) ;clicks highest units first, so dont have to calculate new click positions due to the units moving down one spot in the panel grid	
	Sort2DArray(a_SelectedUnits, "Priority", 1)	; sort in ascending order so select units lower down 1st	
		
	for index, unit in a_SelectedUnits
		xSum += unit.mouseX, ySum += unit.mouseY
	xAvg := xSum/a_SelectedUnits.MaxIndex(), yAvg := ySum/a_SelectedUnits.MaxIndex()

	while (getSelectionCount() > 1)
	{
		unit := a_SelectedUnits[1]
	;	xR := rand(-2,2), yR := rand(-2,2)
		FindAngle(Direction, Angle, xAvg,yAvg,unit.mouseX,unit.mouseY)
		FindXYatAngle(X, Y, Angle, Direction, 4, unit.mouseX, unit.mouseY)
		x += rand(-2,2), y += rand(-2,2)
		send {click right %X%, %Y%}
		tmpObject := []
		tmpObject.insert(a_SelectedUnits[1])
		DeselectUnitsFromPanel(tmpObject, SleepSplitUnits)
		a_SelectedUnits.remove(1)
		if (a_SelectedUnits.MaxIndex() <= 3)
			break
	}
	send %SplitctrlgroupStorage_key%
	send {click  %Xorigin%, %Yorigin%, 0}
		return
}









FindAngle(byref Direction, byref Angle, x1,y1,x2,y2)
{
	v1 := [], v2 := [], vR := []
	v1.x := x1, v1.y := y1	;avg
	v2.x := x2, v2.y := y2

	vR.x := v2.x - v1.x, vR.y := v2.y - v1.y


	Vr.l := sqrt(vR.x**2 + vR.y**2)
	pi := 4 * ATan(1)
	a := abs(vR.x)	;side adjacent angle
	b := abs(vR.y)	;side opposite angle
	c := Vr.l
	if (abs(vR.x) >= abs(vR.y))
		Angle := Asin(b/c) * 180/pi 
	else
		Angle := Asin(b/c) * 180/pi 
	if 	(vR.x > 0)
		Direction := "R"
	else Direction := "L"
	if (vR.y > 0)
		Direction .= "U"
	else Direction .= "D"
	;dir RU, RD, LU, LD
return
}

FindXYatAngle(byref ResultX, byref ResultY,	Angle, Direction, distance, X, Y)
{
	pi := 4 * ATan(1)
	AngleRad :=  pi/180 * Angle
	c := distance
	a := C*cos(AngleRad) 
	b := c*sin(AngleRad) 
	if Direction contains R
		ResultX :=  X + b
	if Direction contains L
		ResultX :=  X - b
	if Direction contains U
		ResultY := Y + a
	if Direction contains D
		ResultY := Y - a
	return
}



getWarpGateCooldown(WarpGate) ; unitIndex
{	global B_uStructure, S_uStructure, O_P_uAbilityPointer, GameIdentifier
	u_AbilityPointer := B_uStructure + WarpGate * S_uStructure + O_P_uAbilityPointer
	ablilty := ReadMemory(u_AbilityPointer, GameIdentifier) & 0xFFFFFFFC
	p1 := ReadMemory(ablilty + 0x28, GameIdentifier)	
	if !(p2 := ReadMemory(p1 + 0x1C, GameIdentifier)) ; 0 if it has never warped in a unit
		return 0
	p3 := ReadMemory(p2 + 0xC, GameIdentifier)
	return ReadMemory(p3 + 0x6, GameIdentifier, 2)
}
getUnitAbilityPointer(unit)
{	global
	return ReadMemory(B_uStructure + unit * S_uStructure + O_P_uAbilityPointer, GameIdentifier) & 0xFFFFFFFC
}

isUnitChronoed(unit)
{	global	; 1 byte = 18h chrono for protoss structures 10h normal state
	if (24 = ReadMemory(B_uStructure + unit * S_uStructure + O_uChronoState, GameIdentifier, 1))	
		return 1
	else return 0
}

isWorkerInProduction(unit) ; units can only be t or P, no Z
{										;state = 1 in prod, 0 not, -1 if doing something else eg flying
	local state
	local type := getUnitType(unit)
	if (type = A_unitID["CommandCenterFlying"] || type = A_unitID["OrbitalCommandFlying"])
		state := -1
	else if ( type = A_unitID["Nexus"]) 	
	{
		local p2 := ReadMemory(getUnitAbilityPointer(unit) + 0x24, GameIdentifier)
		state := ReadMemory(p2 + 0x88, GameIdentifier, 1)
		if (state = 0x43)	;probe Or mothership	
			state := 1
		else 	; idle 0x3
			state := 0
	}
	Else if (type = A_unitID["CommandCenter"])
	{
		 state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
		if (state = 0x12)	;scv in produ
			state := 1
		else if (state = 32 || state = 64)	;0x0A = flying 32 ->PF | 64 -> orbital
			state := -1										; yeah i realise this flying wont e
		else ; state = 0x76 idle
			state := 0
	}
	Else if  (type =  A_unitID["PlanetaryFortress"])
	{
		local p1 := ReadMemory(getUnitAbilityPointer(unit) + 0x34, GameIdentifier)
		state := ReadMemory(p1 + 0x4E4, GameIdentifier, 1) ; wrong - 0x180
		if (state = 0x43)
			state := 1
		else state := 0 ; 0x3
	}
	else if (type =  A_unitID["OrbitalCommand"])
	{
		state := ReadMemory(getUnitAbilityPointer(unit) + 0x9, GameIdentifier, 1)
		if (state = 0x11)	;scv
			state := 1
		else state := 0 ; 99h  	;else if (state = 0)	;flying
	}
	return state
}

return







getEnemyUnits(byref aEnemyUnits, byref aEnemyBuildingConstruction)
{
	GLOBAL DeadFilterFlag, a_Player, a_LocalPlayer, a_UnitTargetFilter
	aEnemyUnits := [], aEnemyBuildingConstruction := []
	While (A_Index <= getHighestUnitIndex()) 
	{
		unit := A_Index - 1
		TargetFilter := getUnitTargetFilter(unit)
		If (TargetFilter & DeadFilterFlag)
			Continue
		Owner := getUnitOwner(unit)
		If  (a_Player[Owner, "Team"] <> a_LocalPlayer["Team"] AND Owner) ; Owner 0 = neutral
		{
			Type := getunittype(unit)
			if (TargetFilter & a_UnitTargetFilter.UnderConstruction)
			{
				aEnemyBuildingConstruction[Owner, Type] := aEnemyBuildingConstruction[Owner, Type] ? aEnemyBuildingConstruction[Owner, Type] + 1 : 1
				aEnemyBuildingConstruction[Owner, "TotalCount"] := aEnemyBuildingConstruction[Owner, "TotalCount"] ? aEnemyBuildingConstruction[Owner, "TotalCount"] + 1 : 1	
			}		; this is a cheat and very lazy way of incorporating a count into the array without stuffing the for loop and having another variable
			Else
				aEnemyUnits[Owner, Type] := aEnemyUnits[Owner, Type] ? aEnemyUnits[Owner, Type] + 1 : 1 ;note +1 (++ will not work!!!)
		}
	}
	Return
}

FilterUnits(byref aEnemyUnits, byref aEnemyBuildingConstruction, byref aUnitID, a_Player)	;care have used A_unitID everywhere else!!
{	
	;	aEnemyUnits[Owner, Type]
	STATIC aRemovedUnits := {"Terran": ["BarracksTechLab","BarracksReactor","FactoryTechLab","FactoryReactor","StarportTechLab"]
							, "Protoss": ["Interceptor"]
							, "Zerg": ["OverlordCocoon","CreepTumorBurrowed","Broodling","Locust"]}

	STATIC aAddUnits 	:=	{"Terran": {SupplyDepotLowered: "SupplyDepot"}
							, "Protoss": {DroneBurrowed: "Drone"} 
							, "Zerg": {DroneBurrowed: "Drone", ZerglingBurrowed: "Zergling", HydraliskBurrowed: "Hydralisk", UltraliskBurrowed: "Ultralisk", RoachBurrowed: "Roach"
							, InfestorBurrowed: "Infestor", BanelingBurrowed: "Baneling", QueenBurrowed: "Queen", SporeCrawlerUprooted: "SporeCrawler", SpineCrawlerUprooted: "SpineCrawler"  
							, Zergling: "BanelingCocoon"}}

									; note - could have just done - if name contains "Burrowed" check, substring = minus burrowed
									; overlorrd cocoon = morphing overseer
									;also need to account for morphing drones into buildings 

	for owner, object in aEnemyUnits
	{
		aDeleteKeys := []					;****have to 'save' the delete keys, as deleting them during a for loop will cause you to go +2 keys on next loop, not 1
		race := a_Player[owner, "Race"]		;it doesn't matter if it attempts to delete the same key a second time (doesn't effect anything)
		for unit, count in object
		{

			if  (unit < aUnitID["Colossus"])	;as colossus is first real unit
			{
				aDeleteKeys.insert(unit)	;object.remove(unit, "")
				continue
			}
			for index, removeUnit in aRemovedUnits[race]
				if (unit = aUnitID[removeUnit])
				{
					aDeleteKeys.insert(unit)
					continue
				}					
		}
		if (race = "Zerg" && object[aUnitID["Drone"]] && aEnemyBuildingConstruction[Owner, "TotalCount"])
			object[aUnitID["Drone"]] -= aEnemyBuildingConstruction[Owner, "TotalCount"] ; as drones morphing are still counted as 'alive' so have to remove them

		for subUnit, mainUnit in aAddUnits[Race]
			if (total := object[subUnit])
			{
				mainUnit := aUnitID[mainUnit]
				if object[mainUnit]
					object[mainUnit] += total
				else object[mainUnit] := total
					aDeleteKeys.insert(unit) 
			}
		for index, unit in aDeleteKeys
			object.remove(unit, "")				; **********	remove(unit, "") Removes an integer key and returns its value, but does NOT affect other integer keys.
												;				as the keys are integers, otherwise it will decrease the keys afterwards by 1 for each removed unit!!!!
	}
	return

}

; unit 123 owner 4

!F1::
msgbox % getSelectionType(0) "`n" getUnitOwner(getSelectedUnitIndex()) "`n" isUnderConstruction(getSelectedUnitIndex()) "`n" getSubGroupPriority(getSelectedUnitIndex())

return

!F2::
;	getEnemyUnits(aEnemyUnits, aEnemyBuildingConstruction)
;	FilterUnits(aEnemyUnits, aEnemyBuildingConstruction, a_UnitID, a_Player)
objtree(a_Player)
objtree(a_LocalPlayer)
msgbox % getLongestEnemyPlayerName(a_Player)
return

getLongestEnemyPlayerName(a_Player)
{
	localTeam := getPlayerTeam(getLocalPlayerNumber())
	for index, Player in a_Player
		if (player.team != localTeam && StrLen(player.name) > StrLen(LongestName))
			LongestName := player.name
	return player.name
}

DrawUnitOverlay(ByRef Redraw, UserScale = 1, PlayerIdentifier = 0, Drag = 0)
{
	GLOBAL aEnemyUnits, aEnemyBuildingConstruction, a_pBitmap, a_Player, a_LocalPlayer, HexColour, GameIdentifier, config_file, UnitOverlayX, UnitOverlayY, MatrixColour 
	static Font := "Arial", Overlay_RunCount, hwnd1, DragPrevious := 0, a_pBrush := [], TransparentBlack := 0x78000000
	Overlay_RunCount ++	
	DestX := i := 0
	Options := "Center cFFFFFFFF r4 s" 17*UserScale					;these cant be static	
	If (Redraw = -1)
	{
		Try Gui, UnitOverlay: Destroy
		Overlay_RunCount := 0
		Redraw := 0
		Return
	}	
	Else if (ReDraw AND WinActive(GameIdentifier))
	{
		Try Gui, UnitOverlay: Destroy
		Overlay_RunCount := 1
		Redraw := 0
	}
	If (Overlay_RunCount = 1)
	{
		Gui, UnitOverlay: -Caption Hwndhwnd1 +E0x20 +E0x80000 +LastFound  +ToolWindow +AlwaysOnTop
		Gui, UnitOverlay: Show, NA X%UnitOverlayX% Y%UnitOverlayY% W400 H400, UnitOverlay
		OnMessage(0x201, "OverlayMove_LButtonDown")
		OnMessage(0x20A, "OverlayResize_WM_MOUSEWHEEL")
		if !a_pBrush[TransparentBlack]	;faster than creating same colour again 
			a_pBrush[TransparentBlack] := Gdip_BrushCreateSolid(TransparentBlack)	; Create a partially transparent, black brush
	}	
	If (Drag AND !DragPrevious)
	{	DragPrevious := 1
		Gui, UnitOverlay: -E0x20
	}
	Else if (!Drag AND DragPrevious)
	{	DragPrevious := 0
		Gui, UnitOverlay: +E0x20 +LastFound
		WinGetPos,UnitOverlayX,UnitOverlayY		
		IniWrite, %UnitOverlayX%, %config_file%, Overlays, UnitOverlayX
		Iniwrite, %UnitOverlayY%, %config_file%, Overlays, UnitOverlayY		
	}
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	DllCall("gdiplus\GdipGraphicsClear", "UInt", G, "UInt", 0)
	setDrawingQuality(G)	
	for slot_number, object in aEnemyUnits ; slotnumber = owner and slotnuber is an object
	{
		DestY := i ? i*Height : 0
		DestX := 0
		for unit, unitCount in object
		{
			If (PlayerIdentifier = 1 Or PlayerIdentifier = 2 ) && (A_Index = 1)
			{	
				IF (PlayerIdentifier = 2)
					OptionsName := " Bold cFF" HexColour[a_Player[slot_number, "Colour"]] " r4 s" 17*UserScale
				Else IF (PlayerIdentifier = 1)
					OptionsName := " Bold cFFFFFFFF r4 s" 17*UserScale		
				pBitmap := a_pBitmap[unit]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5
				gdip_TextToGraphics(G, getPlayerName(slot_number), "x0" "y"(DestY+(Height//4))  OptionsName, Font) ;get string size	
			;	StringSplit, TextSize, TextData, | ;retrieve the length of the string		
				if !LongestNameSize
				{
					LongestNameData :=	gdip_TextToGraphics(G, getLongestEnemyPlayerName(a_Player), "x0" "y"(DestY+(Height//4))  " Bold c00FFFFFF r4 s" 17*UserScale	, Font) ; text is invisible ;get string size	
					StringSplit, LongestNameSize, LongestNameData, | ;retrieve the length of the string
					LongestNameSize := LongestNameSize3
				}
				DestX := LongestNameSize+10*UserScale

			;	DestX := TextSize3+10*UserScale
			}
			Else If (PlayerIdentifier = 3) && (A_Index = 1)
			{	pBitmap := a_pBitmap[a_Player[slot_number, "Race"],"RaceFlat"]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, 12*UserScale, DestY + Height/5, Width, Height, 0, 0, SourceWidth, SourceHeight, MatrixColour[a_Player[slot_number, "Colour"]])
				;Gdip_DisposeImage(pBitmap)
				pBitmap := a_pBitmap[unit]
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5		
				DestX := Width+10*UserScale
			}

			if !(pBitmap := a_pBitmap[unit])
				continue ; as i dont have a picture for that unit - not a real unit?
			SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
			Width *= UserScale *.5, Height *= UserScale *.5	

			Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
			Gdip_FillRoundedRectangle(G, a_pBrush[TransparentBlack], DestX + .6*Width, DestY + .6*Height, Width/2.5, Height/2.5, 5)
			if (unitCount >= 10)
				gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .3*Width/2) "y"(DestY + .5*Height + .35*Height/2)  " Bold cFFFFFFFF r4 s" 9*UserScale, Font)
			Else
					gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .4*Width/2) "y"(DestY + .5*Height + .35*Height/2)  " Bold cFFFFFFFF r4 s" 9*UserScale, Font)

			if (unitCount := aEnemyBuildingConstruction[slot_number, unit])	; so there are some of this unit being built lets draw the count on top of the completed units
			{
				;	Gdip_FillRoundedRectangle(G, a_pBrush[TransparentBlack], DestX, DestY + .6*Height, Width/2.5, Height/2.5, 5)
					Gdip_FillRoundedRectangle(G, a_pBrush[TransparentBlack], DestX + .6*Width, DestY, Width/2.5, Height/2.5, 5)
					if (unitCount >= 10)
						gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .3*Width/2) "y"(DestY + .15*Height/2)  " Bold Italic cFFFFFFFF r4 s" 9*UserScale, Font)
					Else
						gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .4*Width/2) "y"(DestY + .15*Height/2)  " Bold Italic cFFFFFFFF r4 s" 9*UserScale, Font)
					aEnemyBuildingConstruction[slot_number].remove(unit, "")
			}

			DestX += (Width+5*UserScale)
			if (DestX + Width > WindowWidth)
				WindowWidth := DestX
		}
		for unit, unitCount in aEnemyBuildingConstruction[slot_number]		;	lets draw the buildings under construction (these are ones which werent already drawn above)
			if (unit <> "TotalCount" && pBitmap := a_pBitmap[unit])				;	i.e. there are no already completed buildings of same type
			{
				SourceWidth := Width := Gdip_GetImageWidth(pBitmap), SourceHeight := Height := Gdip_GetImageHeight(pBitmap)
				Width *= UserScale *.5, Height *= UserScale *.5	
				Gdip_DrawImage(G, pBitmap, DestX, DestY, Width, Height, 0, 0, SourceWidth, SourceHeight)
				Gdip_FillRoundedRectangle(G, a_pBrush[TransparentBlack], DestX + .6*Width, DestY, Width/2.5, Height/2.5, 5)
				if (unitCount >= 10)
					gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .3*Width/2) "y"(DestY + .15*Height/2)  " Bold Italic cFFFFFFFF r4 s" 9*UserScale, Font)
				Else
					gdip_TextToGraphics(G, unitCount, "x"(DestX + .5*Width + .4*Width/2) " y"(DestY + .15*Height/2)  " Bold Italic cFFFFFFFF r4 s" 9*UserScale, Font)
				DestX += (Width+5*UserScale)
				if (DestX + Width > WindowWidth)
					WindowWidth := DestX
			}

			Height += 5*userscale	;needed to stop the edge of race pic overlap'n due to Supply pic -prot then zerg
			i++ 
	}
	WindowHeight := DestY+Height
	Gdip_DeleteGraphics(G)
	UpdateLayeredWindow(hwnd1, hdc,,,WindowWidth,WindowHeight)
	SelectObject(hdc, obm)
	DeleteObject(hbm)
	DeleteDC(hdc)
	Return
}






; //fold
; unit + 0xE2 ; 1 byte = 18h chrono for protoss structures 10h normal
/*
Orbital - Unit Abilities + 9 = 24h while idle 04h when SCV in prod - 40h while flying - 1byte
CC +9h = 76h idle / 12h scv in prod and 0A when flying - 20h when making PF - 40h  making orbital
pf  - (Unit Abilities + 34) -> pointer  + 180 = 1byte 43 scv in production. 3 idle - there is a queue length nearby 2
Toss - (Unit Abilities + 24!) --> pointer  + 88 = 1byte   43 proble in production. 3 idle queue length nearby
For the nexus there is also a chrono state nearby



address1 :=	(abilities pointer + 28)
Adress 2 := (address1 + 1C) 
Adress 3 :=  (Adress 2  + C)
Adress 3 + 6 = warpgate timer 2 byte

Note: Will give a fail if a the warpgate is virgin i.e. not warpged in a unit
/*
;creep tumours hatches larva broodlings

f2::

clipboard := dectohex((getSelectedUnitIndex()*S_uStructure) + B_uStructure)
		
	

return
f3::
	SC2exe := getProcessBaseAddress(GameIdentifier)
B_hStructure := SC2exe + 0x328C764
	O_hHatchPointer := 0xC
	O_hLarvaCount := 0x5C
	O_hUnitIndexPointer := 0x1C8
	S_hLarva := 0x94	;distance between each larva in 1 hatch
S_hStructure := 0x6F0 




clipboard := dectohex(B_hStructure)
msgbox % getLarvaCount()
;clipboard := dectohex(B_hStructure + O_hLarvaCount)

return

getLarvaCount(player="")
{ 	global A_unitID
	count := 0
	while (Address := HatchIndexUnitPointer(Hatch:=A_index-1)) ; checks there is a hatch or other unit
	while (Hatch < 50), (Address := HatchIndexUnitPointer(Hatch:=A_index-1)) ; checks there is a hatch or other unit
	{
		clipboard := dectohex(Address)
		Unit := getUnitIndexFromAddress(Address) ; First hatch, first larva - if there is just 1 larva it will be in this spot
		type := getUnitType(Unit)
		if isUnitLocallyOwned(Unit) && (type = A_unitID["Hatchery"] ||type = A_unitID["Lair"] || type = A_unitID["Hive"])
		{
			count += getHatchLarvaCount(Hatch)
			msgbox % dectohex(Address) "`n" count "`n" getHatchLarvaCount(Hatch)
		}
	}
		return count
}
getHatchBase(Hatch) ; beings @ 0 - this refers to the hatch index
{	global	; a Positive number indicates a hatch exists - 0 nothing
	return ReadMemory(B_hStructure + Hatch*S_hStructure, GameIdentifier)
}
HatchIndexUnitPointer(Hatch) ; beings @ 0 - this refers to the hatch index
{	global	; a Positive number indicates a hatch exists - 0 nothing
	return ReadMemory(B_hStructure + O_hHatchPointer + Hatch*S_hStructure, GameIdentifier)
}

getUnitIndexFromAddress(Address)
{	global
	return (Address - B_uStructure) / S_uStructure
}

getLarvaUnitIndex(Hatch=0, Larva=0) ; Refers to the hatch index and within that - so begins at 0
{	local LarvaAddress, UnitIndex

	LarvaAddress := ReadMemory(B_hStructure + (Hatch-1)*S_hStructure 
		+ (O_hUnitIndexPointer + (Larva * S_hLarva)) , GameIdentifier) ; address is actually the mem/hex address
	Return  (LarvaAddress - B_uStructure )/ S_uStructure	
}
getHatchLarvaCount(Hatch)
{	global 
	return ReadMemory(B_hStructure + Hatch*S_hStructure + O_hLarvaCount, GameIdentifier)
}


getLarvaPointer(Hatch, Larva)
{	global
	return ReadMemory((B_hStructure + S_hStructure * Hatch) + (O_hUnitIndexPointer + S_hLarva * Larva), GameIdentifier)
}


/*

f3::
dspeak(clipboard := isUnitPatrolling(getSelectedUnitIndex()))

	a_RemoveUnits := []
	findUnitsToRemoveFromArmy(a_RemoveUnits, SelectArmyDeselectXelnaga, SelectArmyDeselectPatrolling, l_ActiveDeselectArmy)
		Sort2DArray(a_RemoveUnits, "Unit", 0) ;clicks highest units first, so dont have to calculate new click positions due to the units moving down one spot in the panel grid	
		Sort2DArray(a_RemoveUnits, "Priority", 1)	; sort in ascending order so select units lower down 1st		
	ObjTree(a_RemoveUnits,"a_selectedunits")
return


	state := getUnitMoveState(getSelectedUnitIndex())
	if (state = uMovementFlags.Amove)
		dspeak("A move")
	else if (state = uMovementFlags.Patrol)
		dspeak("Patrol")
	else if (state = uMovementFlags.HoldPosition)
		dspeak("Hold")
	else if (state = uMovementFlags.Move)
		dspeak("move")
	else if (state = uMovementFlags.Follow)
		dspeak("Follow")
		
; fold//