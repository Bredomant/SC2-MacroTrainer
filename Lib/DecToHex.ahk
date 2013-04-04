DecToHex(Value)
{
	SetFormat IntegerFast, Hex
	Value += 0
	Value .= "" ;required due to 'fast' mode
	SetFormat IntegerFast, D
	Return Value
}
