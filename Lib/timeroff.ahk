timeroff(timers*)
{
	For index, timer in timers ; for current count, current value in timers/array
	{
		settimer, %timer%, off
	}
	return
}

				