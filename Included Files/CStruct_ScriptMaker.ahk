

; http://www.autohotkey.com/community/viewtopic.php?f=2&t=84054&p=522501#p522501
; this is a very useful script
; although my program doesn't use it directly
; I have it here so it gets backed-up on github
; Class_CStruct cane be found in 
; SC2-MacroTrainer\Lib
#include C:\Users\Matthieu\Desktop\GIT Repos\SC2-MacroTrainer\Lib\Class_CStruct.ahk
#SingleInstance Force


Ver = 1.5	; last update : 2012.04.30

;   ===================================================
;   CStruct Class Script Maker GUI   (AHK_L)
;   ===================================================
	gui_margin := 10, width := 1100, height := 600
	W1 := width/2 - gui_margin * 2 - 100
	W2 := width/2 - gui_margin * 2 + 0
	H := height - gui_margin * 2
	Gui, +LastFound
	Gui, Margin, %gui_margin%, %gui_margin%
	Gui, Add, Edit, w%W1% h%H% t4 VScroll HScroll Section wantTab vInputText
	Gui, Add, Button, ys w100 Section vParseButton gParseStruct, Parse (F1)
	Gui, Add, Button, wp vCopyButton gCopy, Copy
	Gui, Add, Button, y+30 wp vClearButton gClear, Clear
	Gui, Add, Checkbox, xp+4 y+20 vClassInclude gCheckClassInclude, Class Include
	Gui, Add, Edit, ys w%W2% h%H% t4 VScroll HScroll wantTab hwndhOutPutText vOutputText
	Gui, Show, w%Width% h%Height% , 'CStruct Class' Script Maker    Ver. %Ver%
	GuiControl, Hide, ClassInclude
	gui_handle := WinExist()
	CStruct_Maker.LoadWinDef()
Return

GuiClose:
ExitApp

CheckClassInclude:
ParseStruct:
	Gui, Submit, NoHide
	lineMark := ";=======================================================================`n"
	pos_old := 1
	index = 1
	while, % pos := RegExMatch(InputText, "(\n([\s|\t]*)\n+)\w", p, pos_old)
	{
		StringMid, Input%index%, InputText, pos_old, pos-pos_old
		pos_old := pos + strlen(p1), index++
	}
	StringMid, Input%index%, InputText, pos_old, strlen(InputText)-pos_old
	
	clsNameList := {}
	OutputText =
	loop % index
	{
		obj := CStruct_Maker.ParseStruct(input := Input%A_index%, ClassInclude)
		if obj.hasParsedLine
			clsNameList[obj.name] := 1
	}

	insideCount := 0
	validLoopCount := 0
	loop % index
	{
		obj := CStruct_Maker.ParseStruct(input := Input%A_index%, ClassInclude, clsNameList)
		if !obj.hasParsedLine
			continue
		if (validLoopCount++)
			OutputText .= lineMark
		OutputText .= obj.class "`n`n"
		insideCount += obj.insideCount
	}

	vSbPos := DllCall("GetScrollPos", "UPTR",hOutPutText, "int", SB_VERT:=1)
	GuiControl,, OutputText, % OutputText
	if insideCount
		GuiControl, Show, ClassInclude
	else
		GuiControl, Hide, ClassInclude
	SCR_wParam := (vSbPos << 16) | 4
	SendMessage, WM_VSCROLL:=0x115, SCR_wParam,, Edit2, ahk_id %gui_handle%
return

Copy:
	Clipboard := RegExReplace(OutputText, "(?<!`r)`n", "`r`n")
return

Clear:
	GuiControl,, InputText
	GuiControl,, OutputText
	GuiControl, Hide, ClassInclude
return

~F1::
	IfWinActive, ahk_id %gui_handle%
		Gosub, ParseStruct
return

;------------------------------------------------------------------------------------------------
class CStruct_Maker
{
	static cmd_AddStructVar := "this.AddStructVar"
	static cmd_SetStructCapacity := "this.SetStructCapacity"
	static cmd_unionStart := "union_start"
	static cmd_unionEnd   := "union_end"
	static lastClassNameMark := "____last____ClassName____"
	static file_winDef := A_WorkingDir "\WinDef.txt"
	static winDef := ""
	
