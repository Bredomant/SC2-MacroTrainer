addhex(var)
{
	SetFormat, IntegerFast, hex
	var := var
	SetFormat, IntegerFast, d
	return var
}