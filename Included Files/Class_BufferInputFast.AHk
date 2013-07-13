Class BufferInputFast
{	static BufferedState := 0, BlockedState := 0, aBuffer := [], aBlockedKeys := []

	createHotkeys(aKeys)
	{
		this.aBlockedKeys := aKeys
		#If, BufferInputFast.isInputBuffered() 
		Hotkey, If, BufferInputFast.isInputBuffered() 
		for index, Button in aKeys
			Try Hotkey, %Button%, g_BufferInputFastLabel, On
		
		#If, BufferInputFast.isInputBlocked() 
		Hotkey, If, BufferInputFast.isInputBlocked()
		for index, Button in aKeys
			Try Hotkey, %Button%, g_ReturnFastLabel, On
		#If
		Hotkey, If
		return			
	}
	disableHotkeys()
	{
		if this.aBlockedKeys.MaxIndex()
		{
			Hotkey, If, BufferInputFast.isInputBuffered()
			for index, Button in this.aBlockedKeys
				Try Hotkey, %Button%, Off
			
			Hotkey, If, BufferInputFast.isInputBlocked() 
			for index, Button in this.aBlockedKeys
				Try Hotkey, %Button%, Off
			Hotkey, If
			this.aBlockedKeys := []
		}
		return			
	}	

	isInputBuffered()
	{
		return this.BufferedState
	}
	isInputBlocked()
	{
		return this.BlockedState
	}
	isInputBlockedOrBuffered()
	{
		if (this.BufferedState || this.BlockedState)
			return 1
		return 0
	}
	BufferInput()
	{
		this.aBuffer := []
		this.BufferedState := 1
		this.BlockedState := 0
		return
	}	
	BlockInput()
	{
		this.BufferedState := 0
		this.BlockedState := 1
		return
	}
	disableBufferingAndBlocking()
	{
		this.BufferedState := 0
		this.BlockedState := 0
		return
	}
	retrieveBuffer()
	{
		return this.aBuffer
	}
	send(MouseBlocking := 0, DisableBuffering := 1)
	{
		static aModifierKeys := ["Shift", "Ctrl", "Alt"]


		MouseGetPos, Xstart, Ystart
		for index, Button in this.aBuffer
		{
			if isObject(Button) ;so its a mouse button or at least has move co-ordinates
			{
				MouseHasMoved := !MouseBlocking
				x := Button.x, y := Button.y
				if InStr(Button.Button, "LButton") && !InStr(Button.Button, "UP") && !MouseBlocking ; so lbutton down (not up)
				{
					if modifiers := BufferInputFast.getModifiersFromString(Button.Button)
						send %modifiers%{click down %x%, %y%} 
					else send {click down %x%, %y%} 
				;	sleep, 5 ; some programs may require a sleep here - SC2 and many others don't.
					continue
				}
				else if InStr(Button.Button, "LButton Up") && MouseBlocking ;
					continue ; as don't need to send the lbutton up command as it was never held down
				else if !MouseBlocking
					send {click  %x%, %y%, 0} ;move the mouse
				Button := Button.Button 
			}
			send % Button
			; apparently sendevent should be able to trigger the scripts own hotkeys
			; but this didn't seem to be the case when testing
			; so not going to bother to do an if Sendevent check
			if Button contains Esc ; this is a local function which disables auto worker
				gosub g_temporarilyDisableAutoWorkerProductionOriginUserInputBufferSend
		}
		if MouseHasMoved
			send {click  %Xstart%, %Ystart%, 0} 
		if DisableBuffering
			BufferInputFast.disableBufferingAndBlocking()

		if !GetKeyState("Lbutton", "P") && GetKeyState("Lbutton") 	; so if the button is up, but the game thinks it down
			send {click Up}  										; send and up command to unstick it - but doesnt seem to work here
	;	else if GetKeyState("Lbutton", "P") && !GetKeyState("Lbutton") 
	;		send {click Down}  		

		if !GetKeyState("Rbutton", "P") && GetKeyState("Rbutton")
			send {click Up Right} 	
	;	else if GetKeyState("Rbutton", "P") && !GetKeyState("Rbutton") 
	;		send {click Down Right}  			

		for index, button in aModifierKeys 							;	seeing if this helps the stick modifer problem
			if !GetKeyState(button, "P") && GetKeyState(button)		; could add a modiferUp ~ hotkey to check
				send % "{" button " Up}"
		return
	}
	getModifiersFromString(string)
	{	static aModifiers := ["*", "+", "^", "!"]
		
		for index, modifier in 	aModifiers
			if inStr(string, modifier)
				result .= modifier
		return result
	}
	getModifierState()
	{
	    If GetKeyState("Shift", "P")
	        Modifiers .= "+"
	    If GetKeyState("Control", "P")
	        Modifiers .= "^"
	    If GetKeyState("Alt", "P")
	        Modifiers .= "!"
	    return Modifiers
	}
	setCase(Upper=0, string="", Title=0)
	{
	    if Upper
	    {
	        if title
	            StringUpper, result, string, T 
	        else StringUpper, result, string
	    }
	    Else
	    {
	        if title
	            StringLower, result, string, T 
	        else StringLower, result, string
	    }
	    return result
	}

	RecordInput()
	{	STATIC MouseButtons :=  "LButton,RButton,MButton,XButton1,XButton2"

	    pressedKey := Trim(A_ThisHotkey, " `t") ; trim spaces and tabs....probably not required
	    StringReplace, pressedKey, pressedKey, ^ 
		StringReplace, pressedKey, pressedKey, + ;	these are needed in case the hotkey/keyname in key list contains these modifiers
		StringReplace, pressedKey, pressedKey, ! 
		StringReplace, pressedKey, pressedKey, *

	    If (GetKeyState("CapsLock", "T") && !GetKeyState("Shift", "P")) 
	    || !GetKeyState("CapsLock", "T") && !GetKeyState("Shift", "P")
	        pressedKey := BufferInputFast.setCase(0, pressedKey) ; change to lower case as the keys in 'pressed keys' are always in upper case
	    if pressedKey contains %MouseButtons% 	;	need to use contain as check for 'lbutton up' modifier/key
	    { 										;	e.g. "+LButton Up"	will still return true (but the + modifier is stripped above anyway)
	    	MouseGetPos, X, Y
	    	pressedKey := BufferInputFast.getModifierState() "{" pressedKey "}"
	    	MouseObject := {Button: pressedKey, x: x, y: y}
	    	this.aBuffer.insert(MouseObject)
	    	return
	    }
		if StrLen(pressedKey) > 1
		    pressedKey := "{" pressedKey "}"
	    this.aBuffer.insert(BufferInputFast.getModifierState() pressedKey)
		return		
	}


}
Goto g_class_BufferInputFastLabelSkip> ;so can include anywhere even in autoexec section

