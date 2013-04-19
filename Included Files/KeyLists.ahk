    l_StandardKeysList=
       (ltrim join|
        A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z
        0|1|2|3|4|5|6|7|8|9|0
        ``|-|=|[|]|`\|;
        '|,|.|/
        Space
        Tab
        Enter
        Escape
        Backspace
        Delete
        ScrollLock
        CapsLock
        NumLock
        PrintScreen
        CtrlBreak
        Pause
        Break
        Insert
        Home
        End
        PgUp
        PgDn
        Up
        Down
        Left
        Right
       )
	  l_FunctionKeysList=
       (ltrim join|
        F1|F2|F3|F4|F5|F6|F7|F8|F9|F10
        F11|F12|F13|F14|F15|F16|F17|F18|F19|F20
        F21|F22|F23|F24
       )
      l_ModifierKeysList := "Shift|Control|Alt"
    ;-- Numpad
    l_NumpadKeysList=
       (ltrim join|
        NumLock
        NumpadDiv
        NumpadMult
        NumpadAdd
        NumpadSub
        NumpadEnter
        NumpadDel
        NumpadIns
        NumpadClear
        NumpadUp
        NumpadDown
        NumpadLeft
        NumpadRight
        NumpadHome
        NumpadEnd
        NumpadPgUp
        NumpadPgDn
        Numpad0
        Numpad1
        Numpad2
        Numpad3
        Numpad4
        Numpad5
        Numpad6
        Numpad7
        Numpad8
        Numpad9
        NumpadDot
       )
		 ; *LButton	;note Lbutton may not work due to modifiers and so needs this
		; but when blocking the mouse, can cause the drag issue
    ;-- Mouse
    l_MouseKeysList=
       (ltrim join|
        LButton
        RButton
        MButton
        WheelDown
        WheelUp
        XButton1
        XButton2
       )

    ;-- Multimedia
    l_MultimediaKeysList=
       (ltrim join|
        Browser_Back
        Browser_Forward
        Browser_Refresh
        Browser_Stop
        Browser_Search
        Browser_Favorites
        Browser_Home
        Volume_Mute
        Volume_Down
        Volume_Up
        Media_Next
        Media_Prev
        Media_Stop
        Media_Play_Pause
        Launch_Mail
        Launch_Media
        Launch_App1
        Launch_App2
       )
	   
