full_command_line := DllCall("GetCommandLine", "str")

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

guititle := "TimeGuardian"
Main := Gui("-SysMenu", "TimeGuardian")
Main.MenuBar := ""
Main.Add("Text",, "计时器:")

Main.Add("Text",, "  工作时间:")
Main.Add("Text",, "  休息时间:")

Main.Add("Text",, "选项:")
Main.Add("CheckBox", "Checked xm+10 vDefaultCheckBox", "休息时屏蔽键盘和鼠标")

Main.Add("Button", "Center", "开始").OnEvent("Click", ProcessUserInput)

Main.Add("Text", "ym+4 xm+80")
Main.Add("Edit", " w50 vWorkTime") 
Main.Add("UpDown", "vWorkTimeUpDown Range1-60", 30)
Main.Add("Edit", "w50 vRestTime")
Main.Add("UpDown", "vRestTimeUpDown Range1-20", 5)


Main.Add("Text", "ym xm+140")
Main.Add("Text",, "(分钟)")
Main.Add("Text",, "(分钟)")
Main.Show()

videourl := FileSelect("", , "请选择休息时播放的视频文件")

workTime := ""
restTime := ""
Saved := ""
status := 0
drag := 0
time := ""
daojishi := ""
ProcessUserInput(*)
{
    global Saved 
    global Main
    global status
    global workTime
    global restTime
    

    Saved := Main.Submit()
    workTime := Saved.WorkTimeUpDown * 60
    restTime := Saved.RestTimeUpDown * 60
    Main.Destroy()
    while(true){
        if(status == 1)
            work()
        else
            rest()
    }
}     

!q::{
    ProcessClose(WinGetPID(guititle))
    ProcessClose(WinGetPID("video"))
}
!v::{
    global time
    if(status == 1)
        time := workTime + 1

    Sleep 1100

}



work(){
    global status,daojishi,Main,drag
    drag := 1
    Main := Gui("AlwaysOnTop -SysMenu ToolWindow")
    Main.MenuBar := ""
    Main.MarginX := 0
    Main.SetFont("cffffff s17 w30")
    ; 设置背景色
    Main.BackColor := "066c06"

    Main.Add("Text", "w100 h30 Center yp+15 xp+20", "注意坐姿")
    daojishi := Main.Add("Text", "w80 h30 Center yp+30 xp+27", Format("{:02}", Round(workTime / 60)) ":" Format("{:02}", 0))
    Main.Show("W123 H40 X" A_ScreenWidth * 0.92 " Y" A_ScreenHeight * 0.87)

    WinSetStyle "-0xC00000", guititle
    ; BlockInput "Off"
    WinSetTransparent 230, guititle
    timeRest()
    status := 0
    
}


rest(){
    global status,daojishi,Main,drag
    drag := 0
    
    ; 播放视频
    video := Gui(,"video")
    aaa := video.Add("ActiveX", "X0 Y0 W" A_ScreenWidth " H" A_ScreenHeight, "{6BF52A52-394A-11d3-B153-00C04F79FAA6}").Value
    aaa.URL := videourl
    aaa.settings.autoStart := true
    aaa.settings.setMode( "loop", true ) 
    aaa.uiMode := "none"
    video.Show("W" A_ScreenWidth " H" A_ScreenHeight)

    Main := Gui("AlwaysOnTop")
    Main.SetFont("c484848 s15 w100")
    Main.BackColor := "000000"
    Main.Add("Text", "w" SysGet(78) " Center ym" SysGet(79) / 2 + 100 " h20 section", "您已工作" Round(workTime / 60) "分钟，请站起来活动一下吧！")
    daojishi := Main.Add("Text", "xs" SysGet(78) / 2, Format("{:02}", Round(restTime / 60)) ":" Format("{:02}", 0))
    Main.Show()
    ; 倒计时窗口  去除标题烂  背景颜色透明
    WinSetStyle "-0xC00000", guititle
    WinSetTransColor Main.BackColor, guititle
    ; BlockInput "On"
    ; WinSetTransparent 180, guititle
    timeRest()
    video.Destroy()
    status := 1
}


timeRest(){
    global status,workTime,restTime,time,Main

    if(status == 1){
        time := workTime
    }
    else{
        time := restTime
    }
    SetTimer xianshi, 1000
    while(time){
        Sleep 500
    }
    SetTimer xianshi, 0
    Main.Destroy()
}

xianshi(){
    global time,daojishi,Main,daojishi
    if(time == 0){
        SetTimer xianshi, 0
        Main.Destroy()
    }else{
        time--
        if(status && time == 15){
            Main.BackColor := "ff0000"
        }
        daojishi.Text := Format("{:02}", Floor(time / 60)) ":" Format("{:02}", Mod(time, 60))
    }
    
}

OnMessage 0x201, down
down(wParam, lParam, msg, hwnd)
{ 
    if(drag){
        global guititle
        MouseGetPos &mouseX, &mouseY
        Loop
        {
            WinGetPos &startX, &startY, , , guititle
            state := GetKeyState("LButton")
            if state == 0
                break
            MouseGetPos &mouseNewX, &mouseNewY
            WinMove startX + mouseNewX - mouseX, startY + mouseNewY - mouseY, , ,guititle
        }
    }
}



    
