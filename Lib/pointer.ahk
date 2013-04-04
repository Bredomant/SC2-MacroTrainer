pointer(game, base, offsets*)
{ 
	If offsets.MaxIndex() = 1
		pointer := offsets[1] + ReadMemory(base, game)
	Else
		For index, offset in offsets ; for count(any name here), value(storage) in array/offsets  
		{
			IF index = 1 
				pointer := ReadMemory(offset + ReadMemory(base, game), game)
			Else If (offsets.MaxIndex() = A_Index)
				pointer += offset
			Else pointer := ReadMemory(pointer + offset, game)
		}	
	Return ReadMemory(pointer, game)
}
