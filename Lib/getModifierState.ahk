getModifierState()
{
    If GetKeyState("Shift", "P")
        Modifiers .= "+"
    If GetKeyState("Control", "P")
        Modifiers .= "^"
    If GetKeyState("Alt", "P")
        Modifiers .= "!"
    return Modifiers
}
