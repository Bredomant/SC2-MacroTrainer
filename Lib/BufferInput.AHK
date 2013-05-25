        ; Note: **** it seems when using *~LButton to monitor user mouse/drag position
        ; it stuffs up using *lbutton as a modifier for blocking the button press is still passed to the active window
        ; hence have to manually enter all the +^! combinations
        ; this does not work when placing the *modifier in front of the modifier+Lbutton Combos in bufferinput command
        ; hence why every key in the keylist file (except LbuttonMods) has the * modifier (saves having an If button contains Lbutton
        ; in the blocking section)
        ; Also need the plain " LButton " here


BufferInput(byref aKeys, Mode="Off", MouseBlocking=1, IgnoreHotkey="")
{ 	STATIC aBuffer
	If (Mode = "Buffer")
		label := "g_bufferInput", aBuffer := []
	Else if (Mode = "RetrieveKeys")
		return aBuffer
	Else if (Mode = "Block")
		label := "g_Return", aBuffer := []
	Else if (Mode = "Send" || Mode = "Off")
	{
		if (Mode = "Send")
			for index, Button in aBuffer
    			send % Button
		for index, Button in aKeys
			Try Hotkey, %Button%, Off
		BlockInput, MouseMoveOff
		CreateHotkeys()		;function which remakes the previously destroyed hotkeys
		return
    }
    else msgbox Error in BufferInput function mode	
	if MouseBlocking
		BlockInput, MouseMove
	for index, Button in aKeys
		Try Hotkey, %Button%, %label%, On
	if IgnoreHotkey	;this hotkey will not be buffered - generally put the function hotkey here so it doesnt get spammed if the user holds it down for ages
	{				; Actually after, testing this probably isnt required as with 1 maxthread hotkey, that hotkey cant fire (and probably wont be reassigned above)
		StringReplace, IgnoreHotkey, IgnoreHotkey, ^
		StringReplace, IgnoreHotkey, IgnoreHotkey, +
		StringReplace, IgnoreHotkey, IgnoreHotkey, !
		Try Hotkey, *%IgnoreHotkey%, g_Return, On
	}
	return

	g_BufferInput:
	    pressedKey := Trim(A_ThisHotkey, " `t*") ; trim the  *
	    If (GetKeyState("CapsLock", "T") && GetKeyState("Shift", "P")) 
	    || !GetKeyState("CapsLock", "T")
	        pressedKey := setCase(0, pressedKey) ; doesnt really work for actual typing eg Shift + capslock = A instead of a cos not sending shift down a shift up
	    if StrLen(pressedKey) > 1
	    {
	      ;  If InStr(pressedKey, "Button")  || InStr(pressedKey, "Wheel")
	        pressedKey := "{" pressedKey "}"
	    }
	    aBuffer.insert(getModifierState() pressedKey)
	return
	g_Return:
	return
}
