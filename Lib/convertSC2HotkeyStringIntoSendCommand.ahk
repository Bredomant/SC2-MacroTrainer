; takes a hotkey stored in SC2s syntax and the corresponding AHK Send command

convertSC2HotkeyStringIntoSendCommand(String)
{
						;	"SC2Key": "AhkKey"
	static aTranslate := {	"PageUp": "PgUp"
						,	"PageDown": "PgDn"
						,	"NumPadMultiply": "NumpadMult"
						,  	"NumPadDivide": "NumpadDiv"
						,	"NumPadPlus": "NumpadAdd"				
						,	"NumPadMinus": "NumpadSub"

						, 	"Grave": "``" ;note needs escape character!
						, 	"Minus": "-"
						, 	"Equals": "="
						, 	"BracketOpen": "["
						, 	"BracketClose": "]"
						,	"BackSlash": "\"						
						, 	"SemiColon": ";"
						, 	"Apostrophe": "'"
						, 	"Comma": ","
						, 	"Period": "."
						,	"Slash": "/"

						, 	"LeftMouseButton": "LButton"
						, 	"RightMouseButton": "RButton"
						,	"MiddleMouseButton": "MButton"
						, 	"ForwardMouseButton": "XButton1"
						, 	"BackMouseButton": "XButton2" }
						; apparently nothing can be bound to the wheel (i thought you COULD do that in sc2....)

	; NumpadDel maps to real delete key, same for NumpadIns, Home, End and num-UP,Down,Left,Right, and Num-PageUp/Down and enter
	; {NumpadClear} (num5 with numlock off) doesnt map to anything
	; nothing can be mapped to windows keys or app keys

; Easier to use string replace here and have the modifiers separate and outside of the
; aTranslate associative array. As AHK Associative arrays are indexed alphabetically (not in order in which keys were added)
; so this would result in modifier strings being incorrectly converted
; SC2 Hotkeys are done in this Order Control+Alt+Shift+Keyname
StringReplace, String, String, Control+, ^, All ;use modifier+ so if user actually has something bound to it wont cause issue
StringReplace, String, String, Alt+, !, All 
StringReplace, String, String, Shift+, +, All 	;this will also act to remove SC2's joining '+'


	; string replace accounts for differences between AHK send Syntax and SC2 hotkey storage

	for SC2Key, AhkKey in aTranslate
		StringReplace, String, String, %SC2Key%, %AhkKey%, All 

	if String in !,#,+,^,{,} ; string must be 1 character length to match
		return "{" String "}"

	static aModifiers := ["+", "^", "!"]
	;lets remove the modifiers so can see command length
	for index, modifier in 	aModifiers
		if inStr(string, modifier)
		{
			StringReplace, String, String, %modifier%,, All
			StringModifiers .= modifier
		}

	; lets correct for any difference in the command names
	; CapsLock ScrollLock NumLock
	; cant bind anything to windows key or appskey in game



	if (StrLen(string) > 1)
		string := StringModifiers "{" string "}" ; as AHK commands > 1 are enclosed in brackets
	else string := StringModifiers string

	if (string = "+=") 		; AHK cant send this correctly != and +- work fine
		string := "+{=}" 	; +!= works fine too as does !+= and ^+=

		return string
}