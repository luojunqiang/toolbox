
; @sa https://github.com/AnyOfYou/Windows-AHK-SwitchProxy/blob/master/SwitchProxy.ahk
;
; private const uint INTERNET_OPTION_REFRESH = 37;
;   Causes the proxy data to be reread from the registry for a handle. No buffer is required. This option can be used on the HINTERNET handle returned by InternetOpen. It is used by InternetSetOption.
; private const uint INTERNET_OPTION_SETTINGS_CHANGED = 39;
;   Notifies the system that the registry settings have been changed so that it verifies the settings on the next call to InternetConnect. This is used by InternetSetOption.
; private const uint INTERNET_OPTION_PROXY_SETTINGS_CHANGED = 95;
;   Alerts the current WinInet instance that proxy settings have changed and that they must update with the new settings. To alert all available WinInet instances, set the Buffer parameter of InternetSetOption to NULL and BufferLength to 0 when passing this option. This option can be set on the handle returned by InternetConnect or HttpOpenRequest.
;
;BOOL InternetSetOption(
;  _In_ HINTERNET hInternet,
;  _In_ DWORD     dwOption,
;  _In_ LPVOID    lpBuffer,
;  _In_ DWORD     dwBufferLength
;);
;
;[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings]
;"ProxyEnable"=dword:00000000
;"ProxyServer"="proxy:8080"
;"ProxyOverride"="*.xxx.com;<local>"

SetIeProxy(state) {
	vKey := "Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	RegWrite,REG_DWORD,HKCU,%vKey%,ProxyEnable,%state%
	;Tooltip,%vKey% %A_IsAdmin%--%vState%--%A_LastError%
	if (state == 0) {
		ToolTip,IE proxy now is [OFF]
	} else {
		RegRead, vProxyServer, HKCU, %vKey%, ProxyServer
		ToolTip,IE proxy now is [%vProxyServer%]
	}
	dllcall("wininet\InternetSetOptionW","int","0","int","39","int","0","int","0")
	dllcall("wininet\InternetSetOptionW","int","0","int","37","int","0","int","0")
	Sleep,3000
	ToolTip
	Return
}

;#NoTrayIcon
;SetIeProxy(1)
