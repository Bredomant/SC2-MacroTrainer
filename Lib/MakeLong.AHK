;=======================================================================================
;    Method:             MakeLong
;    Description:        Creates a LongWord from a LoWord and a HiWord.
;=======================================================================================
        MakeLong(LoWord, HiWord)
        {
            return (HiWord << 16) | (LoWord & 0xffff)
        }