; In my country, the connection to deepl is very unstable, it usually takes 5-30 seconds to get result.
; This means that your code will be stuck for 5-30 seconds at the same time (because it is waiting for the result).
; Using asynchronous mode, you can avoid this situation.

; If you don't use asynchronous mode, the program will get stuck on the next line for 5-30 seconds before it can run the code that follows.
DeepLTranslator.init(,,,"async")
; Get initialization result.
loop
{
  ; Because asynchronous mode is used, you can do whatever you want first, and then check the result.
  ; Here we will display some information dynamically.
  ellipsis.="."
  ; By the way, there is a library called BTT, which is as easy to use as ToolTip but more powerful.
  ; https://github.com/telppa/BeautifulToolTip
  ToolTip, Initializing%ellipsis%
  
  if (DeepLTranslator.getInitResult())
  {
    MsgBox, Initialization succeeded
    break
  }
  else
    Sleep, 1000
}

ret := DeepLTranslator.translate("Hello my love",,,"async")
if (ret.Error)
{
  MsgBox, % ret.Error
  ExitApp
}

; Get translation result.
loop
{
  ellipsis2.="."
  ToolTip, Translating%ellipsis2%
  
  if (DeepLTranslator.getTransResult())
  {
    MsgBox, % DeepLTranslator.getTransResult()
    break
  }
  else
    Sleep, 1000
}

ExitApp

#Include <DeepLTranslator>