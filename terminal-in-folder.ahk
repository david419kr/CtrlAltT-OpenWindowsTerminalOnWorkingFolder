#Requires AutoHotkey v2.0
#SingleInstance Force

^!t::OpenWindowsTerminalHere()

OpenWindowsTerminalHere() {
    path := GetCurrentFolder()

    try {
        if (path != "" && DirExist(path)) {
            ; Pass the folder as the process working directory instead of
            ; interpolating it into the command line.
            Run "wt.exe -d .", path
        } else {
            Run "wt.exe"
        }
    } catch Error as err {
        MsgBox(
            "Windows Terminal을 실행할 수 없습니다.`n`n" err.Message,
            "Windows Terminal 실행 실패",
            "Iconx"
        )
    }
}

GetCurrentFolder() {
    activeHwnd := WinExist("A")
    if !activeHwnd
        return ""

    try activeClass := WinGetClass("ahk_id " activeHwnd)
    catch
        return ""

    if (activeClass = "CabinetWClass" || activeClass = "ExploreWClass")
        return GetExplorerFolder(activeHwnd)

    if (activeClass = "Progman" || activeClass = "WorkerW")
        return A_Desktop

    return ""
}

GetExplorerFolder(explorerHwnd) {
    candidates := []

    try {
        for window in ComObject("Shell.Application").Windows {
            try {
                if (Integer(window.HWND) = explorerHwnd)
                    candidates.Push(window)
            }
        }
    } catch {
        return ""
    }

    if (candidates.Length = 0)
        return ""

    activeTabHwnd := GetActiveExplorerTabHwnd(explorerHwnd)

    if activeTabHwnd {
        for window in candidates {
            if (GetExplorerTabHwnd(window) = activeTabHwnd)
                return GetFilesystemFolderPath(window)
        }
    }

    ; A single candidate is unambiguous on Windows 10 and on a one-tab window.
    if (candidates.Length = 1)
        return GetFilesystemFolderPath(candidates[1])

    ; Multiple tabs exist but the active one could not be identified.
    ; Returning no path is safer than opening in an inactive tab's folder.
    return ""
}

GetActiveExplorerTabHwnd(explorerHwnd) {
    try return ControlGetHwnd(
        "ShellTabWindowClass1",
        "ahk_id " explorerHwnd
    )
    catch
        return 0
}

GetExplorerTabHwnd(window) {
    static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"

    try {
        shellBrowser := ComObjQuery(
            window,
            IID_IShellBrowser,
            IID_IShellBrowser
        )
        if !shellBrowser
            return 0

        tabHwnd := 0
        ComCall(3, shellBrowser, "ptr*", &tabHwnd)
        return tabHwnd
    } catch {
        return 0
    }
}

GetFilesystemFolderPath(window) {
    try {
        path := window.Document.Folder.Self.Path
        return (path != "" && DirExist(path)) ? path : ""
    } catch {
        return ""
    }
}
