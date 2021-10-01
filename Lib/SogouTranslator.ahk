; https://fanyi.sogou.com/
; version: 2021.09.19

class SogouTranslator
{
  init(chromePath:="Chrome\chrome.exe", profilePath:="sogou_translate_profile", debugPort:=9889, mode:="sync", timeout:=30)
  {
    ; 0开始初始化 1完成初始化 空值没有初始化
    this.ready := 0
    
    ; 加载多语言错误提示
    this._multiLanguage()
    
    ; 指定的 chrome.exe 不存在则尝试自动寻找
    if (!FileExist(chromePath))
      chromePath := ""
    
    ; 默认将配置文件放到临时目录
    if (profilePath="sogou_translate_profile")
      profilePath := A_Temp "\sogou_translate_profile"
    
    ; 附着现存或打开新的 chrome
    if (Chrome.FindInstances().HasKey(debugPort))
      ChromeInst := {"base": Chrome, "DebugPort": debugPort}
    else
      ; 搜狗 headless 下必须加 user-agent 才能正常返回数据
      ChromeInst := new Chrome(profilePath,, "--headless --user-agent=""Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36""", chromePath, debugPort)
    
    ; 退出时自动释放资源
    this.page := ChromeInst.GetPage()
    OnExit(ObjBindMethod(this, "_exit"))
    
    ; 初始化，也就是先加载一次页面
    this.page.Call("Page.navigate", {"url": "https://fanyi.sogou.com/text?keyword=init&transfrom=en&transto=zh-CHS&model=general"})
    
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
    
    ; 待翻译的文字超过 sogou 支持的单次最大长度
    if (StrLen(str)>5000)
      return, this.multiLanguage.3
    
    ; 构造 url
    this.NonNull(from, "en"), this.NonNull(to, "zh-CHS")
    url := Format("https://fanyi.sogou.com/text?keyword={1}&transfrom={2}&transto={3}&model=general", this.UriEncode(str), from, to)
    
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
      str := this.page.Evaluate("document.querySelector('#trans-result').textContent;").value
    
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
    }
    else
    {
      l.1 := "Please set the chrome.exe path first!"
      l.2 := "The text to be translated is empty!"
      l.3 := "The text to be translated is over the maximum length!"
      l.4 := "The URL is over the maximum length!"
      l.5 := "Timeout!"
    }
  }
  
  _clearResult()
  {
    this.page.Evaluate("document.querySelector('#trans-result').textContent='';")
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