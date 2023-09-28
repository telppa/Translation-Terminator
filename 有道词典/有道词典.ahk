; 不要用 neutron 库来写
; 用 neutron.qs(".main").innerHTML := template 更新内容的话，切换不了网络释义等模块
; 用 neutron.doc.write(template) 的话，会嵌套出多个 <body> 和 <html> ，导致定位失效
class youdao
{
	dict(word, url := "")
	{
		static wb
		
		; 取得待显示的内容
		设置=
		(`%
		ExpectedStatusCode:200
		NumberOfRetries:3
		)
		请求头=
		(`%
		User-Agent:Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3314.0 Safari/537.36 SE 2.X MetaSr 1.0
		)
		ret := WinHttp.Download(url ? url : "https://dict.youdao.com/w/" word, 设置, 请求头)    ; 下载并存到变量
		
		part1   := GetTag(ret, "<h2 class=""wordbook-js"">")         ; 单词
		part2   := GetTag(ret, "<div class=""trans-container"">")    ; 单词翻译
		part3   := GetTag(ret, "<div id=""webTrans""")               ; 释义模块
		part4_1 := GetTag(ret, "<div id=""examples""")               ; 例句模块
		part4_2 := GetTag(ret, "<div id=""bilingual""")              ; 双语例句
		part4_3 := GetTag(ret, "<div id=""authority""")              ; 权威例句
		part4   := part4_1 ? part4_1 : (part4_2 ? part4_2 : part4_3)
		
		if (part1="" and part2="" and part3="" and part4="")
			; 没找到单词意思
			template=
			(
				<div class="no-data-prompt">
					<span class="prompt">提示：</span><span class="no-word">抱歉没有找到“%word%”相关的词</span>
				</div>
				
				<style>
				.no-data-prompt{
						display: block;
						height: 61px;
						border: 1px solid #e6e7e8;
						border-radius: 8px;
						text-align: center;
						line-height: 61px;
						color: #626469;
						font-weight: 500;
				}
				</style>
			)
		else
			; 找到了
			template=
			(
				<!-- 以下2行 正确显示颜色及位置 -->
				<link href="%A_LineFile%/../result-min.css" rel="stylesheet" type="text/css"/>
				<style>body{margin:20;}</style>
				
				<!-- 以下5行 切换不同释义等模块 -->
				<script type='text/javascript' src='%A_LineFile%/../jquery-1.8.2.min.js'></script>
				<script type="text/javascript" src="%A_LineFile%/../autocomplete_json.js"></script>
				<script type="text/javascript" src="%A_LineFile%/../result-min.js"></script>
				<div id="result_navigator" class="result_navigator"></div>
					<div id="phrsListTab" class="trans-wrapper clearfix">
						%part1%
						%part2%
					</div>
				%part3%
				%part4%
			)
		
		; 首次运行则创建窗口
		if (!IsObject(wb))
		{
			Gui youdao_dict:Add, ActiveX, x0 y0 w480 h360 vwb, Shell.Explorer
			
			this.wb := wb
			wb.silent := true                 ; 屏蔽 js 脚本错误提示
			wb.Navigate("about:blank")        ; 打开空白页
			ComObjConnect(wb, this.wb_events) ; 修复内部跳转（通常是相关单词）
			
			; 获取屏幕物理尺寸
			hdcScreen       := DllCall("GetDC", "UPtr", 0)
			devicecaps_w    := DllCall("GetDeviceCaps", "UPtr", hdcScreen, "Int", 4) ; 毫米
			devicecaps_h    := DllCall("GetDeviceCaps", "UPtr", hdcScreen, "Int", 6) ; 毫米
			devicecaps_size := (Sqrt(devicecaps_w**2 + devicecaps_h**2)/25.4)        ; 英寸 勾股求斜边
			
			; 根据屏幕大小设置缩放比例
			if (devicecaps_size <= 15)
				scale := 1.4
			else if (devicecaps_size <= 17)
				scale := 1.25
			else
				scale := 1.1
			
			; 设置缩放比例，此处比例是根据显示器尺寸与 dpiscale 综合得来
			zoom := (A_ScreenDPI/96*100)*scale & 0xFFFFFFFF  ; ensure INT
			wb.ExecWB(OLECMDID_OPTICAL_ZOOM:=63, OLECMDEXECOPT_DONTPROMPTUSER:=2, zoom, 0)
			
			; 让热键功能比如 Ctrl+C 等生效
			BoundFunc := ObjBindMethod(this, "WM_KeyPress")
			OnMessage( 0x0100, BoundFunc ) ; WM_KEYDOWN
			OnMessage( 0x0101, BoundFunc ) ; WM_KEYUP
			
			while wb.Busy
				sleep 10
		}
		
		; 更新内容
		wb.document.write(template)
		wb.document.close()
		
		; 显示
		Gui youdao_dict:Show, w480 h360,有道词典
		return
		
		有道词典GuiClose:
			Gui youdao_dict:Hide
		return
	}
	
