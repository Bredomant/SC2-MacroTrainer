RandomiseSimpleArray(byref a_Array)
{
	while (a_index <= a_Array.MaxIndex())
	{
		Random, i, a_Array.MinIndex(), a_Array.MaxIndex()
		storage := a_Array[a_index]
		a_Array[a_index] := a_Array[i]
		a_Array[i] := storage	
	}
	return
}
