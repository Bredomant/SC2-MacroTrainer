; returns the Game path
; e.g.	C:\Games\StarCraft II\StarCraft II.exe

StarcraftExePath()
{
	if A_Is64bitOS
		RegRead, GamePath, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Blizzard Entertainment\StarCraft II Retail, GamePath
	else 
		RegRead, GamePath, HKEY_LOCAL_MACHINE, SOFTWARE\Blizzard Entertainment\StarCraft II Retail, GamePath
	return GamePath
}