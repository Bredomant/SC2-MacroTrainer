/*
; ------------ Examples of usage ------------

PID = 1120          ; Process Id.
Address = 0xD0077C  ; Address to write to.
n = 123
d = 1.999
s = Hello, world!

WriteMemory(PID, Address, n, "Int")    ; Write an integer.
WriteMemory(PID, Address, d, "Double") ; Write a double.
WriteMemory(PID, Address, s)   ; Write a whole string
                                ; whith the null terminator.
WriteMemory(PID, Address, s, 5)    ; Write the first 5 characters only
                                    ; (without a null terminator).
VarSetCapacity(Buf, 8)
NumPut(123, Buf, 0, "Int")
NumPut(456, Buf, 4, "Int")

WriteMemory(PID, Address, &Buf, 8) ; Write 8 bytes from a buffer.

*/
; ------------ Function -----------------------

WriteMemory(PID, WriteAddress, Data, TypeOrLength = "")
{
    static PROCESS_VM_WRITE = 0x20
    static PROCESS_VM_OPERATION = 0x8
    static Buf := "        "    ; For numbers in binary form.

    hProcess := DllCall("OpenProcess"
                        , "UInt", PROCESS_VM_WRITE | PROCESS_VM_OPERATION
                        , "Int",  False
                        , "UInt", PID)

    If (!hProcess) {
        MsgBox, OpenProcess failed.
        Return False
    }

    If Data is Number   ; Either a numeric value or a memory address.
    {
        If TypeOrLength is Integer  ; Address of a buffer was passed.
        {
            DataAddress := Data
            DataSize := TypeOrLength    ; Length in bytes of the data in the buffer.
        }
        Else    ; A numeric value was passed.
        {
            If (TypeOrLength = "Double" or TypeOrLength = "Int64")
                DataSize = 8
            Else If (TypeOrLength = "Int" or TypeOrLength = "UInt"
                                          or TypeOrLength = "Float")
                DataSize = 4
            Else If (TypeOrLength = "Short" or TypeOrLength = "UShort")
                DataSize = 2
            Else If (TypeOrLength = "Char" or TypeOrLength = "UChar")
                DataSize = 1
            Else {
                MsgBox, Invalid type of number.
                DllCall("CloseHandle", "UInt", hProcess)
                Return False
            }
            NumPut(Data, Buf, 0, TypeOrLength)
            DataAddress := &Buf
        }
    }
    Else    ; Data is a string.
    {
        DataAddress := &Data
        If TypeOrLength is Integer  ; Length (in characters) was specified.
        {
            If A_IsUnicode
                DataSize := TypeOrLength * 2    ; 1 character = 2 bytes.
            Else
                DataSize := TypeOrLength
        }
        Else
        {
            If A_IsUnicode
                DataSize := (StrLen(Data) + 1) * 2  ; Take the whole string
            Else                                    ; with the null terminator.
                DataSize := StrLen(Data) + 1
        }
    }                                               

    Ret := DllCall("WriteProcessMemory", "UInt", hProcess
                                       , "UInt", WriteAddress
                                       , "UInt", DataAddress
                                       , "UInt", DataSize
                                       , "UInt", 0)

    DllCall("CloseHandle", "UInt", hProcess)

    If (!Ret) {
        MsgBox, WriteProcessMemory failed.
        Return False
    }

    Return True
}