	;return = {name, class}
	ParseStruct(inputText, classInclude=0, addedClassNameList="", defaultName="CStruct", @t0=0, parent="")
	{
		namespace =
		structName =
		if !IsObject(addedClassNameList)
			addedClassNameList := {}
		outputText := "@t" @t0 "class @rootClass extends CStruct_Base`n@t" @t0 "{`n@t" @t0+1 "__New()`n@t" @t0+1 "{"	;@tn - Tab count
		inputText := RegExReplace(inputText, "`a)//.*|#.*|/\*.*?\*/")
		blockNumber := 0
	    pos := 1
		Loop
		{
			if !(i := RegExMatch(InputText, "s).*?({|;|})", t, pos))
				break
			pos := i+StrLen(t)
			t := this.DeleteSideSpace(t)
			
			if (t1 = "{")
			{
				blockNumber++
				if blockNumber=1
					structName := this.GetStructName(t)
				if parent
				{
					if !structName
						structName := defaultName
					StringReplace, outputText, outputText, @rootClass, % structName
				}
				if blockNumber>1
				{
					if !insideStruct and RegExMatch(t, "^struct(?:\s+(\w*))*{$")
					{
						StringReplace, t, t, struct{, struct {
						insideStruct := t
						insideStructCount++
						insideStructBlockNumber := blockNumber
						continue
					}
					if insideStruct
					{
						insideStruct .= t
						continue
					}
				}
				if RegExMatch(t, "^union(?:\s+(\w*))*{$")
					unionBlock := "start"
			}
			else if (t1 = "}")
			{
				blockNumber--
				if insideStruct
				{
					insideStruct .= t
					if (insideStructBlockNumber = blockNumber+1)
					{
						obj := this.ParseStruct(insideStruct, classInclude, addedClassNameList, defaultName . "in" . insideStructCount
							, classInclude? @t0+1:@t0, parent? parent "." structName:"@rootClass")
						insideStructClass .= "`n@t" (classInclude? @t0+1:@t0) ";-----------------------------------------`n" obj.class
						lastClassName := obj.name
						insideStruct := ""
					}
					continue
				}
				if (unionBlock="union")
				{
					unionBlock := ""
					newLine := lastLine
					StringReplace, newLine, newLine, ), % ", """ this.cmd_unionEnd """)"
					StringReplace, outputText, outputText, % lastLine, % newLine
				}
			}
			else 
			{
				if (t=";")
					if !lastClassName
						continue
					else
						t := "struct" insideStructCount ";"
				if insideStruct
				{
					insideStruct .= t
					continue
				}
				if lastClassName
					t := this.lastClassNameMark " " t
				if !(field := this.ParseField(t, unionBlock, addedClassNameList, api_ID_list, exist_ClassType_list, @t0))
				{
					lastClassName := ""
					continue
				}
				allLine := field.allLine
				lastLine := field.lastLine
				if lastClassName
				{
					StringReplace, allLine, allLine, % this.lastClassNameMark, % lastClassName, All
					StringReplace, lastLine, lastLine, % this.lastClassNameMark, % lastClassName, All
					lastClassName := ""
				}
				if (unionBlock="start")
					unionBlock := "union"
				outputText .= allLine
			}
		}
		if structName=
		{
			StringGetPos, pos, InputText, }, R1
			if pos<>-1
				structName := this.GetStructName(SubStr(InputText, pos+1))
		}
		if !this.DeleteSideSpace(structName) or RegExMatch(structName, "\W")
			structName := defaultName

		outputText := outputText "`n@t" @t0+2 this.cmd_SetStructCapacity "()`n@t" @t0+1 "}`n@t" @t0 "@AreaInside}@AreaOutside"
		if insideStructClass
			StringReplace, outputText, outputText, % classInclude? "@AreaInside":"@AreaOutside", % "@t" @t0+1 insideStructClass "`n@t" @t0
		outputText := RegExReplace(outputText, "@AreaInside|@AreaOutside") 
		if !parent
			StringReplace, outputText, outputText, @rootClass, % structName, All
		loop, parse, api_ID_list, `,
		{
			value := org := A_LoopField
			ok := 0
			loop
			{
				if !this.Search(value, value) or !value
					break
				if value is not integer
					continue
				StringReplace, outputText, outputText, % "<" org ">", % value, All
				ok := 1
				break
			}
			if !ok
				StringReplace, outputText, outputText, % "<" A_LoopField ">", % A_LoopField, All
		}
		loop, parse, exist_ClassType_list, `,
		{
			StringSplit, type, A_LoopField, |
			existListStr .= "@t" @t0 ";" type1 " -> " type2 ": use defined class.`n"
		}
		;check exist current struct class
		cls := new %structName%
		if (cls.__Base="CStruct_Base")
			existListStr := "@t" @t0 ";""" structName """ structure class aleady defined. check the include file.`n" existListStr
		if existListStr
			outputText := existListStr "`n" outputText
		
		outputText := this.GetTabChangeData(outputText, @t0)
		obj := {"name":(classInclude? (parent? parent ".":""):"") structName, "class":outputText
				, "insideCount":insideStructCount, "hasParsedLine":(lastLine? 1:0)}
		return obj
	}
	
	
	;-----------------------------------
	GetTabChangeData(t, @t0)
	{
		backup := A_FormatInteger
		SetFormat, integer, D
		curTab := 0
		loop
		{
			IfNotInString, t, % "@t" curTab:=A_index-1
			if (curTab >= @t0)
				break
			if curTab
				tabs .= "`t"
			if (curTab < @t0)
				continue
			StringReplace, t, t, @t%curTab%, % tabs, All
		}
		SetFormat, integer, % backup
		return t
	}
	
	GetStructName(t)
	{
		s := RegExReplace(t, ",.*|FARSTRUCT|struct|typedef|tag|{|}|;|\*|_|\s")
		StringReplace, s, s, % " ",, All
		return (s="")? "": "C" s
	}
	
	;unionBlock = "start" or "union" or ""
	ParseField(t, unionBlock, addedClassNameList, ByRef api_ID_list, ByRef exist_ClassType_list, @t0)
	{
		obj := {}
		IfInString, t, `,
		{
			if RegExMatch(t, "^\s*(?<Type>(?:[\w]+[ \t])*)(?<Name>(?:[\w]+,))", m)
			{
				StringReplace, t, t, % mType
				loop, Parse, t, `,
				{
					if !(o := this.ParseField(mType " " A_LoopField ";", unionBlock, addedClassNameList, api_ID_list, exist_ClassType_list, @t0))
						return 0
					obj.allLine .= o.allLine
				}
				obj.lastLine := o.lastLine
				return obj
			}
			else
				return 0
		}
		if !RegExMatch(t, "^\s*(?<Type>(?:[\w]+[ \t])*[\w]+)(?<Sep>[\s\*]+)(?<Name>\w+)(?:\[(?<Count>.+)\])?\s*;", m)
		if !RegExMatch(t, "^\s*(?<Type>(?:[\w]+[ \t])*[\w]+)(?<Sep>[\s\*]+)(?<Name>\w+)([\s:]+(?<BitField>.+))?\s*;", m)
			return 0
		if !mBitField
		{
			StringReplace, mSep, mSep, % " ",, All
			loop, parse, mCount, % "+ "
			{
				if !A_LoopField
					continue
				if A_LoopField is Integer
					continue
				this.StackPush(api_ID_list, A_LoopField, 1)
				StringReplace, mCount, mCount, % A_LoopField, % "<" A_LoopField ">", All
			}
		}
		mType := (InStr(mSep,"*"))? "UPtr" : RegExReplace(mType, "\s")
		typeComment := this.GetValidVarType(oldType:=mType, mType, addedClassNameList)? "":"`t`t;** undefined var type **"
		if (mType<>oldType)	;exist struct class
			this.StackPush(exist_ClassType_list, oldType "|" mType, 1)
		unionState := (unionBlock="start")? this.cmd_unionStart:""
		obj.allLine := obj.lastLine := "`n@t" @t0+2 this.cmd_AddStructVar "(""" mName """, """ mType """" (strlen(mBitField)? ", ""bit:" mBitField """":"") 
		. (mCount? ", " mCount:"") (unionState? ", """ unionState """":"") ")" typeComment
		return obj
	}
	
	DeleteSideSpace(t)
	{
		return RegExReplace(t, "(?:^\s+)")
	}
	
	StackPush(ByRef stack, item, sameItemNotInput=0)
	{
		if sameItemNotInput and InStr(stack, item)
			return
		if stack
			stack := "," stack
		stack := item stack
	}
	
	StackPop(ByRef stack, defval="")
	{
		if (pos := InStr(stack, ","))
		{
			item := SubStr(stack, 1, pos-1)
			stack := SubStr(stack, pos+1)
			return item
		}
		else if stack
		{
			item := stack
			stack := ""
			return item
		}
		return defval
	}
	
	StackPeek(ByRef stack, defval="")
	{
		if (pos := InStr(stack, ","))
			return SubStr(stack, 1, pos-1)
		else if stack
			return stack
		else
			return defval
	}

	LoadWinDef()
	{
		if IsObject(this.winDef)
			return 1
		IfNotExist, % this.file_winDef
			return 0
		FileRead Contents, % this.file_winDef
		this.winDef := {}
		loop Parse, Contents, `n, `r
			if (RegExMatch(A_LoopField, "(?P<Name>(?P<Index>\w)\w+?)\s+:=\s+(?P<Value>.*)", _))
			{
				if !IsObject(this.winDef[_Index])
					this.winDef[_Index] := {}
				this.winDef[_Index].Insert({Name:_Name, Value:_Value})
			}
			Contents := ""
		if IsObject(this.winDef)
			return 1
		else
			return 0
	}

	Search(Query, ByRef value)
	{
		if !IsObject(this.winDef)
			return 0
		for k, v in this.winDef[SubStr(Query, 1, 1)]
			if (v.Name = Query)
			{
				value := v.Value
				return 1
			}
		return 0
	}

	GetValidVarType(type, ByRef validType, addedClassNameList)
	{
		if (type=this.lastClassNameMark)
			return 1
		if RegExMatch(type, "[^_\w]")
			return 0
		if CStruct_Base.sizeof(type)
		{
			validType := type
			return 1
		}
		type := "C" RegExReplace(type, "_")
		cls := new %type%
		if (cls.__base="CStruct_Base") or ObjHasKey(addedClassNameList, type)
		{
			validType := type
			return 1
		}
		return 0
	}
}


















