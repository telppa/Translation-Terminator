/*
Feature:
  支持 /hide 参数启动
  支持外部呼叫（本翻译器运行时，在自己程序中使用以下代码即可呼叫它翻译）
  注意：当本翻译器使用管理员权限启动后，呼叫聚合翻译器() 必须同样使用管理员权限
    呼叫聚合翻译器("我爱苹果")
    呼叫聚合翻译器(Text)
    {
      Prev_DetectHiddenWindows := A_DetectHiddenWindows
      Prev_TitleMatchMode := A_TitleMatchMode
      DetectHiddenWindows, On
      SetTitleMatchMode, 1
      ControlSetText, Edit2, %Text%, 聚合翻译器 ahk_class AutoHotkeyGUI
      DetectHiddenWindows, %Prev_DetectHiddenWindows%
      SetTitleMatchMode, %Prev_TitleMatchMode%
    }
  
Todo:
  设置最佳显示位置 鼠标位置+窗口宽>屏幕宽 则用屏幕宽 避免超出屏幕
  --headless 下不能使用 --user-data-dir=
  --headless 下临时文件乱跑
  历史记忆
  
已知问题:
  当按住主窗口标题栏并拖动它超出屏幕最顶端，然后松手。
  此时主窗口会自动回落到屏幕范围内，子窗口1号会跟随移动，但子窗口2号不会跟随移动。
*/

#SingleInstance Ignore
#NoEnv
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

Init:
  ; 不要把 chromePath 造为超级全局变量，会污染到库中的同名变量
  chromePath := "Chrome\chrome.exe"
  
  global Translators, Original, OuterOriginal, btnTranslate
  
  Lang := MultiLanguage()
  
  Translators := {"DeepL"  : {initState:"" ,initTime:"" ,resultState:"" ,resultTime:"", name:Lang.81}
                , "Sogou"  : {initState:"" ,initTime:"" ,resultState:"" ,resultTime:"", name:Lang.82}
                , "Baidu"  : {initState:"" ,initTime:"" ,resultState:"" ,resultTime:"", name:Lang.83}
                , "Youdao" : {initState:"" ,initTime:"" ,resultState:"" ,resultTime:"", name:Lang.84}}
  
  gosub, CreatMain
  gosub, CreatSub
  
  OnMessage(0x3, "WM_MOVE")
  OnMessage(536, "OnPBMsg")  ; WM_POWERBROADCAST 从睡眠中醒来则重启
  
  ShowOrHideSub("", "", "", "")
return

CreatMain:
  if (A_Args.1="/hide")
    isHide := "Hide"
  
  Menu, Tray, NoStandard
  Menu, Tray, Icon, icon.png
  Menu, Tray, Add, % Lang.2, MenuHandler
  Menu, Tray, Add, % Lang.3, MenuHandler
  Menu, Tray, Add, % Lang.4, MenuHandler
  Menu, Tray, Add, % Lang.5, MenuHandler
  Menu, Tray, Default, % Lang.2
  
  Gui, +HwndhMain
  Gui, Font, s10, 微软雅黑
  
  Gui, Add, Edit, x16 y16 w450 h150 vOriginal +Disabled
  Gui, Add, Edit, x0 y0 w0 h0 vOuterOriginal gOuterCallHandler  ; 隐藏控件，用于接收外部调用
  Gui, Add, Edit, x0 y0 w0 h0 vMergeOriginal                    ; 隐藏控件，用于记录合并段落前的原文
  
  Gui, Add, CheckBox, x16 y184 w60 h23 vDeepL gShowOrHideSub Checked, % Lang.81
  Gui, Add, CheckBox, x88 y184 w60 h23 vSogou gShowOrHideSub, % Lang.82
  Gui, Add, CheckBox, x160 y184 w60 h23 vBaidu gShowOrHideSub, % Lang.83
  Gui, Add, CheckBox, x232 y184 w60 h23 vYoudao gShowOrHideSub Checked, % Lang.84
  
  Gui, Add, Text, x16 y224 w60 h23 +0x200, % Lang.7
  Gui, Add, ComboBox, x80 y224 w80 vFrom, % Lang.31
  Gui, Add, Text, x180 y224 w60 h23 +0x200, % Lang.8
  Gui, Add, ComboBox, x244 y224 w80 vTo, % Lang.32
  
  Gui, Add, CheckBox, x365 y224 w140 h23 vMerge Checked, % Lang.9
  
  Gui, Add, Button, x16 y264 w450 h40 vbtnTranslate gTranslate +Disabled, % Lang.6
  Gui, Show, %isHide% w482 h320, % Lang.1 " v1.4"
