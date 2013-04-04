rand(a=0.0, b=1) 
{
	if (a = "")
		random, r, 0, b
	else random, r, a, b
	return r
}