; Thread, NoTimers, true is required as this will be in effect most times when these hotkeys are active
; and if this is not set, the hotkey will activate this hotkey thread, which IS interuptible could cause other timers to run
; and these other timers could have their own BufferInputFast.send() (eg auto worker) command which would A. Stuff up the sequence of keystrokes
; B. Prematurely disable key blocking/buffering

g_BufferInputFastLabel:
	Thread, NoTimers, true 
	BufferInputFast.RecordInput()
return
g_ReturnFastLabel:
	Thread, NoTimers, true  ; probably not required as default value makes threads un-interupterble for 15ms
return
#If, (!BufferInputFast.isInputBlockedOrBuffered() && WinActive(GameIdentifier))  ; need this here as AHK tree view goes crazy! it needs like 200 ms sleep or something
; this obviously wont account for if the user has swapped the left and right mouse buttons in windows

; the lbutton check is definitely needed to prevent the button getting stuck down if the user releases/presses it sometimes
; while it is being blocked
; the modifiers probably are not needed, but every now and then the ctrl key gets stuck down
; and needs a press, testing if this makes it more robust
; the mouse hook/system state seems slower to update and so needs a small sleep
; to allow the button to 'come up' i.e. register
; the keyboard buttons seem much faster, but added the delay anyway
~Lbutton Up::
sleep(2)
if !GetKeyState("Lbutton", "P") && GetKeyState("Lbutton") 
	send {click left up}	
return
~alt up::
sleep(2)
if !GetKeyState("alt", "P") && GetKeyState("alt") 
	send {alt up}
return
~ctrl up::
sleep(2)
if !GetKeyState("ctrl", "P") && GetKeyState("ctrl") 
	send {ctrl up}
return
~Shift Up::
sleep(2)
if !GetKeyState("Shift", "P") && GetKeyState("Shift") 
	send {Shift up}
return
#If
g_class_BufferInputFastLabelSkip>: