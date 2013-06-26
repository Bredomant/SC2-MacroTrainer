; http://msdn.microsoft.com/en-us/library/windows/desktop/ms686298%28v=vs.85%29.aspx
; Works best with HPET enabled

Sleep(ms=1)
{
		STATIC timeBeginPeriodHasAlreadyBeenCalled
		if (timeBeginPeriodHasAlreadyBeenCalled != 1)
		{
			DllCall("Winmm.dll\timeBeginPeriod", UInt, 1)
			timeBeginPeriodHasAlreadyBeenCalled := 1
		}
		
	DllCall("Sleep", UInt, ms)
}