; https://fanyi.youdao.com/
; version: 2021.10.02

class YoudaoTranslator
{
  init(chromePath:="Chrome\chrome.exe", profilePath:="youdao_translate_profile", debugPort:=9891, mode:="sync", timeout:=30)
  {
    ; 0开始初始化 1完成初始化 空值没有初始化
    this.ready := 0
    
    ; 加载多语言错误提示
    this._multiLanguage()
    
    ; 指定的 chrome.exe 不存在则尝试自动寻找
    if (!FileExist(chromePath))
      chromePath := ""
    
    ; 默认将配置文件放到临时目录
    if (profilePath="youdao_translate_profile")
      profilePath := A_Temp "\youdao_translate_profile"
    
    ; 附着现存或打开新的 chrome
    if (Chrome.FindInstances().HasKey(debugPort))
      ChromeInst := {"base": Chrome, "DebugPort": debugPort}
    else
      ChromeInst := new Chrome(profilePath,, "--headless", chromePath, debugPort)
    
    ; 退出时自动释放资源
    this.page := ChromeInst.GetPage()
    OnExit(ObjBindMethod(this, "_exit"))
    
    ; 初始化，也就是先加载一次页面
    this.page.Call("Page.navigate", {"url": "https://fanyi.youdao.com/"})
    
    ; 同步将产生阻塞直到返回结果，异步将快速返回以便用户自行处理结果
    this._receive(mode, timeout, true)
    
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
    
    ; 待翻译的文字超过 youdao 支持的单次最大长度
    if (StrLen(str)>5000)
      return, this.multiLanguage.3
    
    ; 清空原文
    while (this.page.Evaluate("document.querySelector('#inputOriginal').value;").value!="")
    {
      this.page.Evaluate("document.querySelector('#inputDelete').click();")
      Sleep, 500
    }
    
    ; 选择语言
    if (this._convertLanguageAbbr(from, to)=this.multiLanguage.6)
      return, this.multiLanguage.6
    
    ; 翻译
    this.page.Call("Input.insertText", {"text": str})
    return, this._receive(mode, timeout)
  }
  
  getResult()
  {
    ; 获取翻译结果
    try
      str := this.page.Evaluate("document.querySelector('#transTarget').innerText;").value
    
    ; 去掉空白符后不为空则返回原文
    if (Trim(str, " `t`r`n`v`f")!="")
      ; youdao 会返回多余的换行
      return, StrReplace(str, "`n`n", "`n")
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
    languageSelected := from "-" to
    ; 语言发生变化，需要重新选择
    if (languageSelected!=this.languageSelected)
    {
      this.languageSelected := languageSelected
      
      if (from="auto")
        this.page.Evaluate("document.querySelector('#languageSelect > li.default > a').click();")
      else
      {
        ; 语言排列顺序与网页显示一致
        langSel := {"zh-en":2 , "en-zh":3
                  , "zh-ja":4 , "ja-zh":5
                  , "zh-ko":6 , "ko-zh":7
                  , "zh-fr":8 , "fr-zh":9
                  , "zh-de":10, "de-zh":11
                  , "zh-ru":12, "ru-zh":13
                  , "zh-es":14, "es-zh":15
                  , "zh-pt":16, "pt-zh":17
                  , "zh-it":18, "it-zh":19
                  , "zh-vi":20, "vi-zh":21
                  , "zh-id":22, "id-zh":23
                  , "zh-ar":24, "ar-zh":25
                  , "zh-nl":26, "nl-zh":27
                  , "zh-th":28, "th-zh":29}
        
        if (!langSel.HasKey(languageSelected))
          return, this.multiLanguage.6
        else
          this.page.Evaluate(Format("document.querySelector('#languageSelect > li:nth-child({1}) > a').click();"
                           , langSel[languageSelected]))
      }
    }
  }
  
  _clearResult()
  {
    this.page.Evaluate("document.querySelector('#inputDelete').click();")
  }
  
  _receive(mode, timeout, isInit:=false)
  {
    ; 异步模式直接返回
    if (mode="async")
      return
    
    ; 初始化过程的检验
    if (isInit)
    {
      startTime := A_TickCount
      loop
      {
        ; 页面是否加载完成
        if (this.Evaluate("document.readyState;").value != "complete")
          return
        else
          Sleep, 500
        
        if ((A_TickCount-startTime)/1000 >= timeout)
          return, this.multiLanguage.5
      }
    }
    else
    {
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
  }
  
  _exit()
  {
    if (this.page.connected)
      deepl.free()
  }
  
  #Include %A_LineFile%\..\NonNull.ahk
}

#Include %A_LineFile%\..\Chrome.ahk