; on Vista and above this will set the process/program volume only
; on xp and below this will change the system volume
SetProgramWaveVolume(pct, device := 1) {
    v := pct*655.35
    DllCall("winmm\waveOutSetVolume", "int", device-1, "uint", v|(v<<16))
}