CheckForUpdates(installed_version, url)
{
	global latestVersion
	latestVersion := ""
	URLDownloadToFile, %url%, %A_Temp%\version_checker_temp_file.txt
	if !ErrorLevel 
	{	
		FileRead latestVersion, %A_Temp%\version_checker_temp_file.txt
		FileDelete %A_Temp%\version_checker_temp_file.txt
		If ( latestVersion > installed_version )
			Return 1 ; update exist
		Return 0 ; no update
	}
	Return 3 ;RETURN 3 for error
}