Url2Var(url)
{
	URLDownloadToFile, %url%, %A_Temp%\var_temp_file.txt
	if !ErrorLevel 
	{	
		FileRead output, %A_Temp%\var_temp_file.txt
		FileDelete %A_Temp%\var_temp_file.txt
	}
	Else
		output := "Error"
	Return output
}