Goto, ColourSector>
ColourSelectorSave:

%CS_LaunchedColour% := CS_TransparencySlider CS_colour ;save the new colour to the variable stored in the variablde :(
CS_LaunchedColour := "_"  CS_LaunchedColour	;get the handle name
if ( CS_LaunchedColour = "_UnitHighlightInvisibleColour" || CS_LaunchedColour = "_UnitHighlightHallucinationsColour")
	paintPictureControl(%CS_LaunchedColour%, CS_colour, CS_TransparencySlider, 50,22) ; draw it with a width of 50, as I'm not sure how to make the function get the controls width from the other gui
Else paintPictureControl(%CS_LaunchedColour%, CS_colour, CS_TransparencySlider, 300,22)
Gui, Options:-Disabled  
Gui, Destroy
Return

ColourSelector:
CS_LaunchedColour := SubStr(A_GuiControl, 2)	;drops the # and allows colour to be saved 

width := 300 , height := 300 
WidthTmp := width +16 , HeightTmp := height +16

Gui, New
; Gui, +LastFound not needed?
;HWND := WinExist()

Gui, Add, Slider, x5 y2 Line10 NoTicks Range0-510 Vertical +AltSubmit  vCS gCS h%HeightTmp%  ; Colour Slider
Gui, Add, Picture, x30 y10 h%height% 0xE  HWND_BAR gInvoke_Slide			;colour slither
Gui, Add, Picture, x+30 y10 0xE w%width% h%height% section  HWND_PRGS_ gChoosecolour				;colour box
Gui, Add, Picture, x+10 y10 h%height% 0xE  HWND_TransScale			;Transparency Scale Pic
Gui, Add, Slider, x+15 y2 h%HeightTmp% Line10 NoTicks Range0-255 Vertical Invert Left +AltSubmit  vCS_TransparencySlider gCS , 255 ;slider

Gui, Add, GroupBox, x10 y+5 w285 h80 section, Selected Colour
Gui, Add, Picture, xp+15 yp+20 w255 h50  0xE HWND_ColourIndicator 
paintPictureControl(_ColourIndicator, CS_colour := %CS_LaunchedColour%,,,, 10)
Gui, Add, Button, x+20 ys+5 gColourSelectorSave w100 h35, Save Changes
Gui, Add, Button, gGuiClose w100 h35, Cancel

CreateTransparencyScale(_TransScale)
CreateColourRainbow(_BAR)

CreateSpectrum(_PRGS_, 255, 0, 0, , True, Height, Width)
CS_TransparencySlider := "0xFF" 
Gui, Show, 
Gui, +OwnerOptions
Gui, Options:+Disabled
return

Invoke_Slide:	;colour chart
MouseGetPos,, CS
GuiControl,, CS, % CS -= 33

CS:		;slider
Critical	;required to stop blinking
GuiControlGet, CS_TransparencySlider
CS_TransparencySlider := DecToHex(CS_TransparencySlider)
GuiControlGet, CS
CalcCS(CS, 85, CSR, CSG, CSB)
CreateSpectrum(_PRGS_, CSR, CSG, CSB, CS_TransparencySlider,, Height, Width)
paintPictureControl(_ColourIndicator, CS_colour, CS_TransparencySlider,,, 10)
Critical, Off
return


Choosecolour: ; big colour chart
MouseGetPos, X, Y
PixelGetcolor, CS_colour, % X, % Y, RGB
CS_colour := SubStr(CS_colour, 3)
paintPictureControl(_ColourIndicator, CS_colour, CS_TransparencySlider,,, 10)
return
paintPictureControl(Handle, Colour, Transparency = "FF", ControlW = "", ControlH = "", RoundCorner=0)
{ 
	if substr(Transparency, 1, 2) = "0x"
		Transparency := substr(Transparency, 3)
	if substr(Colour, 1, 2) = "0x"
		Colour := substr(Colour, 3)
	if StrLen(Colour) > 6	; account for included transparency in colour str
	{	Transparency := substr(Colour, 1, 2)
		Colour := substr(Colour, 3, 6)		
	}
	If (ControlW = "" OR ControlH = "")
		GuiControlGet, Control, Pos, %Handle%
	pBitmap  := Gdip_CreateBitmap(ControlW, ControlH)
	G := Gdip_GraphicsFromImage(pBitmap)
	pBrushBackground  := Gdip_BrushCreateSolid("0xFFF0F0F0") 	;cover the edges of the pic
	Gdip_FillRectangle(G, pBrushBackground, 0, 0, ControlW, ControlH)
	pBrush  := Gdip_BrushCreateSolid("0x" Transparency Colour)
	if RoundCorner
	{
		Gdip_SetSmoothingMode(G, 4)
		Gdip_FillRoundedRectangle(G, pBrush, 0, 0, ControlW, ControlH, RoundCorner)
	}
	Else 
	{
		Gdip_FillRectangle(G, pBrush, 0, 0, ControlW, ControlH)
		pPen := Gdip_CreatePen(0xFF000000, 1)
		Gdip_DrawRectangle(G, pPen, 0, 0, ControlW-1, ControlH-1) 
		Gdip_DeletePen(pPen)	
	}	
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(Handle, HBitmap)	
	Gdip_DeleteBrush(pBrush), Gdip_DeleteBrush(pBrushBackground), Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
	Return
}

paintPicture(File, Colour, Transparency = "FF", ControlW = "", ControlH = "", RoundCorner=0)
{ 
	if substr(Transparency, 1, 2) = "0x"
		Transparency := substr(Transparency, 3)
	if substr(Colour, 1, 2) = "0x"
		Colour := substr(Colour, 3)
	if StrLen(Colour) > 6	; account for included transparency in colour str
	{	Transparency := substr(Colour, 1, 2)
		Colour := substr(Colour, 3, 6)		
	}

	If (ControlW = "" OR ControlH = "")
		GuiControlGet, Control, Pos, %Handle%
	pBitmap  := Gdip_CreateBitmap(ControlW, ControlH)
	G := Gdip_GraphicsFromImage(pBitmap)
	pBrushBackground  := Gdip_BrushCreateSolid("0xFFF0F0F0") 	;cover the edges of the pic
	Gdip_FillRectangle(G, pBrushBackground, 0, 0, ControlW, ControlH)
	pBrush  := Gdip_BrushCreateSolid("0x33" Colour)
	;pBrush  := Gdip_BrushCreateSolid("0x" Transparency Colour)
	if RoundCorner
	{
		Gdip_SetSmoothingMode(G, 4)
		Gdip_FillRoundedRectangle(G, pBrush, 0, 0, ControlW, ControlH, RoundCorner)
	}
	Else 
		Gdip_FillRectangle(G, pBrush, 0, 0, ControlW, ControlH)
	Gdip_SaveBitmapToFile(pBitmap, File)
	Gdip_DeleteBrush(pBrush), Gdip_DeleteBrush(pBrushBackground), Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap)
	Return
}


