; https://fanyi.baidu.com/
; version: 2021.10.02

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
    this.page := ChromeInst.GetPage()
    OnExit(ObjBindMethod(this, "_exit"))
    
    ; 初始化，也就是先加载一次页面
    this.page.Call("Page.navigate", {"url": "https://fanyi.baidu.com/#en/zh/init"})
    
    ; 同步将产生阻塞直到返回结果，异步将快速返回以便用户自行处理结果
    this._receive(mode, timeout)
    
    ; 完成初始化
    this.ready := 1
  }
  
  translate(str, from:="", to:="", mode:="sync", timeout:=30)
  {
    ; 没有初始化则初始化一遍
    if (this.ready="")
      this.init()
    
    ; 已经开始初始化则等待其完成
    while (this.ready=0)
      Sleep, 500
    
    ; 待翻译的文字为空
    if (Trim(str, " `t`r`n`v`f")="")
      return, this.multiLanguage.2
    
    ; 待翻译的文字超过 baidu 支持的单次最大长度
    if (StrLen(str)>5000)
      return, this.multiLanguage.3
    
    ; 清空上次翻译结果，避免获取到上次的结果
    this._clearResult()
    
    ; 构造 url
    l := _convertLanguageAbbr(from, to)
    url := Format("https://fanyi.baidu.com/#{1}/{2}/{3}", l.from, l.to, this.UriEncode(str))
    
    ; url 超过最大长度
    if (StrLen(url)>8182)
      return, this.multiLanguage.4
    
    ; 翻译
    this.page.Call("Page.navigate", {"url": url})
    return, this._receive(mode, timeout)
  }
  
  getResult()
  {
    ; 获取翻译结果
    try
      str := this.page.Evaluate("document.querySelector('#main-outer > div > div > div.translate-wrap > div.translateio > div.translate-main.clearfix > div.trans-right > div > div > div.output-bd').innerText;").value
    
    ; 去掉空白符后不为空则返回原文
    if (Trim(str, " `t`r`n`v`f")!="")
      return, str
  }
  
  free()
  {
    this.page.Call("Browser.close")	; 关闭浏览器(所有页面和标签)
    this.page.Disconnect()					; 断开连接
  }
  
  _multiLanguage()
  {
    this.multiLanguage := []
    l := this.multiLanguage
    if (A_Language="0804")
    {
      l.1 := "自己先去源码里把 chrome.exe 路径设置好！"
      l.2 := "待翻译文字为空！"
      l.3 := "待翻译文字超过最大长度！"
      l.4 := "URL 超过最大长度！"
      l.5 := "超时！"
      l.6 := "不支持此两种语言间的翻译！"
    }
    else
    {
      l.1 := "Please set the chrome.exe path first!"
      l.2 := "The text to be translated is empty!"
      l.3 := "The text to be translated is over the maximum length!"
      l.4 := "The URL is over the maximum length!"
      l.5 := "Timeout!"
      l.6 := "Translation between these two languages is not supported!"
    }
  }
  
  _convertLanguageAbbr(from, to)
  {
    this.NonNull(from, "en"), this.NonNull(to, "zh")
    ; 除 ro 被罗姆语占用外，其它均是无冲突转换
    dict     := {et:"est", bg:"bul", da:"dan", fr:"fra", fi:"fin"
               , ko:"kor", lv:"lav", lt:"lit", ro:"rom", ja:"jp"
               , sv:"swe", sl:"slo", es:"spa"}
    ret      := {}
    ret.from := dict.HasKey(from) ? dict[from] : from
    ret.to   := dict.HasKey(to)   ? dict[to]   : to
    return, ret
  }
  
  _clearResult()
  {
    this.page.Evaluate("document.querySelector('#main-outer > div > div > div.translate-wrap > div.translateio > div.translate-main.clearfix > div.trans-right > div > div > div.output-bd').innerText='';")
  }
  
  _receive(mode, timeout)
  {
    ; 异步模式直接返回
    if (mode="async")
      return
    
    ; 同步模式将在这里阻塞直到取得结果或超时
    startTime := A_TickCount
    loop
    {
      ret := this.getResult()
      if (ret!="")
        return, ret
      else
        Sleep, 500
      
      if ((A_TickCount-startTime)/1000 >= timeout)
        return, this.multiLanguage.5
    }
  }
  
  _exit()
  {
    if (this.page.connected)
      deepl.free()
  }
  
  #Include %A_LineFile%\..\NonNull.ahk
  #Include %A_LineFile%\..\UriEncode.ahk
}

#Include %A_LineFile%\..\Chrome.ahk