DwmEnableComposition(Enable)
{
	if A_OSVersion in WIN_7,WIN_VISTA 
		return DllCall("dwmapi\DwmEnableComposition", "uint", Enable)
}
;	returns S_OK (i.e. 0) when works else, returns the error code
/*
	In Windows 8, Desktop Window Manager (DWM) is always ON and cannot be disabled by end users and apps.
	Note  This function is deprecated as of Windows 8. DWM can no longer be programmatically disabled.
	Remarks:
	Disabling DWM composition disables it for the entire desktop. DWM composition will be automatically 
	enabled	when all processes that have disabled composition have called DwmEnableComposition to 
	enable it or have been terminated. The WM_DWMCOMPOSITIONCHANGED notification is sent whenever DWM 
	composition is enabled or disabled.
*/