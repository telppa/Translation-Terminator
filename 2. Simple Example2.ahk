; Initialization allows you to specify the chrome.exe path and also speeds up the first translation.
; BaiduTranslator.init()                    --- Automatically find the path of the installed chrome.exe
; BaiduTranslator.init("x:\xxx\chrome.exe") --- Use specified path of the chrome.exe
BaiduTranslator.init()

; Translate text from Japanese to English.
MsgBox,% BaiduTranslator.translate("今日の天気はとても良いです", "ja", "en")
; Supports automatic detection language by using "auto".
MsgBox,% BaiduTranslator.translate("今日の天気はとても良いです", "auto", "en")
; Omitting the parameters 2 and 3 means translate text from English to Chinese.
MsgBox,% BaiduTranslator.translate("Hello my love")

; It will automatically release resources on exit.
; But you can also release resources manually.
; Please note that after releasing resources, you need to re-initialize it before using again.
BaiduTranslator.free()

ExitApp

#Include <BaiduTranslator>



/*
-------------------------------------------------------------------------
The other libraries are used in a very similar way to BaiduTranslator.

For example:

  SogouTranslator.init()
  SogouTranslator.translate("text")
  SogouTranslator.free()
  #Include <SogouTranslator>

  DeepLTranslator.init()
  DeepLTranslator.translate("text")
  DeepLTranslator.free()
  #Include <DeepLTranslator>

*/