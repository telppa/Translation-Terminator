; In my country, the connection to deepl is very unstable, it usually takes 5-30 seconds to get results.
; This means that your code will be stuck for 5-30 seconds at the same time (because it is waiting for the result).
; Using asynchronous mode, you can avoid this situation.

; If you don't use asynchronous mode, the program will get stuck on the next line for 5-30 seconds before it can run the code that follows.
DeepLTranslator.init(,,,"async")

; Get initialization results.
loop
{
  ; Because asynchronous mode is used, you can do whatever you want first, and then check the results.
  ; Here we will display some information dynamically.
  ellipsis.="."
  ; By the way, there is a library called BTT, which is as easy to use as ToolTip but more powerful.
  ; https://github.com/telppa/BeautifulToolTip
  ToolTip, Initializing%ellipsis%
  
  if (DeepLTranslator.getInitResult()!="")
  {
    MsgBox, Initialization succeeded
    break
  }
  else
    Sleep, 1000
}

DeepLTranslator.translate("Hello my love",,,"async")
loop
{
  ellipsis2.="."
  ToolTip, Translating%ellipsis2%
  
  if (DeepLTranslator.getResult()!="")
  {
    MsgBox, % DeepLTranslator.getResult()
    break
  }
  else
    Sleep, 1000
}

DeepLTranslator.free()
ExitApp

#Include <DeepLTranslator>