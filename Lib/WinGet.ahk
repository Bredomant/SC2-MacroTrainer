WinGet(Cmd = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "")
{
	WinGet, Output , %Cmd%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return Output
}
