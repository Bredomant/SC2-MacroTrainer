getModifiersFromString(string)
{	static aModifiers := ["*", "+", "^", "!"]
	
	for index, modifier in 	aModifiers
		if inStr(string, modifier)
			result .= modifier
	return result
}
