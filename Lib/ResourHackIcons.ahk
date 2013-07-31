ResourHackIcons(dotIcoFile)
{
	if !A_IsCompiled
		return
	msgbox This will attempt to change the included icons inside the binary file.`n`nThis may not work!`n`nOnly .ico files are compatible.`n`nThe program will close and attempt the operation. This will take around 10 seconds.
	FileCreateDir, %A_Temp%\Resource Hacker
	FileInstall, Included Files\Resource Hacker\Dialogs.def, %A_Temp%\Resource Hacker\Dialogs.def, 1 
	FileInstall, Included Files\Resource Hacker\ResHacker.cnt, %A_Temp%\Resource Hacker\ResHacker.cnt, 1 
	FileInstall, Included Files\Resource Hacker\ResHacker.exe, %A_Temp%\Resource Hacker\ResHacker.exe, 1 
	FileInstall, Included Files\Resource Hacker\ResHacker.hlp, %A_Temp%\Resource Hacker\ResHacker.hlp, 1 
	FileInstall, Included Files\Resource Hacker\ResHacker.ini, %A_Temp%\Resource Hacker\ResHacker.ini, 1 

	Rscript := "[FILENAMES]"
			.	"`nExe= " A_ScriptFullPath
			. "`nSaveAs= " A_ScriptFullPath
			. "`n[COMMANDS]"
		;	. "`n-addoverwrite " dotIcoFile ", ICONGROUP,MAINICON,0"
			. "`n-addoverwrite " dotIcoFile ", icon, 159,"
			. "`n-addoverwrite " dotIcoFile ", icon, 160,"
			. "`n-addoverwrite " dotIcoFile ", icon, 206,"
			. "`n-addoverwrite " dotIcoFile ", icon, 207,"
			. "`n-addoverwrite " dotIcoFile ", icon, 208,"
			. "`n-addoverwrite " dotIcoFile ", icon, 228,"
			. "`n-addoverwrite " dotIcoFile ", icon, 229,"
			. "`n-addoverwrite " dotIcoFile ", icon, 230,"

	FileDelete, %A_Temp%\Resource Hacker\Rscript.txt
	FileAppend, %Rscript%, %A_Temp%\Resource Hacker\Rscript.txt

	AhkScript := "#NoEnv"
		. "`n#SingleInstance force"
		. "`nSetWorkingDir %A_ScriptDir%"
		. "`nsleep 4000" ;give time for macro trainer to close so can open in reshackers
		. "`nRun,  %A_Temp%\Resource Hacker\ResHacker.exe -script Rscript.txt"
		. "`nRun,  ResHacker.exe -script Rscript.txt, %A_Temp%\Resource Hacker\"
		. "`nmsgbox I just tried to change the included icon files``nDon't know if it worked.``n``nPress ok to re-launch the macro-trainer to find out"
		. "`nrun, " A_ScriptFullPath ;attempt to launch the original program
		. "`nExitapp"

		DynaRun(AhkScript, "ChangeIcon.AHK", A_Temp "\AHK.exe") 
		ExitApp
}