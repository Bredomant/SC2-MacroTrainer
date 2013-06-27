#include Class_CStruct.ahk
getSystemTimerResolutions(ByRef MinResolution = "", ByRef MaxResolution = "")
{
	LPTIMECAPS := new Ctimecaps  ; included in Class_CStruct.ahk
	DllCall("Winmm.dll\timeGetDevCaps", Ptr, LPTIMECAPS.ptr, UInt, LPTIMECAPS.size)	
	MinResolution := LPTIMECAPS.wPeriodMin
	MaxResolution := LPTIMECAPS.wPeriodMax
	return
}

/*
MMRESULT timeGetDevCaps(
  LPTIMECAPS ptc,
  UINT cbtc
);

ptc
A pointer to a TIMECAPS structure. This structure is filled with information about the resolution of the timer device.
cbtc
The size, in bytes, of the TIMECAPS structure.


class Ctimecaps extends CStruct_Base
{
	__New()
	{
		this.AddStructVar("wPeriodMin", "UINT")
		this.AddStructVar("wPeriodMax", "UINT")
		this.SetStructCapacity()
	}
}
*/