HexFromRGB(@colourR, @colourG, @colourB)
{
   SetFormat IntegerFast, Hex
   colour := 0x1000000 + (@colourR << 16) + (@colourG << 8) + @colourB
   StringTrimLeft colour, colour, 3
   colour .= ""
   SetFormat IntegerFast, D
   return colour
}
CalcCS(CS, CSDiv, ByRef CSR, ByRef CSG, ByRef CSB)
{
	If (CS//CSDiv = 0 || CS//CSDiv = 3)
	   CSR := (CS//CSDiv = 0) ? 255 : 0, CSG := (CS//CSDiv = 0) ? 0 : 255, CSB := (CS//CSDiv = 0) ? Round((CS/CSDiv - CS//CSDiv) * 255) : 255 - Round((CS/CSDiv - CS//CSDiv) * 255)
	Else If (CS//CSDiv = 1 || CS//CSDiv = 4)
	   CSR := (CS//CSDiv = 1) ? 255 - Round((CS/CSDiv - CS//CSDiv) * 255) : Round((CS/CSDiv - CS//CSDiv) * 255), CSG := (CS//CSDiv = 1) ? 0 : 255, CSB := (CS//CSDiv = 1) ? 255 : 0
	Else If (CS//CSDiv = 2 || CS//CSDiv = 5)
	   CSR := (CS//CSDiv = 2) ? 0 : 255, CSG := (CS//CSDiv = 2) ? Round((CS/CSDiv - CS//CSDiv) * 255) : 255 - Round((CS/CSDiv - CS//CSDiv) * 255), CSB := (CS//CSDiv = 2) ? 255 : 0
	return
}



CreateColourRainbow(Handle, Width=15, Height=300)
{
	BAR := Gdip_CreateBitmap(Width, Height)
	BG := Gdip_GraphicsFromImage(BAR)
	Gdip_SetSmoothingMode(BG, 1)
	Loop, 255 ;creates the slider colour display
	{
		CalcCS(A_Index, 42.5, CSR, CSG, CSB)
		B_PBRUSH:=Gdip_CreateLineBrushFromRect(0, A_Index*2-1, Width, 2, "0xFF" . HexFromRGB(CSR, CSG, CSB), "0xFF" . HexFromRGB(CSR, CSG, CSB), 0, 0)
		Gdip_FillRectangle(BG, B_PBRUSH, 0, A_Index*2-1, Width, 2)
		Gdip_DeleteBrush(B_PBRUSH)
	}
	B_HBITMAP := Gdip_CreateHBITMAPFromBitmap(BAR)

	SetImageX(Handle, B_HBITMAP)
	Gdip_DeleteGraphics(BG)
	Gdip_DisposeImage(BAR)
	DeleteObject(B_HBITMAP)
	Return
}
CreateTransparencyScale(Handle, Width=15, Height=300)
{
	BAR := Gdip_CreateBitmap(Width, Height)
	BG := Gdip_GraphicsFromImage(BAR)
	CalcCS(A_Index, 42.5, CSR, CSG, CSB)
	B_PBRUSH:=Gdip_CreateLineBrushFromRect(0, A_Index*2-1, Width, Height, "0xFF000000" , "0xFFFFFFFF", 1, 2)
	Gdip_FillRectangle(BG, B_PBRUSH, 0, A_Index*2-1, Width, Height)
	Gdip_DeleteBrush(B_PBRUSH)
	B_HBITMAP := Gdip_CreateHBITMAPFromBitmap(BAR)
	SetImageX(Handle, B_HBITMAP)
	Gdip_DeleteGraphics(BG)
	Gdip_DisposeImage(BAR)
	DeleteObject(B_HBITMAP)
	Return
}

CreateSpectrum(Handle="ImSoVeryLazy", R=255,G=0,B=0, Transparency="0xFF", Setup=False, Width=300, Height=300)
{
	static _PBRUSH_
	_PROGRESS_:=Gdip_CreateBitmap(Width, Height)
	_G_ := Gdip_GraphicsFromImage(_PROGRESS_)
	Gdip_SetSmoothingMode(_G_, 1)
	If (Handle = "ImSoVeryLazy" And Setup <> "Shutdown")
		Msgbox Error No handle Used in Function: %A_ThisFunc%		
   Else If (Setup)
   {
		pBrushBackground  := Gdip_BrushCreateSolid("0xFFF0F0F0") 	;cover the edges of the pic
		Gdip_FillRectangle(_G_, pBrushBackground, 0, 0, Width, Height)
	  Loop, 255
	  {
		 _PBRUSH_:=Gdip_CreateLineBrushFromRect(0, A_Index*2-1, Width, 2, Transparency . HexFromRGB(256 - A_Index, 256 - A_Index, 256 - A_Index), Transparency . HexFromRGB(R - A_Index, 0, 0), 0, 0)
		 Gdip_FillRectangle(_G_, _PBRUSH_, 0, A_Index*2-1, Width, 2)
	  }
   }
   Else If setup = "Shutdown"
		Gdip_DeleteBrush(_PBRUSH_)
   Else 
   {
		pBrushBackground  := Gdip_BrushCreateSolid("0xFFF0F0F0") 	;cover the edges of the pic
		Gdip_FillRectangle(_G_, pBrushBackground, 0, 0, Width, Height)
	  Loop, 255
	  {
		 _PBRUSH_:=Gdip_CreateLineBrushFromRect(0, A_Index*2-1, Width, 2, Transparency . HexFromRGB(256 - A_Index, 256 - A_Index, 256 - A_Index), Transparency . HexFromRGB((R - Ceil(A_Index / Floor(256 / R)) < 0) ? 0 : R - Ceil(A_Index / Floor(256 / R)), (G - Ceil(A_Index / Floor(256 / G)) < 0) ? 0 : G - Ceil(A_Index / Floor(256 / G)), (B - Ceil(A_Index / Floor(256 / B)) < 0) ? 0 : B - Ceil(A_Index / Floor(256 / B))), 0, 0)
		 Gdip_FillRectangle(_G_, _PBRUSH_, 0, A_Index*2-1, Width, 2)
	  }
   }
	 Gdip_DeleteBrush(pBrushBackground)
	_HBITMAP_:=Gdip_CreateHBITMAPFromBitmap(_PROGRESS_)
	SetImageX(Handle, _HBITMAP_)	
	Gdip_DeleteGraphics(_G_)
	Gdip_DisposeImage(_PROGRESS_)
	DeleteObject(_HBITMAP_)
	Return
}
ColourSector>: