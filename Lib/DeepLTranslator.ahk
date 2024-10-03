; https://www.deepl.com/translator
; version: 2024.10.03

class DeepLTranslator
{
  init(chromePath:="Chrome\chrome.exe", profilePath:="deepl_translate_profile", debugPort:=9888, mode:="sync", timeout:=30)
  {
    ; 0开始初始化 1完成初始化 空值没有初始化
    this.ready := 0
    
    ; 加载多语言错误提示
    this._multiLanguage()
    
    ; 指定的 chrome.exe 不存在则尝试自动寻找
    if (!FileExist(chromePath))
      chromePath := ""
    
    ; 默认将配置文件放到临时目录
    if (profilePath="deepl_translate_profile")
      profilePath := A_Temp "\deepl_translate_profile"
    
    ; 附着现存或打开新的 chrome
    if (Chrome.FindInstances().HasKey(debugPort))
      ChromeInst := {"base": Chrome, "DebugPort": debugPort}
    else
      ChromeInst := new Chrome(profilePath,, "--headless", chromePath, debugPort)
    
    ; 退出时自动释放资源
    OnExit(ObjBindMethod(this, "_exit"))
    
    ; 初始化，也就是先加载一次页面
    this.page := ChromeInst.GetPage()
    this.page.Call("Page.navigate", {"url": "https://www.deepl.com/translator#en/zh/init"}, mode="async" ? false : true)
    
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
    
    ; 待翻译的文字超过 deepl 支持的单次最大长度
    ; 这里需要注意，实际使用中会因未知原因触发 “xxxx个字符中仅3000个字符已翻译。免费注册以实现一次性翻译多达5000个字符。”
    ; 所以这里限制为3000
    if (StrLen(str)>3000)
      return {Error : this.multiLanguage.3}
    
    ; 清空原文
    this._clearTransResult()
    
    ; 选择语言
    if (this._convertLanguageAbbr(from, to).Error)
      return {Error : this.multiLanguage.6}
    
    ; 翻译
    this.page.Evaluate("document.querySelector('[data-testid=""translator-source-input""]').focus();")
    this.page.Call("Input.insertText", {"text": str}, mode="async" ? false : true)
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
      str := this.page.Evaluate("document.querySelectorAll('d-textarea')[1].innerText;").value
    
    ; 去掉空白符后不为空则返回原文
    if (Trim(str, " `t`r`n`v`f")!="")
    {
      ; deepl 会返回多余的换行
      str := StrReplace(str, "`n`n`n", "`r")
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
      l.3 := "待翻译文字超过最大长度（3000）！"
      l.4 := "URL 超过最大长度（8182）！"
      l.5 := "超时！"
      l.6 := "不支持此两种语言间的翻译！"
    }
    else
    {
      l.1 := "Please set the chrome.exe path first!"
      l.2 := "The text to be translated is empty!"
      l.3 := "The text to be translated is over the maximum length(3000)!"
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
        this.page.Evaluate("document.querySelector('[data-testid=""translator-source-lang-btn""]').click();")
        this.page.Evaluate("document.querySelector('[data-testid=""translator-lang-option-auto""]').click();")
      }
      else
      {
        /*
          检测源语言     荷兰语           土耳其语
          阿拉伯语       捷克语           乌克兰语
          爱沙尼亚语     拉脱维亚语       西班牙语
          保加利亚语     立陶宛语         希腊语
          波兰语         罗马尼亚语       匈牙利语
          丹麦语         葡萄牙语         意大利语
          德语           日语             印尼语
          俄语           瑞典语           英语
          法语           书面挪威语       中文
          芬兰语         斯洛伐克语       
          韩语           斯洛文尼亚语     
        */
        dict_from := {  auto:"auto",     nl:"nl",     tr:"tr"
                      , ar:"ar",         cs:"cs",     uk:"uk"
                      , et:"et",         lv:"lv",     es:"es"
                      , bg:"bg",         lt:"lt",     el:"el"
                      , pl:"pl",         ro:"ro",     hu:"hu"
                      , da:"da",         pt:"pt",     it:"it"
                      , de:"de",         ja:"ja",     id:"id"
                      , ru:"ru",         sv:"sv",     en:"en"
                      , fr:"fr",         nb:"nb",     zh:"zh"
                      , fi:"fi",         sk:"sk"
                      , ko:"ko",         sl:"sl"}
        
        /*
          阿拉伯语       捷克语               土耳其语
          爱沙尼亚语     拉脱维亚语           乌克兰语
          保加利亚语     立陶宛语             西班牙语
          波兰语         罗马尼亚语           希腊语
          丹麦语         葡萄牙语             匈牙利语
          德语           葡萄牙语（巴西）     意大利语
          俄语           日语                 印尼语
          法语           瑞典语               英语（美式）
          芬兰语         书面挪威语           英语（英式）
          韩语           斯洛伐克语           中文（简体）
          荷兰语         斯洛文尼亚语         中文（繁体）
        */
        dict_to := {  ar:"ar",     cs:"cs",         tr:"tr"
                    , et:"et",     lv:"lv",         uk:"uk"
                    , bg:"bg",     lt:"lt",         es:"es"
                    , pl:"pl",     ro:"ro",         el:"el"
                    , da:"da",     pt:"pt-PT",      hu:"hu"
                    , de:"de",     pt2:"pt-BR",     it:"it"
                    , ru:"ru",     ja:"ja",         id:"id"
                    , fr:"fr",     sv:"sv",         en:"en-US"
                    , fi:"fi",     nb:"nb",         en2:"en-GB"
                    , ko:"ko",     sk:"sk",         zh:"zh-Hans"
                    , nl:"nl",     sl:"sl",         zh2:"zh-Hant"}
        
        if (!dict_from.HasKey(from) or !dict_to.HasKey(to))
          return {Error : this.multiLanguage.6}
        else
        {
          this.page.Evaluate("document.querySelector('[data-testid=""translator-source-lang-btn""]').click();")
          this.page.Evaluate(Format("document.querySelector('[data-testid=""translator-lang-option-{}""]').click();"), dict_from[from])
          
          this.page.Evaluate("document.querySelector('[data-testid=""translator-target-lang-btn""]').click();")
          this.page.Evaluate(Format("document.querySelector('[data-testid=""translator-lang-option-{}""]').click();"), dict_to[to])
        }
      }
    }
  }
  
  _clearTransResult()
  {
    try this.page.Evaluate("document.querySelector('[data-testid=""translator-source-clear-button""]').click();")
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