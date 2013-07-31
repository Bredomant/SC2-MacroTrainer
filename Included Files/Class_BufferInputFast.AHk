Class BufferInputFast
{	static BufferedState := 0, BlockedState := 0, aBuffer := [], aBlockedKeys := []
	
	; EmergencyRestartKey: Allows a specified key to
	; launch a label even while input is blocked e.g. to reload the script
	; As Ctrl, Shift, Alt are remapped to 'return' during blocking, the emergency
	; key must not contain these modifiers. (wont work) 
	; **Valid keys are any Win-key combination or any single button 
	; 
	; As the EmergencyRestart has no #if i.e. it is global, it will take precedence 
	; over any of the keys listed in the blocking routine.

	setEmergencyRestartKey(Key, Label, Options := "")
	{	static EmergencyRestartKey
		Hotkey, If 	;	just in case there is an active Hotkey, if somewhere above
		#If
		if (Key != EmergencyRestartKey)
		{
			Try Hotkey, %EmergencyRestartKey%, Off 	; disable the previous key if it exists
													; note, this may disable some other function hotkey
													; if the user has changed both keys 
													; due to the where I actually call this function
													; to ensure the emergency restart hotkey is never
													; overwritten by another function hotkey
			Try Hotkey, %Key%, %Label%, On, %Options%
		}
		EmergencyRestartKey := Key
		return
	}
	createHotkeys(aKeys)
	{	GLOBAL GameIdentifier
		this.aBlockedKeys := aKeys
		
		#If, BufferInputFast.isInputBuffered() && WinActive(GameIdentifier)
		Hotkey, If, BufferInputFast.isInputBuffered() && WinActive(GameIdentifier)
		for index, Button in aKeys
			Try Hotkey, %Button%, g_BufferInputFastLabel, On

		#If, BufferInputFast.isInputBlocked() && WinActive(GameIdentifier)
		Hotkey, If, BufferInputFast.isInputBlocked() && WinActive(GameIdentifier)
		for index, Button in aKeys
			Try Hotkey, %Button%, g_ReturnFastLabel, On
		#If
		return			
	}
	disableHotkeys()
	{ 	GLOBAL GameIdentifier
		if this.aBlockedKeys.MaxIndex()
		{
			Hotkey, If, BufferInputFast.isInputBuffered() && WinActive(GameIdentifier)
			for index, Button in this.aBlockedKeys
				Try Hotkey, %Button%, Off

			Hotkey, If, BufferInputFast.isInputBlocked() && WinActive(GameIdentifier)
			for index, Button in this.aBlockedKeys
				Try Hotkey, %Button%, Off
			Hotkey, If
			this.aBlockedKeys := []
		}
		return			
	}
	releaseModifiers()
	{
		if GetKeyState("Shift", "P")
			sendInput {Blind}{Shift up}
		if GetKeyState("Ctrl", "P")
			sendInput {Blind}{ctrl up}	
		if GetKeyState("Alt", "P")
			sendInput {Blind}{alt up}
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
		this.releaseModifiers() ;lets release the modifiers (the hard rebinds will prevent it getting pushed down)
		return
	}	
	BlockInput()
	{
		this.BufferedState := 0
		this.BlockedState := 1
		this.releaseModifiers() ;lets release the modifiers (the hard rebinds will prevent it getting pushed down)
		return
	}
	disableBufferingAndBlocking()
	{
	;	shift = 1, ctrl = 2, alt = 4 (and add them together)

		ModifierState := readModifierState() ; read from sc2 memory

		, Shift := (1 & ModifierState)
		, Ctrl := (2 & ModifierState)
		, Alt := (4 & ModifierState)

;	{Blind} Has to be used when sending modifier ups.	
;

;	Obviously sendInput {Blind}{Shift Up} must be used to restore the logical state of the key
;	before restoring user input,
;	but sendInput {Blind}{Shift Down} also needs to be used when the other scenario occurs
;	This does present a super slim timing window if the user releases the shift key the instant the 
;	command runs, but the chance of this happening is very low and considerably less likely
;	than a user intended shift action not being shift-modified.
; 	If this slim timming Shift Down window ends up being a problem, can just launch a settimer 
;	in say 50ms which does another check and corrects the keystate. But I will test for a while and 
;	see how well it works in its current implementation.

;	If this Down event isn't sent, and the user is holding down the shift button
;	all of the user input within the first ~50ms of blocking being turned off will NOT
;	be shift modified (when it should be!) 

;	This was tested by removing the below SendInputs which restore the keystate
;	and and putting a unit on a patrol move and moving the mouse to a spot
;	so that it will be Blind Right clicked at that location
; 	If the game realised shift was down the unit was shift Right clicked
;	if it didn't it was simply Right clicked

;	BufferInputFast.BufferInput()
;	soundplay *-1 
	; Shift Key is physically pressed and held down 
;	sleep 5000
;	BufferInputFast.Send()
;	sleep(50)
;	send {BLIND}{click Right} 

; 	Further Notes: Technically I should use Send {Blind} For all send commands after blocking enabled
;	This is because even though the shift key is remapped to nothing, AHK will still see it as 
; 	physically AND logically down when pressed, even though the game window will not know it is down,
;	hence when using plain send AHK will send extra shift UP/down modifiers to the send command
;	but this shouldn't cause any major issues.

; 	Also Note: Don't trust cheat engine to read the modifier value correctly during some blocking events.
;	I can't explain this, but sometimes it simply doesn't read or update properly (even using 
;	increased timer resolutions). I Don't know if this is the same for some other values.
;	Hence it is better to have a tool tip on a loop which reads and displays the value
;	When doing this, the value always corresponds to what you would expect it to be

		if (GetKeyState("Shift", "P") != Shift)
		{
			if GetKeyState("Shift", "P")
				sendInput {Blind}{Shift Down}
			else 
				sendInput {Blind}{Shift Up}
		}

		if (GetKeyState("Ctrl", "P") != Ctrl)
		{
			if GetKeyState("Ctrl", "P")
				sendInput {Blind}{Ctrl Down}
			else 
				sendInput {Blind}{Ctrl Up}
		}

		if (GetKeyState("Alt", "P") != Alt)
		{
			if GetKeyState("Alt", "P")
				sendInput {Blind}{Alt Down}
			else 
				sendInput {Blind}{Alt Up}
		}
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
		StringReplace, pressedKey, pressedKey, ~
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