return

CreatSub:
  for k, v in Translators
  {
    Gui, %k%:+Owner%hMain% +Hwndh%k% +LabelSub  ; 所有子窗口的事件标签都以 Sub 开头，例如 SubClose
    Gui, %k%:Font, s12, 微软雅黑
    Gui, %k%:Add, Edit, x0 y0 w482 h150 v%k%Edit +Disabled
    Gui, %k%:Show, Hide w482 h150, % v.name
  }
return

MultiLanguage()
{
  ret := []
  
  if (A_Language="0804")
  {
    ret.1  := "聚合翻译器"
    ret.2  := "显示"
    ret.3  := "隐藏"
    ret.4  := "重启"
    ret.5  := "退出"
    ret.6  := "翻译"
    ret.7  := "源语言："
    ret.8  := "目标语言："
    ret.9  := "自动合并段落"
    ret.21 := "正在初始化..."
    ret.22 := "初始化失败，请重试。"
    ret.23 := "初始化成功。"
    ret.24 := "翻译中..."
    ret.25 := "错误 ： "
    ret.26 := "翻译失败，请重试。"
    ret.31 := "自动检测||中文|英语|日语|韩语|德语|法语|俄语|阿拉伯语|爱沙尼亚语|保加利亚语|波兰语|丹麦语|芬兰语|荷兰语|捷克语|拉脱维亚语|立陶宛语|罗马尼亚语|葡萄牙语|瑞典语|斯洛伐克语|斯洛文尼亚语|泰语|土耳其语|乌克兰语|西班牙语|希腊语|匈牙利语|意大利语|印尼语|越南语"
    ret.32 := "中文||英语|日语|韩语|德语|法语|俄语|阿拉伯语|爱沙尼亚语|保加利亚语|波兰语|丹麦语|芬兰语|荷兰语|捷克语|拉脱维亚语|立陶宛语|罗马尼亚语|葡萄牙语|瑞典语|斯洛伐克语|斯洛文尼亚语|泰语|土耳其语|乌克兰语|西班牙语|希腊语|匈牙利语|意大利语|印尼语|越南语"
    ret.81 := "DeepL"
    ret.82 := "搜狗"
    ret.83 := "百度"
    ret.84 := "有道"
  }
  else
  {
    ret.1  := "Aggregate Translator"
    ret.2  := "Show"
    ret.3  := "Hide"
    ret.4  := "Reload"
    ret.5  := "Exit"
    ret.6  := "Translate"
    ret.7  := "From:"
    ret.8  := "To:"
    ret.9  := "Merge Paragraph"
    ret.21 := "Initializing..."
    ret.22 := "Initialization failed, please try again."
    ret.23 := "Initialization succeeded."
    ret.24 := "Translating..."
    ret.25 := "ERROR : "
    ret.26 := "Translation failed, please try again."
    ret.31 := "auto||zh|en|ja|ko|de|fr|ru"
    ret.32 := "zh||en|ja|ko|de|fr|ru"
    ret.81 := "DeepL"
    ret.82 := "Sogou"
    ret.83 := "Baidu"
    ret.84 := "Youdao"
  }
  
  return, ret
}

CalculatePos(Margin)
{
  global hMain
  static SubHeight
  
  Prev_DetectHiddenWindows := A_DetectHiddenWindows
  DetectHiddenWindows, On
  
  ; 获取主窗口坐标+宽高
  WinGetPos, X, Y, W, H, ahk_id %hMain%
  ; 获取子窗口高度
  if (!SubHeight)
    for k, v in Translators
    {
      WinGetPos, , , , SubHeight, % "ahk_id " h%k%
      if (SubHeight)
        break
    }
  
  DetectHiddenWindows, %Prev_DetectHiddenWindows%
  
  ; 计算主窗口+子窗口坐标
  H2          := SubHeight
  Y2          := (H2*3+Margin*2-(H+Margin+H2))//2
  return, Pos := [[X,          Y+H+Margin]
                , [X+W+Margin, Y-Y2]
                , [X+W+Margin, Y-Y2+H2+Margin]
                , [X+W+Margin, Y-Y2+2*(H2+Margin)]]
}

