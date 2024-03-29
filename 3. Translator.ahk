﻿gosub, CreateGUI
gosub, InitializeTranslator
return

CreateGUI:
  Gui Add, Edit, x16 y10 w450 h150 vOriginal +Disabled
  Gui Add, Edit, x16 y220 w450 h150 vTranslation +Disabled
  Gui Add, Button, x16 y170 w450 h40 vTranslate +Disabled, Translate
  Gui Show, w482 h380, Translator
return

InitializeTranslator:
  GuiControl, , Original, Initializing...`n正在初始化...
  ; SogouTranslator.multiLanguage.5 = Timeout
  if (SogouTranslator.init().Error=SogouTranslator.multiLanguage.5)
    GuiControl, , Original, Initialization failed, please exit and try again.`n初始化失败，请退出重试。
  else
  {
    GuiControl, Enable, Original
    GuiControl, Enable, Translation
    GuiControl, Enable, Translate
    GuiControl, , Original, Initialization succeeded, please enter the text to be translated.`n初始化完成，请输入待翻译文本。
  }
return

ButtonTranslate:
  Gui, Submit, NoHide
  GuiControl, , Translation, Translating...`n翻译中...
  
  ; To determine whether Chinese to English or English to Chinese translation is based on the percentage of Chinese characters in the original text
  RegExReplace(Original, "[一-龟]", , Chinese_Characters_Len)
  if (Chinese_Characters_Len/StrLen(Original) > 0.6)
    ret := SogouTranslator.translate(Original, "zh", "en")
  else
    ret := SogouTranslator.translate(Original)
  
  GuiControl, , Translation, % ret.Error ? ret.Error : ret
return

GuiEscape:
GuiClose:
  ExitApp
return

#Include <SogouTranslator>