SendEmail(p_to, p_subject, p_message, oAttachments := "", user="Macro.Trainer@gmail.com", pass="PublicPasswordfwnk322rf2")
{
	pmsg          := ComObjCreate("CDO.Message")
	pmsg.From       := "MT BugReport@mail.com" ; """AHKUser"" <...@gmail.com>"
	pmsg.To       := p_to
	pmsg.BCC       := ""   ; Blind Carbon Copy, Invisable for all, same syntax as CC
	pmsg.CC       := "" ; "Somebody@somewhere.com, Other-somebody@somewhere.com"
	pmsg.Subject    := p_subject

	;You can use either Text or HTML body like

	getSystemTimerResolutions(MinTimer, MaxTimer)
	p_message 	.= "`n`n`n"
				. "General System Info:`n`n"
				. "Trainer Vr: " getProgramVersion() "`n"
				. "OSVersion: " A_OSVersion "`n"
				. "Is64bitOS: " A_Is64bitOS "`n"
				. "Language Code: " A_Language "`n"
				. "Language: " getSystemLanguage() "`n"
				. "Scipt & Path: " A_ScriptFullPath "`n"
				. "Screen Width: " A_ScreenWidth "`n"
				. "Screen Height: " A_ScreenHeight "`n"
				. "Screen DPI: " A_ScreenDPI "`n"
				. "MinTimer: " MinTimer "`n"
				. "MaxTimer: " MaxTimer "`n"

	pmsg.TextBody    := p_message
	;OR
	;pmsg.HtmlBody := "<html><head><title>Hello</title></head><body><h2>Hello</h2><br /><p>Testing!</p></body></html>"


	;sAttach         := "Path_Of_Attachment" ; can add multiple attachments, the delimiter is |


	if (oAttachments && isobject(oAttachments))
	{
		for index, attachmentPath in  oAttachments
			sAttach .= attachmentPath "|"
	}
	else if oAttachments
		sAttach := oAttachments
	sAttach := Trim(sAttach, "`t |")

	fields := Object()
	fields.smtpserver   := "smtp.gmail.com" ; specify your SMTP server
	fields.smtpserverport     := 465 ; 25
	fields.smtpusessl      := True ; False
	fields.sendusing     := 2   ; cdoSendUsingPort
	fields.smtpauthenticate     := 1   ; cdoBasic
	fields.sendusername := user
	fields.sendpassword := pass
	fields.smtpconnectiontimeout := 60
	schema := "http://schemas.microsoft.com/cdo/configuration/"


	pfld :=   pmsg.Configuration.Fields

	For field,value in fields
		pfld.Item(schema . field) := value
	pfld.Update()

	Loop, Parse, sAttach, |, %A_Space%%A_Tab%
		pmsg.AddAttachment(A_LoopField)
	pmsg.Send()
}