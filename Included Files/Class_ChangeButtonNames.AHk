/*
	This can change the button names of msgboxes
	It uses no global variables!
	It does have a label in global namespace 'ChangeButtonNamesFuncationLabelLongNameABCD1234'
	Use: 	Simply call ChangeButtonNames.set(WinTitle, NewButtonName)
			immediately before the msgbox.

	***Note:	You must still refer to the original msgbox button names 
				e.g. ifMsgbox Yes 
	Probably could make it so can do multiples msgboxes, but If its called immediately before the msgbox command, i cant
	foresee an issue
*/

class ChangeButtonNames
{
	static sWinTitle, sNewButtonName 
	set(WinTitle, NewButtonName*)
	{
		
		this.sNewButtonName := NewButtonName
		this.sWinTitle := WinTitle
		SetTimer, ChangeButtonNamesFuncationLabelLongNameABCD1234, 50 
		return 
	}
	getWinTitle()
	{
		return this.sWinTitle
	}
	getButtonNames() ; returns an object
	{
		return this.sNewButtonName
	}

}
ChangeButtonNamesFuncationLabelLongNameABCD1234:
	if (A_ThisLabel = "ChangeButtonNamesFuncationLabelLongNameABCD1234") ; so can be included in autoExec section
	{
		if !WinExist(ChangeButtonNames.getWinTitle())
		    return  ; Keep waiting.
		SetTimer,, Off ;uses A_Thislabel as labelname
		;winactivate(ChangeButtonNames.getWinTitle())
		for index, Name in ChangeButtonNames.getButtonNames()
			ControlSetText, Button%index%, &%Name%
		return
	}
