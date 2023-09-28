; 取自 “http://ahkscript.org/boards/viewtopic.php?f=6&t=2512&hilit=parse+url”
; 修复原版不能在64位运行的问题。
; 返回值为空说明字符串不是 url ，否则返回包含具体信息的对象。
CrackUrl(url)
{
	; 生成结构体
	VarSetCapacity(URL_COMPONENTS, A_PtrSize == 8 ? 104 : 60, 0)
	
	; 必须先设置以下项的值才能完成结构体的初始化
	; https://docs.microsoft.com/zh-tw/previous-versions/aa919268(v=msdn.10)
	NumPut(A_PtrSize == 8 ? 104 : 60, URL_COMPONENTS, 0, "UInt")  ; dwStructSize
	NumPut(1, URL_COMPONENTS, A_PtrSize == 8 ? 16 : 8, "UInt")    ; dwSchemeLength
	NumPut(1, URL_COMPONENTS, A_PtrSize == 8 ? 32 : 20, "UInt")   ; dwHostNameLength
	NumPut(1, URL_COMPONENTS, A_PtrSize == 8 ? 48 : 32, "UInt")   ; dwUserNameLength
	NumPut(1, URL_COMPONENTS, A_PtrSize == 8 ? 64 : 40, "UInt")   ; dwPasswordLength
	NumPut(1, URL_COMPONENTS, A_PtrSize == 8 ? 80 : 48, "UInt")   ; dwUrlPathLength
	NumPut(1, URL_COMPONENTS, A_PtrSize == 8 ? 96 : 56, "UInt")   ; dwExtraInfoLength
	
	; 通过返回值是否为1可以判断字符串是否是 url
	if (DllCall("Winhttp.dll\WinHttpCrackUrl", "Ptr",&url, "UInt",StrLen(url), "UInt",0, "Ptr",&URL_COMPONENTS)=1)
	{
		lpszScheme        := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 8 : 4, "Ptr")
		dwSchemeLength    := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 16 : 8, "UInt")
		lpszHostName      := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 24 : 16, "Ptr")
		dwHostNameLength  := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 32 : 20, "UInt")
		nPort             := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 36 : 24, "Int")
		lpszUserName      := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 40 : 28, "Ptr")
		dwUserNameLength  := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 48 : 32, "UInt")
		lpszPassword      := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 56 : 36, "Ptr")
		dwPasswordLength  := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 64 : 40, "UInt")
		lpszUrlPath       := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 72 : 44, "Ptr")
		dwUrlPathLength   := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 80 : 48, "UInt")
		lpszExtraInfo     := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 88 : 52, "Ptr")
		dwExtraInfoLength := NumGet(URL_COMPONENTS, A_PtrSize == 8 ? 96 : 56, "UInt")
		
		ret := {}
		ret.Scheme    := StrGet(lpszScheme, dwSchemeLength)
		ret.HostName  := StrGet(lpszHostName, dwHostNameLength)
		ret.Port      := nPort
		ret.UserName  := StrGet(lpszUserName, dwUserNameLength)
		ret.Password  := StrGet(lpszPassword, dwPasswordLength)
		ret.UrlPath   := StrGet(lpszUrlPath, dwUrlPathLength)
		ret.ExtraInfo := StrGet(lpszExtraInfo, dwExtraInfoLength)
		return, ret
	}
}