; https://fanyi.youdao.com/
; version: 2023.06.06

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
    OnExit(ObjBindMethod(this, "_exit"))
    
    ; 初始化，也就是先加载一次页面
    this.page := ChromeInst.GetPage()
    this.page.Call("Page.navigate", {"url": "https://fanyi.youdao.com/index.html#/"}, mode="async" ? false : true)
    
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
    
    ; 待翻译的文字超过 youdao 支持的单次最大长度
    if (StrLen(str)>5000)
      return {Error : this.multiLanguage.3}
    
    ; 清空原文
    this._clearTransResult()
    
    ; 选择语言
    if (this._convertLanguageAbbr(from, to).Error)
      return {Error : this.multiLanguage.6}
    
    ; 翻译
    this.page.Call("Input.insertText", {"text": str}, mode="async" ? false : true)
    return this._receive(mode, timeout, "getTransResult")
  }
  
  getInitResult()
  {
    ; 页面是否加载完成
    if (this.page.Evaluate("document.readyState;").value = "complete")
      return "OK"
  }
  
  getTransResult()
  {
    ; 获取翻译结果
    try
      str := this.page.Evaluate("document.querySelector('#js_fanyi_output_resultOutput').innerText;").value
    
    ; 去掉空白符后不为空则返回原文
    if (Trim(str, " `t`r`n`v`f")!="")
    {
      ; youdao 会返回多余的换行
      str := StrReplace(str, "`n`n`n", "`r")
      str := StrReplace(str, "`n`n", "`r")
      return StrReplace(str, "`r", "`n")
    }
  }
  
  free()
  {
    this.page.Call("Browser.close",, false) ; 关闭浏览器(所有页面和标签)
    this.page.Disconnect()                  ; 断开连接
  }
  
  _multiLanguage()
  {
    this.multiLanguage := []
    l := this.multiLanguage
    if (A_Language="0804")
    {
      l.1 := "自己先去源码里把 chrome.exe 路径设置好！"
      l.2 := "待翻译文字为空！"
      l.3 := "待翻译文字超过最大长度（5000）！"
      l.4 := "URL 超过最大长度（8182）！"
      l.5 := "超时！"
      l.6 := "不支持此两种语言间的翻译！"
    }
    else
    {
      l.1 := "Please set the chrome.exe path first!"
      l.2 := "The text to be translated is empty!"
      l.3 := "The text to be translated is over the maximum length(5000)!"
      l.4 := "The URL is over the maximum length(8182)!"
      l.5 := "Timeout!"
      l.6 := "Translation between these two languages is not supported!"
    }
  }
  
  _convertLanguageAbbr(from, to)
  {
    languageSelected := from "-" to
    
    ; 语言发生变化，需要重新选择
    if (languageSelected!=this.languageSelected)
    {
      this.languageSelected := languageSelected
      
      if (from="auto" or to="auto" or from=to)
      {
        this.page.Evaluate("document.querySelector('div.lang-container.lanFrom-container').click();")
        this.page.Evaluate("document.querySelector('div.common-language-container > div > div:nth-child(1)').click();")
      }
      else
      {
        /*
          阿拉伯语    德语            俄语
          法语        韩语            荷兰语
          葡萄牙语    日语            泰语
          西班牙语    英语            意大利语
          越南语      印度尼西亚语    中文
        */
        dict := { ar:1,     de:2,     ru:3
                , fr:4,     ko:5,     nl:6
                , pt:7,     ja:8,     th:9
                , es:10,    en:11,    it:12
                , vi:13,    id:14,    zh:15 }
        
        if (!dict.HasKey(from) or !dict.HasKey(to))
          return {Error : this.multiLanguage.6}
        else
        {
          this.page.Evaluate("document.querySelector('div.lang-container.lanFrom-container').click();")
          this.page.Evaluate(Format("document.querySelector('div.specify-language-container > div > div > div > div:nth-child({})').click();", dict[from]))
          
          this.page.Evaluate("document.querySelector('div.lang-container.lanTo-container').click();")
          this.page.Evaluate(Format("document.querySelector('div.specify-language-container > div > div > div > div:nth-child({})').click();", dict[to]))
        }
      }
    }
  }
  
  _clearTransResult()
  {
    try this.page.Evaluate("document.querySelector('#TextTranslate > div.source > a').click();")
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
}

#Include %A_LineFile%\..\Chrome.ahk