; 不要在此函数中使用 Critical ，会导致启动 chrome 变得很卡 
ShowOrHideSub(ControlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
  global hMain, Lang, chromePath
  
  WinGetTitle, isMainShow, ahk_id %hMain%
  isMainHide := isMainShow ? "" : "Hide"
  
  Pos := CalculatePos(Margin:=10)
  
  for k, v in Translators
  {
    GuiControlGet, CheckBoxState, , %k%
    if (CheckBoxState)
    {
      ; 子窗口按预设位置显示出来
      n++
      
      ; 避免子窗口移动到负坐标
      if (Pos[n, 1]>0 and Pos[n, 2]>0)
      {
        WinGetPos, x, , w, h, % "ahk_id " h%k%
        if (x!="")
          ; 子窗口存在则移动位置
          DllCall("MoveWindow", "Ptr", h%k%, "Int", Pos[n, 1], "Int", Pos[n, 2], "Int", w, "Int", h, "Int", 0)
        else
          ; 子窗口不存在则显示
          Gui, %k%:Show, % Format("{} x{} y{}", isMainHide, Pos[n, 1], Pos[n, 2])
      }
      
      switch, v.initState
      {
        case 0,1 : continue
        case 2   : v.initState:=1
        case ""  :
             v.initState:=0
             GuiControl, %k%:, %k%Edit, % Lang.21
             Translator := k "Translator"
             %Translator%.init(chromePath,,,"async")
      }
    }
    else
    {
      ; 隐藏起来
      Gui, %k%:Hide
      
      switch, v.initState
      {
        case "",0,2 : continue
        case 1      : v.initState:=2
      }
    }
  }
  
  ; 重复 SetTimer 只会更新原计时器的时间参数，不会中断正在运行的原计时器，也不会重复设置多个计时器
  SetTimer, CheckInit, 500
}

CheckInit()
{
  global Lang
  
  initCount1:=0, initCount0:=0
  for k, v in Translators
  {
    ; 统计可用引擎数量
    if (v.initState=1)
      initCount1++
    ; 统计正在初始化引擎数量
    if (v.initState=0)
      initCount0++
  }
  
  ; 可用引擎数量大于等于1，则启用原文框与翻译按钮
  if (initCount1>=1)
  {
    GuiControl, Enable, Original
    GuiControl, Enable, btnTranslate
  }
  ; 没有可用引擎，则禁用原文框与翻译按钮
  else
  {
    GuiControl, Disable, Original
    GuiControl, Disable, btnTranslate
  }
  
  ; 没有正在初始化的引擎则返回
  if (initCount0=0)
  {
    SetTimer, CheckInit, Off
    return
  }
  
  for k, v in Translators
  {
    ; 正在初始化
    if (v.initState=0)
    {
      v.initTime := NonNull_Ret(v.initTime, A_TickCount)
      
      ; 初始化超时
      if (A_TickCount - v.initTime > 30*1000)
      {
        v.initState:="", v.initTime:=""
        GuiControl, %k%:, %k%Edit, % Lang.22
        continue
      }
      
      ; 初始化成功
      Translator := k "Translator"
      if (%Translator%.getInitResult())
      {
        v.initState:=1, v.initTime:=""
        GuiControl, %k%:Enable, %k%Edit
        GuiControl, %k%:, %k%Edit, % Lang.23
      }
    }
  }
}

