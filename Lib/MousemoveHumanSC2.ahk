MousemoveHumanSC2(options){
desiredx:=regexmatch(options,"i)x(\-?\d+)",m) ? m1:""
desiredy:=regexmatch(options,"i)y(\-?\d+)",m) ? m1:""
width:=regexmatch(options,"i)w(\d+)",m) ? m1:0					; These are the final X,Y result +/-
height:=regexmatch(options,"i)h(\d+)",m) ? m1:0					;
relative:=regexmatch(options,"i)r(\d+)",m) ? m1:false
time:=regexmatch(options,"i)t(\d+)",m)&&m1>0 ? m1:200
if desiredx=""||desiredy=""
		 return
batchlines:=a_batchlines
setbatchlines,-1
varsetcapacity(current,8)
dllcall("GetCursorPos","Uint",&current)
currentx:=numget(current,0,"Int")
currenty:=numget(current,4,"Int")
desiredx:=width ? rand(relative ? desiredx+currentx:desiredx,(relative ? desiredx+currentx:desiredx)+width):relative ? desiredx+currentx:desiredx
desiredy:=height ? rand(relative ? desiredy+currenty:desiredy,(relative ? desiredy+currenty:desiredy)+height):relative ? desiredy+currenty:desiredy
xabs := abs(currentx-desiredx), yabs := abs(currenty-desiredy)
; 5,30 was
while (firstx < 10) OR (firstx > A_ScreenWidth - 10)						;in SC2 screen scrolls when mouse within 5 pixels of the screen border 
{	
	firstx:=rand(currentx+rand(15,55*(xabs/100)),desiredx+rand(15,55*(xabs/100)))
	if (desiredx < 10) OR (desiredx > A_ScreenWidth - 10)
		Break
}
 
While (firsty < 10) OR (firsty > A_ScreenHeight - 10)
{
	firsty:=rand(currenty+rand(15,550*(yabs/100)),desiredy+rand(15,55*(yabs/100)))
	if (desiredy < 10) OR (desiredy > A_ScreenWidth - 10)
		Break
}

While (secondx < 10) OR (secondx > A_ScreenWidth - 10)	
{	
	secondx:=rand(firstx,desiredx+rand(15,55*(xabs/100)))
	if (desiredx < 10) OR (desiredx > A_ScreenWidth - 10)
		Break
}
	
While (secondy < 10) OR (secondy > A_ScreenHeight - 10)	
{
	secondy:=rand(firsty,desiredy+rand(15,55*(yabs/100)))
	if (desiredy < 10) OR (desiredy > A_ScreenWidth - 10)
		Break
}

blockinput,mousemove
timeend:=(timestart:=a_tickcount)+time
while(a_tickcount<timeend)
{
	 dllcall("SetCursorPos",int,round(currentx*(fromend:=(timeend-a_tickcount)/time)**3+3*firstx*(fromstart:=(a_tickcount-timestart)/time)*fromend**2+3*secondx*fromend*fromstart**2+desiredx*fromstart**3),int,round(currenty*fromend**3+3*firsty*fromstart*fromend**2+3*secondy*fromend*fromstart**2+desiredy*fromstart**3))
	 dllcall("Sleep",UInt,1)
}
dllcall("SetCursorPos",int,desiredx,int,desiredy)
blockinput,mousemoveoff
setbatchlines,% batchlines
}