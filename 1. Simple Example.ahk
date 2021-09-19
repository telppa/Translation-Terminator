; Initialization, which is required.
SogouTranslator.init()

; Translate text from Japanese to English.
MsgBox,% SogouTranslator.translate("今日の天気はとても良いです", "ja", "en")
; SogouTranslator and BaiduTranslator supports automatic detection language by using "auto", but DeepLTranslator does not.
MsgBox,% SogouTranslator.translate("今日の天気はとても良いです", "auto", "en")
; Omitting the parameters 2 and 3 means translate text from English to Chinese.
MsgBox,% SogouTranslator.translate("Hello my love")

; Release resources, which is required.
SogouTranslator.free()
ExitApp

#Include <SogouTranslator>



/*
-------------------------------------------------------------------------
The other two libraries are used in a very similar way to SogouTranslator.

For example:

  DeepLTranslator.init()
  DeepLTranslator.translate("text")
  DeepLTranslator.free()
  #Include <DeepLTranslator>

  BaiduTranslator.init()
  BaiduTranslator.translate("text")
  BaiduTranslator.free()
  #Include <BaiduTranslator>

-------------------------------------------------------------------------
The difference between them is very subtle.

For example:

  In SogouTranslator, "zh-CHS" means Chinese. However, in DeepLTranslator, "zh" means Chinese.

  SogouTranslator and BaiduTranslator supports "auto", but DeepLTranslator does not.

*/