/*
匹配到的字符串，包含标签本身。
例如 data="123<em>abc</em>456" tag="<em>" 匹配到的结果是 “<em>abc</em>” 。

最后一个参数的意思是返回第n个符合的字串。
例如 data="<em>1</em><em>2</em><em>3</em>" tag="<em>" occurrence=2 匹配到的结果是 “<em>2</em>” 。

匹配到的标签总是平衡的。
例如 data="<em>1<em>2</em></em></em>" tag="<em>" 匹配到的结果是 “<em>1<em>2</em></em>” 。

修复了 GetNestedTag 的多个bug，并且大幅优化嵌套查找的性能。
*/
GetTag(data, tag, occurrence := 1, maximumDepth := 100)
{
  tag := Trim(tag) ; 移除前后的空格和tab，使得匹配 “<img ” “<img” 都能成功。
  if (data="" or tag="")
    return
  
  startpos := InStr(data, tag, false, 1, occurrence) ; false 代表不区分大小写。
  if (startpos=0)                                    ; 没有匹配的字符串则直接返回空值。
    return
  
  RegExMatch(tag, "iS)<([a-z0-9]+)", basetag) ; 原版的匹配规则 “i)<([a-z]*)” 无法匹配类似 <h2> 这样带数字的标签。
  , openstyle1 := "<" basetag1 ">"            ; 匹配类似 <head> 的情况。
  , openstyle2 := "<" basetag1 " "            ; 匹配类似 <head id=""> 的情况。
  , closestyle := "</" basetag1 ">"           ; 匹配类似 </head> 的情况。
  loop
  {
    ; 假设当前找到的内容中，已经存在10个开标签，则至少需要10个闭标签，因此直接使用开标签数量而不是 A_Index 来进行查找优化。
    endpos := InStr(data, closestyle, false, startpos, NonNull_Ret(opencount1+opencount2, 1)) + StrLen(closestyle)
    string := SubStr(data, startpos, endpos - startpos)
    
    StrReplace(string, openstyle1, openstyle1, opencount1)
    StrReplace(string, openstyle2, openstyle2, opencount2)
    StrReplace(string, closestyle, closestyle, closecount)
    if (opencount1+opencount2 = closecount) ; 确保匹配到的标签是平衡的。
      break
    
    if (A_Index>maximumDepth or endpos=0) ; 避免陷入死循环以及 data 中标签不平衡时快速返回。
      return
  }
  return string
}

#IncludeAgain %A_LineFile%\..\NonNull.ahk