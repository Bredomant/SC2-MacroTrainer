getKeyboardAndMouseButtonArray(keyList=31)   ;31 will get entire keylist excluding modifiers 
{   ; Included Lists are: l_StandardKeysList,  l_ModifierKeysList, l_FunctionKeysList, l_NumpadKeysList, l_MouseKeysList, l_MultimediaKeysList
    #IncludeAgain %A_ScriptDir%\Included Files\KeyLists.ahk
    l_Keys := []
    if (keyList & 1)
        loop, parse, l_StandardKeysList, |
            l_Keys.insert(A_Loopfield)
    if (keyList & 2)
        loop, parse, l_FunctionKeysList, |
            l_Keys.insert(A_Loopfield)        
    if (keyList & 4)
        loop, parse, l_NumpadKeysList, |
            l_Keys.insert(A_Loopfield)           
    if (keyList & 8)
        loop, parse, l_MouseKeysList, |
            l_Keys.insert(A_Loopfield)             
    if (keyList & 16)
        loop, parse, l_MultimediaKeysList, |
            l_Keys.insert(A_Loopfield)    
    if (keyList & 32)
        loop, parse, l_ModifierKeysList, |
            l_Keys.insert(A_Loopfield)    
    return l_Keys
}