	; 修复内部跳转（通常是相关单词）
	class wb_events
	{
		BeforeNavigate2(pDisp, Url, Flags, TargetFrameName, PostData, Headers, Cancel)
		{
			; Url 形如
			; about:/w/eng/apple_computer/#keyfrom=dict.phrase.wordgroup
			; about:/w/price/#keyfrom=E2Ctranslation
			; about:/example/价格/#keyfrom=dict.basic.ce27	
			; about:blank
			if (SubStr(Url, 1, 7) = "about:/")
			{
				Cancel[] := true                                           ; -1 取消跳转，0 继续跳转 https://www.autohotkey.com/boards/viewtopic.php?t=7367
				obj := CrackUrl("https://dict.youdao.com/" SubStr(Url, 8))
				Url := obj.Scheme "://" obj.HostName obj.UrlPath           ; Url 必须去掉锚点的（带锚点会导致下载失败）
				youdao.dict("", Url)
			}
			else if (Url="about:blank")
			{
				Cancel[] := true
				this.ShowTip("此链接指向空白页", 5)
			}
		}
		
		ShowTip(text, WhichToolTip := 1)
		{
			ToolTip %text%, , , %WhichToolTip%
			ToolTipHide := ObjBindMethod(this, "HideTip", WhichToolTip)
			SetTimer % ToolTipHide, -1000
		}
		
		HideTip(WhichToolTip)
		{
			ToolTip, , , , %WhichToolTip%
		}
	}
	
	; 让热键功能比如 Ctrl+C 等生效
	WM_KeyPress( wParam, lParam, nMsg, hWnd )
	{
		static Vars := ["hWnd", "nMsg", "wParam", "lParam", "A_EventInfo", "A_GuiX", "A_GuiY"]
		
		if (A_Gui = "youdao_dict")
		{
			WinGetClass, ClassName, ahk_id %hWnd%
			if ( ClassName = "Internet Explorer_Server" )
			{
				VarSetCapacity( MSG, 28, 0 )                    ; MSG STructure    http://goo.gl/4bHD9Z
				for k, v in Vars
					NumPut( %v%, MSG, ( A_Index-1 ) * A_PtrSize )
				
				IOleInPlaceActiveObject_Interface := "{00000117-0000-0000-C000-000000000046}"
				pipa := ComObjQuery( this.wb, IOleInPlaceActiveObject_Interface )
				TranslateAccelerator := NumGet( NumGet( pipa+0 ) + 5*A_PtrSize )
				
				loop, 2  ; IOleInPlaceActiveObject::TranslateAccelerator method    http://goo.gl/XkGZYt
					r := DllCall( TranslateAccelerator, "UInt", pipa, "UInt", &MSG )
				until, (wParam != 9 or this.wb.document.activeElement != "")
				
				ObjRelease( pipa )
				
				if (r = 0)
					return, 0  ; S_OK: the message was translated to an accelerator.
			}
		}
	}
}

#Include %A_LineFile%\..\Lib\WinHttp.ahk
#Include %A_LineFile%\..\Lib\GetTag.ahk
#Include %A_LineFile%\..\Lib\CrackUrl.ahk