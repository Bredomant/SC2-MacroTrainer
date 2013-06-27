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
		}
		if !GetKeyState("Lbutton", "P") && GetKeyState("Lbutton") 	; so if the button is up, but the game thinks it down
			send {click Up}  										; send and up command to unstick it - but doesnt seem to work here
	;	else if GetKeyState("Lbutton", "P") && !GetKeyState("Lbutton") 
	;		send {click Down}  		

		if !GetKeyState("Rbutton", "P") && GetKeyState("Rbutton")
			send {click Up Right} 	
	;	else if GetKeyState("Rbutton", "P") && !GetKeyState("Rbutton") 
	;		send {click Down Right}  			


		if MouseHasMoved
			send {click  %Xstart%, %Ystart%, 0} 
		if DisableBuffering
			BufferInputFast.disableBufferingAndBlocking()
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
g_BufferInputFastLabel:
	BufferInputFast.RecordInput()
return
g_ReturnFastLabel:
return
#If, !BufferInputFast.isInputBlockedOrBuffered() 
~Lbutton Up::
sleep(1)
if !GetKeyState("Lbutton", "P") && GetKeyState("Lbutton") 
	send {click left up}
return
#If
g_class_BufferInputFastLabelSkip>: