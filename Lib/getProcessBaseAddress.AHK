getProcessBaseAddress(WindowTitle, Hex=1, MatchMode=3)	;WindowTitle can be anything ahk_exe ahk_class etc
{
	SetTitleMatchMode, %MatchMode%	;mode 3 is an exact match
	WinGetClass, classname, %WindowTitle%
	h := DllCall("FindWindow", "str", classname, "UInt", 0) ;the second param is an optional win title

	; im not exactly sure when it is required to call GetWindowLongPtr instead of GetWindowLong
	; as  GetWindowLong works on my win 7 64 bit system, but GetWindowLongPtr doesnt!
	; hence why im using errorlevel, and not simiply calling one by the OS/bit-type

	BaseAddress := DllCall("GetWindowLong", "Uint", h, "Uint", -6) ; this strangely works in win7-64bit
	if ErrorLevel ; should be -4 if function not found inside dll (eg win8)
		BaseAddress := DllCall("GetWindowLongPtr", "Uint", h, "Uint", -6)	; this is needed for win8
	if Hex
		return dectohex(BaseAddress)
	else return BaseAddress
}