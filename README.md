# Open Windows Terminal in the active Explorer folder

Press Ctrl+Alt+T to open Windows Terminal in the folder shown by the active File Explorer tab.

The script reads the current folder directly from Explorer's Shell/COM objects. It does not focus or copy the address bar, does not touch the clipboard, and does not depend on the `"Open in Terminal"` context-menu entry being installed.

## Files and downloads

- `terminal-in-folder.ahk` — readable AutoHotkey v2 source.
- [GitHub Releases](https://github.com/david419kr/CtrlAltT-OpenWindowsTerminalOnWorkingFolder/releases/latest) — source, precompiled `terminal-in-folder.exe`, and SHA-256 checksums.

## Features

- Opens Windows Terminal in the active Explorer tab's actual filesystem folder.
- Correctly distinguishes tabs that share the same Explorer window on Windows 11.
- Supports Windows 10 Explorer windows and the Windows desktop.
- Does not send `Alt+D`/`Ctrl+C` or read and restore the clipboard.
- Passes the folder as the process working directory and runs `wt.exe -d .`, avoiding path quoting and drive-root parsing problems.
- Falls back to a normal `wt.exe` launch when the active location is not a real filesystem directory.
- Works even when the Windows Terminal context-menu entry is hidden, disabled, or not registered.

## Requirements

- Windows 10 or Windows 11.
- Windows Terminal installed, with the `wt.exe` app execution alias available.
- AutoHotkey v2 for the `.ahk` source, or the precompiled EXE from Releases.

## Quick start

1. Exit any older copy of this script or EXE that is already running.
2. Run `terminal-in-folder.ahk` with AutoHotkey v2, or run `terminal-in-folder.exe` from Releases.
3. Activate a File Explorer window or the desktop.
4. Press Ctrl+Alt+T.

When another application is active, Ctrl+Alt+T opens Windows Terminal normally without forcing an Explorer path.

## How it works

1. Reads the active window handle and checks whether it belongs to Explorer or the desktop.
2. Enumerates `Shell.Application.Windows` entries whose top-level HWND matches the active Explorer window.
3. On Windows 11, matches `ShellTabWindowClass1` with each entry's `IShellBrowser` window handle to select the active tab instead of another tab in the same window.
4. Reads `window.Document.Folder.Self.Path` and accepts it only when it is an existing filesystem directory.
5. Runs `wt.exe -d .` with that folder set as the process working directory.
6. If the folder cannot be resolved safely, runs `wt.exe` without a directory argument.

Virtual Shell locations such as Home, This PC, search results, Control Panel, and the Recycle Bin do not have a normal filesystem directory. In those locations, the script intentionally uses the normal Terminal fallback.

## Customize

- Change the hotkey by editing `^!t::OpenWindowsTerminalHere()` in `terminal-in-folder.ahk`.
- For example, replace `^!t` with `#t` to use Win+T.
- Change the `Run` lines if you want to use another terminal command.

## Build the EXE

1. Install AutoHotkey v2, including Ahk2Exe.
2. Compile `terminal-in-folder.ahk` with the AutoHotkey v2 64-bit base executable.

The release EXE is an unsigned AutoHotkey-compiled executable. Some antivirus products may report a false positive. If that happens, use the source directly or compile it locally.

## Troubleshooting

- **Nothing happens**
  - Confirm that the script/EXE is running in the notification area.
  - Exit older copies that may still own the same Ctrl+Alt+T hotkey.
  - Confirm that Windows Terminal is installed and the `wt.exe` app execution alias is enabled.
- **Terminal opens in its default folder**
  - The current Explorer location may be a virtual Shell folder rather than a filesystem directory.
  - The folder may be unavailable because of network or permission problems.
- **A shell startup script changes the folder**
  - PowerShell, CMD, or another profile can change its own directory after Terminal starts. Check the shell's profile/startup configuration.
- **Antivirus flags the EXE**
  - Run the `.ahk` source with AutoHotkey v2 or compile it locally.

## Security and privacy

The script reads local Explorer Shell objects and launches `wt.exe` locally. It does not send data over the network, modify the registry, invoke the context menu, simulate Explorer input, or access the clipboard.

---

# 활성 탐색기 폴더에서 Windows Terminal 열기

Ctrl+Alt+T를 누르면 현재 활성화된 파일 탐색기 탭의 폴더에서 Windows Terminal을 엽니다.

스크립트는 Explorer의 Shell/COM 객체에서 현재 폴더를 직접 읽습니다. 주소창을 활성화하거나 복사하지 않고, 클립보드를 건드리지 않으며, `"터미널에서 열기"` 컨텍스트 메뉴가 설치되어 있는지에도 의존하지 않습니다.

## 파일 및 다운로드

- `terminal-in-folder.ahk` — 내용을 확인할 수 있는 AutoHotkey v2 소스.
- [GitHub Releases](https://github.com/david419kr/CtrlAltT-OpenWindowsTerminalOnWorkingFolder/releases/latest) — 소스, 미리 컴파일된 `terminal-in-folder.exe`, SHA-256 체크섬.

## 주요 기능

- 활성 Explorer 탭의 실제 파일시스템 폴더에서 Windows Terminal을 엽니다.
- Windows 11에서 같은 Explorer 창을 공유하는 여러 탭을 정확히 구분합니다.
- Windows 10 Explorer 창과 Windows 바탕 화면을 지원합니다.
- `Alt+D`/`Ctrl+C`를 보내거나 클립보드를 저장·복원하지 않습니다.
- 폴더를 프로세스 작업 디렉터리로 지정하고 `wt.exe -d .`를 실행하므로 경로 따옴표와 드라이브 루트 파싱 문제를 피합니다.
- 활성 위치가 실제 파일시스템 디렉터리가 아니면 일반 `wt.exe` 실행으로 폴백합니다.
- Windows Terminal 컨텍스트 메뉴가 숨겨졌거나 비활성화됐거나 등록되지 않은 PC에서도 작동합니다.

## 요구사항

- Windows 10 또는 Windows 11.
- Windows Terminal이 설치되어 있고 `wt.exe` 앱 실행 별칭을 사용할 수 있어야 합니다.
- `.ahk` 소스 실행에는 AutoHotkey v2가 필요하며, 또는 Releases의 미리 컴파일된 EXE를 사용할 수 있습니다.

## 빠른 시작

1. 실행 중인 이전 버전의 스크립트나 EXE를 종료합니다.
2. AutoHotkey v2로 `terminal-in-folder.ahk`를 실행하거나 Releases의 `terminal-in-folder.exe`를 실행합니다.
3. 파일 탐색기 창 또는 바탕 화면을 활성화합니다.
4. Ctrl+Alt+T를 누릅니다.

다른 애플리케이션이 활성화된 상태에서 Ctrl+Alt+T를 누르면 Explorer 경로를 강제하지 않고 Windows Terminal을 일반 실행합니다.

## 작동 원리

1. 활성 창의 핸들을 읽고 Explorer 또는 바탕 화면인지 확인합니다.
2. 최상위 HWND가 활성 Explorer 창과 같은 `Shell.Application.Windows` 항목을 찾습니다.
3. Windows 11에서는 `ShellTabWindowClass1`과 각 항목의 `IShellBrowser` 창 핸들을 비교하여 같은 창의 다른 탭이 아닌 활성 탭을 선택합니다.
4. `window.Document.Folder.Self.Path`를 읽고 실제로 존재하는 파일시스템 디렉터리인 경우에만 사용합니다.
5. 해당 폴더를 프로세스 작업 디렉터리로 지정하고 `wt.exe -d .`를 실행합니다.
6. 폴더를 안전하게 확인할 수 없으면 디렉터리 인수 없이 `wt.exe`를 실행합니다.

홈, 내 PC, 검색 결과, 제어판, 휴지통 같은 가상 Shell 위치에는 일반 파일시스템 디렉터리가 없습니다. 이런 위치에서는 의도적으로 일반 Terminal 실행으로 폴백합니다.

## 사용자 지정

- `terminal-in-folder.ahk`의 `^!t::OpenWindowsTerminalHere()`를 수정하여 단축키를 변경할 수 있습니다.
- 예를 들어 `^!t`를 `#t`로 바꾸면 Win+T를 사용합니다.
- 다른 터미널 명령을 사용하려면 `Run` 줄을 수정합니다.

## EXE 빌드

1. Ahk2Exe를 포함한 AutoHotkey v2를 설치합니다.
2. AutoHotkey v2 64비트 base 실행 파일로 `terminal-in-folder.ahk`를 컴파일합니다.

릴리스 EXE는 서명되지 않은 AutoHotkey 컴파일 실행 파일입니다. 일부 백신에서 오탐할 수 있습니다. 이 경우 소스를 직접 실행하거나 로컬에서 컴파일하세요.

## 문제 해결

- **아무 반응이 없을 때**
  - 알림 영역에서 스크립트/EXE가 실행 중인지 확인합니다.
  - 같은 Ctrl+Alt+T 단축키를 사용하는 이전 버전을 종료합니다.
  - Windows Terminal이 설치되어 있고 `wt.exe` 앱 실행 별칭이 활성화되어 있는지 확인합니다.
- **Terminal이 기본 폴더에서 열릴 때**
  - 현재 Explorer 위치가 파일시스템 디렉터리가 아닌 가상 Shell 폴더일 수 있습니다.
  - 네트워크 또는 권한 문제로 폴더에 접근하지 못할 수 있습니다.
- **셸 시작 스크립트가 폴더를 바꿀 때**
  - PowerShell, CMD 또는 다른 프로필이 Terminal 시작 후 자체적으로 디렉터리를 변경할 수 있습니다. 해당 셸의 프로필/시작 설정을 확인합니다.
- **백신이 EXE를 차단할 때**
  - AutoHotkey v2로 `.ahk` 소스를 실행하거나 로컬에서 직접 컴파일합니다.

## 보안 및 개인정보

스크립트는 로컬 Explorer Shell 객체를 읽고 로컬에서 `wt.exe`를 실행합니다. 네트워크로 데이터를 전송하거나, 레지스트리를 수정하거나, 컨텍스트 메뉴를 호출하거나, Explorer 입력을 시뮬레이트하거나, 클립보드에 접근하지 않습니다.
