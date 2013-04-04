Sort2DArray(Byref TDArray, KeyName, Order=1) 
{
    For index2, obj2 in TDArray 		 ;TDArray : a two dimensional TDArray
	{           						 ;KeyName : the key name to be sorted
        For index, obj in TDArray  		 ;Order: 1:Ascending 0:Descending
		{
            if (lastIndex = index)
                break
            if !(A_Index = 1) &&  ((Order=1) ? (TDArray[prevIndex][KeyName] > TDArray[index][KeyName]) : (TDArray[prevIndex][KeyName] < TDArray[index][KeyName])) 
			{       
			   address := &TDArray[index]              
			   PrevAddress := &TDArray[prevIndex]
			   TDArray[index] := Object(PrevAddress)                ;im not sure why this doesnt overwrite 
			   TDArray[prevIndex] := Object(address)				;the other...cos it was a pointer...but it works :D
            }         
            prevIndex := index
        }     
        lastIndex := prevIndex
    }
}