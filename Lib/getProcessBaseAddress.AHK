getProcessBaseAddress(WindowTitle, Hex=1, MatchMode=3)
{
	SetTitleMatchMode, %MatchMode%	;mode 3 is an exact match
	WinGetClass, classname, %WindowTitle%
	h := DllCall("FindWindow", "str", classname, "UInt", 0) ;the second param is an optional win title
	if Hex
		return dectohex(DllCall("GetWindowLong", "Uint", h, "Uint", -6))
	else return DllCall("GetWindowLong", "Uint", h, "Uint", -6)
}