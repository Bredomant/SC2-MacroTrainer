; http://msdn.microsoft.com/en-us/library/windows/desktop/ms686298%28v=vs.85%29.aspx
; Works best with HPET enabled
; call sleep("Off") before exiting the script

Sleep(ms=1)
{	STATIC timeBeginPeriodSet, MinSetResolution

	if !timeBeginPeriodSet
	{
		if !MinSetResolution
			getSystemTimerResolutions(MinSetResolution)
		DllCall("Winmm.dll\timeBeginPeriod", UInt, MinSetResolution)
		timeBeginPeriodSet := 1
	}
	else if (ms = "Off" && timeBeginPeriodSet)
	{
		DllCall("Winmm.dll\timeEndPeriod", UInt, MinSetResolution)
		timeBeginPeriodSet := 0
		return
	}
	DllCall("Sleep", UInt, ms)
}


/*
Use caution when calling timeBeginPeriod, as frequent calls can significantly affect the system clock, 
system power usage, and the scheduler. If you call timeBeginPeriod, call it one time early in the application 
and be sure to call the timeEndPeriod function at the very end of the application.


*/