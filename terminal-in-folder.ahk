; Ctrl+Alt+T -> 현재 탐색기 경로에서 Windows Terminal 열기 (AHK v2)
^!t::
{
    expHwnd := WinActive("ahk_class CabinetWClass") ; File Explorer
    path := ""
    if expHwnd {
        for window in ComObject("Shell.Application").Windows {
            if (window.hwnd = expHwnd) {
                try path := window.Document.Folder.Self.Path
            }
        }
    }
    if (path = "" || !DirExist(path)) {
        ; 폴백: 사용자 프로필에서 열기
        Run "wt.exe"
        return
    }
    ; 현재 경로에서 터미널 열기
    Run Format('wt.exe -d "{}"', path)
}
