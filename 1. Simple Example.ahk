; Initialization, which is required.
BaiduTranslator.init()

; Translate text from Japanese to English.
MsgBox,% BaiduTranslator.translate("今日の天気はとても良いです", "ja", "en")
; BaiduTranslator and SogouTranslator supports automatic detection language by using "auto", but DeepLTranslator does not.
MsgBox,% BaiduTranslator.translate("今日の天気はとても良いです", "auto", "en")
; Omitting the parameters 2 and 3 means translate text from English to Chinese.
MsgBox,% BaiduTranslator.translate("Hello my love")

; Release resources, which is required.
BaiduTranslator.free()
ExitApp

#Include <BaiduTranslator>



/*
-------------------------------------------------------------------------
The other two libraries are used in a very similar way to SogouTranslator.

For example:

  SogouTranslator.init()
  SogouTranslator.translate("text")
  SogouTranslator.free()
  #Include <SogouTranslator>

  DeepLTranslator.init()
  DeepLTranslator.translate("text")
  DeepLTranslator.free()
  #Include <DeepLTranslator>

-------------------------------------------------------------------------
The difference between them is very subtle.

For example:

  In SogouTranslator, "zh-CHS" means Chinese. However, in DeepLTranslator, "zh" means Chinese.

  SogouTranslator and BaiduTranslator supports "auto", but DeepLTranslator does not.

*/