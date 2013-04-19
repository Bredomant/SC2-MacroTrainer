BufferInput(byref aKeys, Mode="Off", MouseBlocking=1)
{ 	STATIC aBuffer
	If (Mode = "Buffer")
		label := "g_bufferInput", aBuffer := []
	Else if (Mode = "Block")
		label := "g_Return", aBuffer := []
	Else if (Mode = "Send" || Mode = "Off")
	{
		if (Mode = "Send")
			for index, Button in aBuffer
    			send % Button
		for index, Button in aKeys
			Try Hotkey, *%Button%, Off
		BlockInput, MouseMoveOff
		CreateHotkeys()		;function which remakes the previously destroyed hotkeys
		return
    }
    else msgbox Error in BufferInput function mode	
	if MouseBlocking
		BlockInput, MouseMove
	for index, Button in aKeys
		Try Hotkey, *%Button%, %label%, On
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
