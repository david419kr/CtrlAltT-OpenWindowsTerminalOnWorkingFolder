#Requires AutoHotkey v2.0

^!t::
{
    path := ""

    if IsExplorerActive() {
        path := GetExplorerActiveTabPath()
    } else if IsDesktopActive() {
        path := A_Desktop
    }

    path := NormalizeDir(path)

    if (path != "" && DirExist(path)) {
        dirArg := MakeWtDirArg(path)              ; D:\  -> D:\. 로 바꿔 파싱 이슈 회피
        cmd := Format('wt.exe -d "{}"', dirArg)
        Run cmd, path                              ; working directory도 같이 지정
    } else {
        Run "wt.exe"                               ; 기존 폴백 유지
    }
}

IsExplorerActive() {
    return WinActive("ahk_class CabinetWClass") || WinActive("ahk_class ExploreWClass")
}

IsDesktopActive() {
    return WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW")
}

NormalizeDir(p) {
    if (p = "")
        return ""

    p := StrReplace(p, "`r")
    p := StrReplace(p, "`n")
    p := Trim(p)
    p := StrReplace(p, Chr(34), "")               ; 모든 " 제거

    ; "D:" 같은 형태면 루트로 보정
    if RegExMatch(p, "i)^[A-Z]:$") {
        p .= "\"
    }
    return p
}

MakeWtDirArg(p) {
    ; 끝이 "\"면 따옴표 파싱이 꼬일 수 있어 ".“을 붙여 끝 "\"를 제거한 형태로 전달
    if (p != "" && SubStr(p, -1) = "\")
        return p "."
    return p
}

GetExplorerActiveTabPath() {
    clipSaved := ClipboardAll()
    A_Clipboard := ""

    SendInput "!d"
    Sleep 50
    SendInput "^c"

    if !ClipWait(0.6) {
        A_Clipboard := clipSaved
        return ""
    }

    raw := A_Clipboard
    A_Clipboard := clipSaved

    raw := StrReplace(raw, "`r")
    raw := StrReplace(raw, "`n")
    raw := Trim(raw)
    raw := StrReplace(raw, Chr(34), "")

    if (raw = "")
        return ""

    ; file:///C:/... 형태면 경로로 변환
    if (InStr(raw, "file:///", true) = 1) {
        raw := SubStr(raw, 9)
        raw := StrReplace(raw, "/", "\")
        raw := Trim(raw)
        raw := StrReplace(raw, Chr(34), "")
    }

    ; 가상 경로는 실패 처리해서 폴백으로 넘김
    if RegExMatch(raw, "i)^(shell:|ms-)")
        return ""

    ; 드라이브/UNC 경로만 추출
    if RegExMatch(raw, "i)([A-Z]:(?:\\.*)?|\\\\[^\\]+\\.*)", &m)
        return m[1]

    return raw
}
