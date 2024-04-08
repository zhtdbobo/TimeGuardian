; full_command_line := DllCall("GetCommandLine", "str")

; if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
; {
;     try
;     {
;         if A_IsCompiled
;             Run '*RunAs "' A_ScriptFullPath '" /restart'
;         else
;             Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
;     }
;     ExitApp
; }
#SingleInstance force

guititle := "TimeGuardian"
Main := Gui("-SysMenu", guititle)
Main.MenuBar := ""
Main.Add("Text",, "计时器:")

Main.Add("Text",, "  工作时间:")
Main.Add("Text",, "  休息时间:")

Main.Add("Text",, "选项:")
Main.Add("CheckBox", "Checked xm+10 vDefaultCheckBox", "休息时屏蔽键盘和鼠标")

submit := Main.Add("Button", "", "开始")
setting := Main.Add("Button", "X+90", "设置")

; 开始按钮和设置按钮的监听事件
submit.OnEvent("Click", SubmitEvent)
setting.OnEvent("Click", SettingEvent)

Main.Add("Text", "ym+4 xm+80")
Main.Add("Edit", " w50 vWorkTime") 
Main.Add("UpDown", "vWorkTimeUpDown Range1-60", 35)
Main.Add("Edit", "w50 vRestTime")
Main.Add("UpDown", "vRestTimeUpDown Range1-20", 5)

Main.Add("Text", "ym xm+140")
Main.Add("Text",, "(分钟)")
Main.Add("Text",, "(分钟)")

Main.Show()

; 设置焦点到开始上
submit.Focus()
workTime := ""
restTime := ""
Saved := ""
status := 1
drag := 0
time := ""
daojishi := ""
systemTime := ""
systemDate := ""
Count := MonitorGetCount()

dpiWidth := A_ScreenWidth * 96 / A_ScreenDPI
dpiHeight := A_ScreenHeight * 96 / A_ScreenDPI
settingGui := ""
; 配置文件
windowBackgroundColor := "1d766f" ; 窗口背景色
workTextTip := "注意坐姿"
warningColor := "a63a3a"

if not FileExist("TimeGuardian.ini"){
    IniWrite windowBackgroundColor, "TimeGuardian.ini", "Window", "windowBackgroundColor"
    IniWrite workTextTip, "TimeGuardian.ini", "Window", "workTextTip"
    IniWrite warningColor, "TimeGuardian.ini", "Window", "warningColor"
}

getDefaultVariable(){
    global windowBackgroundColor,workTextTip,warningColor
    windowBackgroundColor := IniRead("TimeGuardian.ini", "Window", "windowBackgroundColor")
    workTextTip := IniRead("TimeGuardian.ini", "Window", "workTextTip")
    warningColor := IniRead("TimeGuardian.ini", "Window", "warningColor")
}


SubmitEvent(*)
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
    getDefaultVariable()
    while(true){
        if(status == 1)
            work()
        else
            rest()
    }
}     


SettingEvent(*)
{
    global settingGui
    Main.Hide()
    settingGui := Gui("-SysMenu", "setting")
    settingGui.MenuBar := ""
    Tab := settingGui.Add("Tab3",, ["Window","Text"])
    Tab.UseTab("Window", true)
    settingGui.Add("Text", "w200", "背景色:")
    settingGui.Add("Text", "w200", "工作文字:")
    save := settingGui.Add("Button", "Y+10", "保存")
    cancel := settingGui.Add("Button", "X+10", "取消")

    settingGui.Add("Text", "ym+4 xm+80")
    settingGui.Add("Edit", "w50 vwindowBackgroundColor", windowBackgroundColor) 
    settingGui.Add("Edit", "w100 vworkTextTip", workTextTip) 
    
    settingGui.Show()
    save.OnEvent("Click", SaveEvent)
    cancel.OnEvent("Click", CancelEvent)

}  

SaveEvent(*)
{
    configuration := settingGui.Submit()
    IniWrite configuration.windowBackgroundColor, "TimeGuardian.ini", "Window", "windowBackgroundColor"
    IniWrite configuration.workTextTip, "TimeGuardian.ini", "Window", "workTextTip"
    settingGui.Destroy()
    Main.Show()
    
}  

CancelEvent(*)
{
    settingGui.Destroy()
    Main.Show()
}  


