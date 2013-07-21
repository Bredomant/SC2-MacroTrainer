
; returns the Install path
; e.g.	C:\Games\StarCraft II\

StarcraftInstallPath()
{
	if A_Is64bitOS
		RegRead, SC2InstallPath, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Blizzard Entertainment\StarCraft II Retail, InstallPath
	else 
		RegRead, SC2InstallPath, HKEY_LOCAL_MACHINE, SOFTWARE\Blizzard Entertainment\StarCraft II Retail, InstallPath
	return SC2InstallPath
}