DwmIsCompositionEnabled()
{
	if A_OSVersion in WIN_8,WIN_7,WIN_VISTA  
	{
		DllCall("Dwmapi\DwmIsCompositionEnabled", "Int*", State) ; returns 0 if works, else error code
		return state 
	}
	return 0
}
/*
	In Windows 8, Desktop Window Manager (DWM) is always ON and cannot be disabled by end users and apps.
	But this function is still included and will return true
*/