!c::ProcessClose(WinGetPID(guititle))
!b::{
    global time
    if(status == 1)
        time := workTime + 1

    Sleep 1100

}

guiArray := []


work(){
    global status,daojishi,Main,drag
    drag := 1
    tipGui("cffffff s17 w30", "w100 h30 Center yp+12 xp+10", workTextTip)
    daojishi := Main.Add("Text", "w80 h30 Center yp+30 xp+27", Format("{:02}", Round(workTime / 60)) ":" Format("{:02}", 0))

    ; Main.Show("W120 H80 X" A_ScreenWidth * 0.93 " Y" A_ScreenHeight * 0.87)
    Main.Show("W120 H80 X" A_ScreenWidth * 0.954 " Y" A_ScreenHeight * 0.912)

    WinSetStyle "-0xC00000", guititle
    ; 设置圆角显示
    WinSetRegion "0-0 W" 120 / 96 * A_ScreenDPI " H" 80 / 96 * A_ScreenDPI " R30-30", "ahk_pid " WinGetPID(guititle)

    ; BlockInput "Off"
    WinSetTransparent 220, guititle

    guiArray.Push(Main)

    timeRest()
    status := 0
    
}


rest(){
    global status,daojishi,Main,drag,guiArray,systemTime
    drag := 0
    tipGui("cFFFFFF s30 w100", "w" dpiWidth " Center Y+" A_ScreenHeight * 96 / A_ScreenDPI / 4  " h100", "您已工作" Round(workTime / 60) "分钟，请站起来活动一下吧！")
    daojishi := Main.Add("Text", "w" dpiWidth " Center h100", Format("{:02}", Round(restTime / 60)) ":" Format("{:02}", 0))
    
    Main.SetFont("cf15d64 s20")
    ; Main.Add("Edit", "Background1d766f -Border -Theme -VScroll r5 vtodo w" A_ScreenWidth " Center", "")

    Main.Show("X0 Y0 W" dpiWidth " H" dpiHeight)

    ; BlockInput "On"
    WinSetTransparent 230, guititle

    guiArray.Push(Main)

    ; 适配多屏，为每一个屏幕增加绿色的背景
    i := 1
    while i <= Count
    {
        if(i != MonitorGetPrimary()){
            assistdant(i)
        }
        i++
    }
    timeRest()
    status := 1
}


tipGui(fontFormat, textOption, tipText){
    global Main,systemTime
    Main := Gui("AlwaysOnTop -SysMenu -Caption ToolWindow")
    Main.MenuBar := ""
    Main.MarginX := 0
    Main.BackColor := windowBackgroundColor
    if(status == 0){
        Main.SetFont("s60")
        ; MsgBox A_ScreenDPI
        systemTime := Main.Add("Text", "cFFBF40 w" dpiWidth " h80 Center Y+50", FormatTime(, "hh:mm:ss"))
        Main.SetFont("s20")
        systemDate := Main.Add("Text", "cFFBF40 w" dpiWidth " h40 Center ", FormatTime(, "yyyy/M/d dddd tt"))
    }
    Main.SetFont(fontFormat)
    Main.Add("Text", textOption, tipText)
    
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
    guiDestory()
}

xianshi(){
    global time,daojishi,Main,daojishi,systemTime
    if(time == 0){
        SetTimer xianshi, 0
        guiDestory()
    }else{
        time--
        if(status && time <= 15){
            Main.BackColor := warningColor
        }else{
            Main.BackColor := windowBackgroundColor
        }
        daojishi.Text := Format("{:02}", Floor(time / 60)) ":" Format("{:02}", Mod(time, 60))
        if(status == 0){
            systemTime.Text := A_Hour ":" A_Min ":" A_Sec
        }
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


assistdant(index){
    global guiArray
    assistant := Gui("AlwaysOnTop -SysMenu -Caption ToolWindow")
    assistant.MenuBar := ""
    assistant.MarginX := 0
    assistant.BackColor := windowBackgroundColor
    MonitorGet(index, &Left, &Top, &Right, &Bottom)
    assistant.Show("X" Left " Y" Top " W" Right - Left " H" Bottom - Top)

    WinSetTransparent 230, assistant
    guiArray.Push(assistant)
}

guiDestory(){
    for i in guiArray{
        i.Destroy()
    }
}
    
