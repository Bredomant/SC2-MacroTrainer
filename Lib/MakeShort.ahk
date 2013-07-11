;=======================================================================================
;    Method:             MakeLong
;    Description:        Extracts LoWord and HiWord from a LongWord.
;=======================================================================================
        MakeShort(Long, ByRef LoWord, ByRef HiWord)
        {
            LoWord := Long & 0xffff
        ,   HiWord := Long >> 16
        }