Translate(ControlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
  global Lang, From, To
  
  Gui, Submit, NoHide
  
  GuiControlGet, CheckBoxState, , Merge
  if (CheckBoxState)
  {
    for k, v in Paragraph.merge(Original)
      OriginalMerged.=v "`r`n`r`n"
    
    Original := RTrim(OriginalMerged, "`r`n")
    GuiControl, , Original, %Original%
  }
  
  for k, v in Translators
  {
    if (v.initState=1)
    {
      GuiControl, %k%:, %k%Edit, % Lang.24
      
      dict := { 自动检测:"auto", 阿拉伯语:"ar",   爱沙尼亚语:"et"
              , 保加利亚语:"bg", 波兰语:"pl",     丹麦语:"da"
              , 德语:"de",       俄语:"ru",       法语:"fr"
              , 芬兰语:"fi",     韩语:"ko",       荷兰语:"nl"
              , 捷克语:"cs",     拉脱维亚语:"lv", 立陶宛语:"lt"
              , 罗马尼亚语:"ro", 葡萄牙语:"pt",   日语:"ja"
              , 瑞典语:"sv",     斯洛伐克语:"sk", 斯洛文尼亚语:"sl"
              , 泰语:"th",       土耳其语:"tr",   乌克兰语:"uk"
              , 西班牙语:"es",   希腊语:"el",     匈牙利语:"hu"
              , 意大利语:"it",   印尼语:"id",     英语:"en"
              , 越南语:"vi",     中文:"zh"}
      From := dict.HasKey(From) ? dict[From] : From
      To   := dict.HasKey(To)   ? dict[To]   : To
      
      Translator := k "Translator"
      ret := %Translator%.translate(Original, From, To, "async")
      
      if (ret.Error)
      {
        GuiControl, %k%:, %k%Edit, % Lang.25 ret.Error
        continue
      }
      else
      {
        NeedToCheckTrans := 1
        v.resultState := 0
      }
    }
  }
  
  if (NeedToCheckTrans)
    SetTimer, CheckTrans, 500
}

CheckTrans()
{
  global Lang
  
  resultCount0 := 0
  for k, v in Translators
    if (v.resultState=0)
      resultCount0++
  
  if (resultCount0=0)
  {
    SetTimer, CheckTrans, Off
    return
  }
  
  for k, v in Translators
  {
    if (v.resultState=0)
    {
      v.resultTime := NonNull_Ret(v.resultTime, A_TickCount)
      
      ; 翻译超时
      if (A_TickCount - v.resultTime > 30*1000)
      {
        v.resultState:="", v.resultTime:=""
        GuiControl, %k%:, %k%Edit, % Lang.26
        continue
      }
      
      Translator := k "Translator"
      ret := %Translator%.getTransResult()
      if (ret)
      {
        v.resultState:="", v.resultTime:=""
        GuiControl, %k%:, %k%Edit, % ret
      }
    }
  }
}

; 这是一个隐藏控件，用于接收外部对翻译器的调用
OuterCallHandler(ControlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
  ShowAll()
  
  Gui, Submit, NoHide
  if (Trim(OuterOriginal, " `t`r`n`v`f")!="")
  {
    GuiControl, , Original, %OuterOriginal%
    GuiControlGet, OutputVar, Enabled, btnTranslate
    if (OutputVar)
      Translate("", "", "", "")
  }
}

MenuHandler:
  if (A_ThisMenuItem=Lang.2)  ; 托盘按钮 - 显示
    ShowAll()
  
  if (A_ThisMenuItem=Lang.3)  ; 托盘按钮 - 隐藏
    HideAll()
  
  if (A_ThisMenuItem=Lang.4)  ; 托盘按钮 - 重启
    Reload
  
  if (A_ThisMenuItem=Lang.5)  ; 托盘按钮 - 退出
    ExitApp
return

; 关闭主窗口时隐藏
GuiEscape:
GuiClose:
  HideAll()
return

; 屏蔽子窗口关闭。这样就不用处理多选框的反向勾选问题了
SubClose:
return

ShowAll()
{
  for k, v in Translators
  {
    GuiControlGet, CheckBoxState, , %k%
    if (CheckBoxState)
      Gui, %k%:Show
  }
  Gui, Show  ; 最后显示主窗口以使主窗口获得焦点
}

HideAll()
{
  for k, v in Translators
    Gui, %k%:Hide
  Gui, Hide
}

WM_MOVE()
{
  SetTimer, MoveSub, -500
  return
  
  MoveSub:
    ShowOrHideSub("", "", "", "")
  return
}

OnPBMsg(wParam, lParam, msg, hwnd)
{
  switch, wParam
  {
    ; PBT_APMRESUMECRITICAL PBT_APMRESUMESUSPEND PBT_APMRESUMEAUTOMATIC
    case 6,7,18:
      SetTimer, Reload, -1000
  }

  ; Must return True after message is processed
  return, true
  
  Reload:
    Run "%A_AhkPath%" /restart "%A_ScriptFullPath%" /hide
  return
}

#Include <NonNull>
#Include <DeepLTranslator>
#Include <SogouTranslator>
#Include <BaiduTranslator>
#Include <YoudaoTranslator>
#Include <Paragraph>
