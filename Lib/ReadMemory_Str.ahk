; Automatically closes handle when a new (or null) program is indicated
; Otherwise, keeps the process handle open between calls that specify the
; same program. When finished reading memory, call this function with no
; parameters to close the process handle i.e: "Closed := ReadMemory_Str()"

;//function ReadMemory_Str 
ReadMemory_Str(MADDRESS=0, pOffset = 0, PROGRAM = "StarCraft II", length = 0 , terminator = "") 
{ 
   Static OLDPROC, ProcessHandle
   VarSetCapacity(MVALUE,4,0)
   If PROGRAM != %OLDPROC%
   {
      WinGet, pid, pid, % OLDPROC := PROGRAM
      ProcessHandle := ( ProcessHandle ? 0*(closed:=DllCall("CloseHandle"
      ,"UInt",ProcessHandle)) : 0 )+(pid ? DllCall("OpenProcess"
      ,"Int",16,"Int",0,"UInt",pid) : 0) ;PID is stored in value pid
   }
	If (MADDRESS = 0) 
		closed:=DllCall("CloseHandle","UInt",ProcessHandle)
	If ( length = 0) ; read until terminator found
	{
		teststr = 
        Loop
        { 
            Output := "x"  ; Put exactly one character in as a placeholder. used to break loop on null 
            tempVar := DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS+pOffset, "str", Output, "Uint", 1, "Uint *", 0) 
            if (ErrorLevel or !tempVar) 
               return teststr 
            if (Output = terminator)
              break 
            teststr .= Output 
            MADDRESS++ 
		} 
        return, teststr  
		}		
	Else ; will read until X length
	{
		 teststr = 
         Loop % length
         { 
            Output := "x"  ; Put exactly one character in as a memory placeholder. 
            tempVar := DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS+pOffset, "str", Output, "Uint", 1, "Uint *", 0) 
            if (ErrorLevel or !tempVar) 
              return teststr 
            teststr .= Output
            MADDRESS++ 
         } 
          return, teststr  
	}
		 
		 
}