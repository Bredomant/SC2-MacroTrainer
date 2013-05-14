; Automatically closes handle when a new (or null) program is indicated
; Otherwise, keeps the process handle open between calls that specify the
; same program. When finished reading memory, call this function with no
; parameters to close the process handle i.e: "Closed := ReadMemory()"

;The new method using Numget is around 35% faster!!!

;Bytes can take 1,2,3,4 or 8 or can simply pass "Char", "float", "Double" etc as needed
ReadMemory(MADDRESS=0,PROGRAM="",BYTES=4)
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
   if (BYTES = 1)
         Tpye := "Char"
   else if (BYTES = 2)
      Type := "Short"
   else if (BYTES = 4)
      Type := "Int"
   else if (BYTES = 8)
      Type := "Int64"
   else Type := BYTES
   If (ProcessHandle) && DllCall("ReadProcessMemory","UInt",ProcessHandle,"UInt",MADDRESS,"Str",MVALUE,"UInt",BYTES,"UInt *",0)
         return numget(MVALUE, 0, Type)
   return !ProcessHandle ? "Handle Closed:" closed : "Fail"
}


/*
ReadMemory(MADDRESS=0,PROGRAM="",BYTES=4)
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

*/