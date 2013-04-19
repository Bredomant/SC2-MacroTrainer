setCase(Upper=0, string="", Title=0)
{
    if Upper
    {
        if title
            StringUpper, result, string, T 
        else StringUpper, result, string
    }
    Else
    {
        if title
            StringLower, result, string, T 
        else StringLower, result, string
    }
    return result
}