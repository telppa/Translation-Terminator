﻿; https://fanyi.baidu.com/
; version: 2024.10.03

class BaiduTranslator
{
  init(chromePath:="Chrome\chrome.exe", profilePath:="baidu_translate_profile", debugPort:=9890, mode:="sync", timeout:=30)
  {
    ; 0开始初始化 1完成初始化 空值没有初始化
    this.ready := 0
    
    ; 加载多语言错误提示
    this._multiLanguage()
    
    ; 指定的 chrome.exe 不存在则尝试自动寻找
    if (!FileExist(chromePath))
      chromePath := ""
    
    ; 默认将配置文件放到临时目录
    if (profilePath="baidu_translate_profile")
      profilePath := A_Temp "\baidu_translate_profile"
    
    ; 附着现存或打开新的 chrome
    if (Chrome.FindInstances().HasKey(debugPort))
      ChromeInst := {"base": Chrome, "DebugPort": debugPort}
    else
      ChromeInst := new Chrome(profilePath,, "--headless", chromePath, debugPort)
    
    ; 退出时自动释放资源
    OnExit(ObjBindMethod(this, "_exit"))
    
    ; 初始化，也就是先加载一次页面
    this.page := ChromeInst.GetPage()
    this.page.Call("Page.navigate", {"url": "https://fanyi.baidu.com/mtpe-individual/multimodal?query=init&lang=en2zh"}, mode="async" ? false : true)
    
    ; 同步将产生阻塞直到返回结果，异步将快速返回以便用户自行处理结果
    this._receive(mode, timeout, "getInitResult")
    
    ; 完成初始化
    this.ready := 1
  }
  
  translate(str, from:="auto", to:="zh", mode:="sync", timeout:=30)
  {
    ; 没有初始化则初始化一遍
    if (this.ready="")
      this.init()
    
    ; 已经开始初始化则等待其完成
    while (this.ready=0)
      Sleep 500
    
    ; 待翻译的文字为空
    if (Trim(str, " `t`r`n`v`f")="")
      return {Error : this.multiLanguage.2}
    
    ; 将换行符统一为 `r`n
    ; 这样才能让换行数量在翻译前后保持一致
    str := StrReplace(str, "`r`n", "`n")
    str := StrReplace(str, "`r", "`n")
    str := StrReplace(str, "`n", "`r`n")
    
    ; 待翻译的文字超过 baidu 支持的单次最大长度
    if (StrLen(str)>1000)
      return {Error : this.multiLanguage.3}
    
    ; 清空上次翻译结果，避免获取到上次的结果
    this._clearTransResult()
    
    ; 构造 url
    l := this._convertLanguageAbbr(from, to)
    url := Format("https://fanyi.baidu.com/mtpe-individual/multimodal?query={}&lang={}2{}", this.UriEncode(str), l.from, l.to)
    
    ; url 超过最大长度
    if (StrLen(url)>8182)
      return {Error : this.multiLanguage.4}
    
    ; 翻译
    this.page.Call("Page.navigate", {"url": url}, mode="async" ? false : true)
    return this._receive(mode, timeout, "getTransResult")
  }
  
  getInitResult()
  {
    return this.getTransResult()
  }
  
  getTransResult()
  {
    ; 获取翻译结果
    try
      str := this.page.Evaluate("document.querySelector('#trans-selection').innerText;").value
    
    ; 去掉空白符后不为空则返回原文
    if (Trim(str, " `t`r`n`v`f")!="")
    {
      ; baidu 会返回多余的换行
      str := StrReplace(str, "`n`n", "`r")
      return StrReplace(str, "`r", "`n")
    }
  }
  
  free()
  {
    try ret := this.page.Call("Browser.getVersion",,, 1) ; 确保 ws 连接正常
    
    if (ret)
      this.page.Call("Browser.close") ; 关闭浏览器(所有页面和标签)
  }
  
  _multiLanguage()
  {
    this.multiLanguage := []
    l := this.multiLanguage
    if (A_Language="0804")
    {
      l.1 := "自己先去源码里把 chrome.exe 路径设置好！"
      l.2 := "待翻译文字为空！"
      l.3 := "待翻译文字超过最大长度（1000）！"
      l.4 := "URL 超过最大长度（8182）！"
      l.5 := "超时！"
      l.6 := "不支持此两种语言间的翻译！"
    }
    else
    {
      l.1 := "Please set the chrome.exe path first!"
      l.2 := "The text to be translated is empty!"
      l.3 := "The text to be translated is over the maximum length(1000)!"
      l.4 := "The URL is over the maximum length(8182)!"
      l.5 := "Timeout!"
      l.6 := "Translation between these two languages is not supported!"
    }
  }
  
  _convertLanguageAbbr(from, to)
  {
    ; 由于 baidu 支持的语言实在太多，所以不进行语种是否支持的判断
    ; 除 ro 被罗姆语占用外，其它均是无冲突转换
    dict     := { ar:"ara", et:"est", bg:"bul", pl:"pl",  da:"dan"
                , de:"de",  ru:"ru",  fr:"fra", fi:"fin", ko:"kor"
                , nl:"nl",  cs:"cs",  lv:"lav", lt:"lit", ro:"rom"
                , pt:"pt",  ja:"jp",  sv:"swe", nb:"nob", sk:"sk"
                , sl:"slo", th:"th",  tr:"tr",  uk:"ukr", es:"spa"
                , el:"el",  hu:"hu",  it:"it",  id:"id",  en:"en"
                , vi:"vie", zh:"zh"}
    ret      := {}
    ret.from := dict.HasKey(from) ? dict[from] : from
    ret.to   := dict.HasKey(to)   ? dict[to]   : to
    return ret
  }
  
  _clearTransResult()
  {
    try this.page.Evaluate("document.querySelector('#editor-text > div > div > span').click();")
  }
  
  _receive(mode, timeout, result)
  {
    ; 异步模式直接返回
    if (mode="async")
      return
    
    ; 同步模式将在这里阻塞直到取得结果或超时
    startTime := A_TickCount
    loop
    {
      ret := result="getInitResult" ? this.getInitResult() : this.getTransResult()
      if (ret!="")
        return ret
      else
        Sleep 500
      
      if ((A_TickCount-startTime)/1000 >= timeout)
        return {Error : this.multiLanguage.5}
    }
  }
  
  _exit()
  {
    if (this.page.connected)
      this.free()
  }
  
  #IncludeAgain %A_LineFile%\..\UriEncode.ahk
}

#Include %A_LineFile%\..\Chrome.ahk