;This is required for the reading of the 8 bit target filter - cant work out how to do this properly with numget

ReadMemoryOld(MADDRESS=0,PROGRAM="",BYTES=4)
{
   Static OLDPROC, ProcessHandle
   VarSetCapacity(MVALUE, BYTES,0)
   If PROGRAM != %OLDPROC%
   {
      WinGet, pid, pid, % OLDPROC := PROGRAM
      ProcessHandle := ( ProcessHandle ? 0*(closed:=DllCall("CloseHandle"
      ,"UInt",ProcessHandle)) : 0 )+(pid ? DllCall("OpenProcess"
      ,"Int",16,"Int",0,"UInt",pid) : 0)
   }
   If (ProcessHandle) && DllCall("ReadProcessMemory","UInt",ProcessHandle,"UInt",MADDRESS,"Str",MVALUE,"UInt",BYTES,"UInt *",0)
   {	Loop % BYTES
			Result += *(&MVALUE + A_Index-1) << 8*(A_Index-1)
		Return Result
	}
   return !ProcessHandle ? "Handle Closed:" closed : "Fail"
}