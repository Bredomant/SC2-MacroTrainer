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
		sendInput {Blind}{Shift up}{ctrl up}{alt up} ;lets release the modifiers (the hard rebinds will prevent it getting pushed down)
		return
	}	
	BlockInput()
	{
		this.BufferedState := 0
		this.BlockedState := 1
		sendInput {Blind}{Shift up}{ctrl up}{alt up} ;lets release the modifiers (the hard rebinds will prevent it getting pushed down)
		return
	}
	disableBufferingAndBlocking()
	{
	;	shift = 1, ctrl = 2, alt = 4 (and add them together)
		; This is to restore propper shift modifier state
		; MOdifiers can be seen as up when they are down
		; if modifier combox eg shit + ctrl are
		; pressed and released a few times during blocking 
/*
		ModifierState := readModifierState() ; read from sc2 memory
		, Shift := (1 & ModifierState)
		, Ctrl := (2 & ModifierState)
		, Alt := (4 & ModifierState)

		if GetKeyState("Shift", "P") && !Shift
			sendInput {Blind}{Shift Down}
		if GetKeyState("Ctrl", "P") && !Ctrl
			sendInput {Blind}{ctrl Down}	
		if GetKeyState("alt", "P") && !alt
			sendInput {Blind}{alt Down}		
*/
		ModifierState := readModifierState() ; read from sc2 memory
		, Shift := (1 & ModifierState)
		, Ctrl := (2 & ModifierState)
		, Alt := (4 & ModifierState)

		; so this checks if the key is physically UP, but SC2 Window thinks its Down
		; due to it being released while blocking was enabled
		if !GetKeyState("Shift", "P") && Shift
			sendInput {Blind}{Shift up}
		if !GetKeyState("Ctrl", "P") && Ctrl
			sendInput {Blind}{ctrl up}	
		if !GetKeyState("alt", "P") && alt
			sendInput {Blind}{alt up}


		if (GetKeyState("Shift", "P") != GetKeyState("Shift"))
		{
			if GetKeyState("Shift", "P")
				sendInput {Blind}{Shift Down}
			else 
				sendInput {Blind}{Shift Up}
		}

		if (GetKeyState("Ctrl", "P") != GetKeyState("Ctrl"))
		{
			if GetKeyState("Ctrl", "P")
				sendInput {Blind}{Ctrl Down}
			else 
				sendInput {Blind}{Ctrl Up}
		}

		if (GetKeyState("alt", "P") != GetKeyState("alt"))
		{
			if GetKeyState("alt", "P")
				sendInput {Blind}{alt Down}
			else 
				sendInput {Blind}{alt Up}
		}
		this.BufferedState := 0
		this.BlockedState := 0

	;  using write modifiers still possible for modifiers to be temp stuck down outside game
  	; but a send should fix that  	
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

	;	for index, button in aModifierKeys 							;	seeing if this helps the stick modifer problem
	;		if !GetKeyState(button, "P") && GetKeyState(button)		; could add a modiferUp ~ hotkey to check
	;			Send % "{" button " Up}"
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
	stripModifiers(pressedKey)
	{
	    StringReplace, pressedKey, pressedKey, ^ 
		StringReplace, pressedKey, pressedKey, + ;	these are needed in case the hotkey/keyname in key list contains these modifiers
		StringReplace, pressedKey, pressedKey, ! 
		StringReplace, pressedKey, pressedKey, *
		return pressedKey
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
	  	pressedKey := BufferInputFast.stripModifiers(pressedKey)


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


g_ModifierInputFastLabel:
return 
		ModifierState := readModifierState() ; read from sc2 memory
		; so this checks if the key is physically down, but SC2 Window thinks its up
		if GetKeyState("Shift", "P") || (1 & ModifierState)
			sendInput {Blind}{Shift up}
		if GetKeyState("Ctrl", "P") || (2 & ModifierState)
			sendInput {Blind}{ctrl up}
		if GetKeyState("alt", "P") || (4 & ModifierState)
			sendInput {Blind}{alt up}
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
; Note: have another hotkey, *~LButton, g_LbuttonDown, on active in createhotkeys()
; *Perhaps I should try making this Lbutton a *Lbutton (but seems to work ok as is)
; as this hotkey will only fire when no modifers are used
; the other one will only fire WHEN modifiers are present due to this hotkey
~Lbutton Up::
sleep(2)
if !GetKeyState("Lbutton", "P") && GetKeyState("Lbutton") 
	send {click left up}	
return

#If, (BufferInputFast.isInputBlockedOrBuffered() && WinActive(GameIdentifier))
*Shift::return 
*shift up::return

*Ctrl::return 
*Ctrl up::return

*Alt::return 
*Alt up::return
#If


/*
Test: Current re-assign hotkey block/buffer method
      press shift key down
      enable buffering
      physically release the shift
      disable (not send) buffering
When the below part is incorprated into the script
    #If, (WinActive(GameIdentifier)) 
    ~Shift Up::
    sleep(2)
    if !GetKeyState("Shift", "P") && GetKeyState("Shift") 
      send {Shift up}

Result:
  Shift key is stuck down until it gets pressed (every action will be shift modified)
  BUT  AHK sees the shift key as both physically and LOGICALLY up

	Therefore any comparison of the two will not work
	Having a sendInput {Shift up} somewhere afterwards fixes key state
*/
/*
#If, (WinActive(GameIdentifier)) 
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

*/
g_class_BufferInputFastLabelSkip>:


/*

  If BlockInput Is turned on while a key is pressed, and the user then released it while input is blocked
  that key will still be seen as logically down

  Any send command made after input is retored will restore the logical state of MODIFIERS (not other keys) even send {click, 500, 500, 0}

  Within SC2 physically holding 'S' and then pressing Ctrl does not alter the sound state
  But, if 'Ctrl' is logically down then pressing S will change the sound state

  
  When the keyboardhook is installed AHK wont trigger it sown hotkeys if a modifer is logically down and
  other part of the key is then physically pressed e.g. ^s ctrl is logically down 
  When the keyboardhook is NOT installed this will actually trigger the hotkey


  Test: Loop sendInput {Shift Up} with 10ms sleep while holding down shift in game and right clicking a unit in circle
  Result: 95% of the clicks were Shift-Clicks but a few were not i.e. just right clicks

  Test2: Loop sendInput {Blind}{Shift Up} (same as above)
  Result: The vast majority of clicks were NOT Shift-Clicks i.e. just right clicks

  Test2: Loop sendInput {Blind}{Shift Up} (same as above)
  Result: The vast majority of clicks were NOT Shift-Clicks i.e. just right clicks

  Test: With my current blocking/hotkey method
        enable blocking/buffering
        Press and hold a key
        disable buffering
        release key physically


  Result:
          Withing the first 10ms (or less) the key is seen as logically UP and physically down, but then i assume the 
          autorepeat feature kicks in and the key registers as both physically and logically down

  Recommendation: Perhaps try restoring the keystate (at least for modifiers)
  	but as it is it should work fine, its only a few ms when the key isnt registering     

*/
