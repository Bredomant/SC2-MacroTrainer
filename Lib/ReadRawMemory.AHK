ReadRawMemory(MADDRESS=0,PROGRAM="", byref Buffer="", BYTES=4)
{
   Static OLDPROC, ProcessHandle

   VarSetCapacity(Buffer, BYTES)

   If PROGRAM != %OLDPROC%
   {
      WinGet, pid, pid, % OLDPROC := PROGRAM
      ProcessHandle := ( ProcessHandle ? 0*(closed:=DllCall("CloseHandle"
      ,"UInt",ProcessHandle)) : 0 )+(pid ? DllCall("OpenProcess"
      ,"Int",16,"Int",0,"UInt",pid) : 0)
   }
   If (ProcessHandle) && DllCall("ReadProcessMemory","UInt",ProcessHandle,"UInt",MADDRESS,"Str",Buffer,"UInt",BYTES,"UInt *",bytesread)
      return bytesread
   return !ProcessHandle ? "Handle Closed:" closed : "Fail"
}
