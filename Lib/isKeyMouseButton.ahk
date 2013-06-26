isKeyMouseButton(key)
{
	STATIC MouseButtons :=  "LButton,RButton,MButton,XButton1,XButton2"
	
;	StringReplace, key, key, ^ 	;dont need these as using if var 'contain now' instead of if var in
;	StringReplace, key, key, +
;	StringReplace, key, key, !
;	StringReplace, key, key, *
	if key contains %MouseButtons% ;need to use contain as check for 'up modifier'
		return 1
	else return 0
}