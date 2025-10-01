# Open Windows Terminal in current Explorer folder (AutoHotkey v2)

A tiny AutoHotkey v2 script that opens Windows Terminal at the current File Explorer folder using the hotkey Ctrl+Alt+T.

This repository contains:
- `terminal-in-folder.ahk` — AutoHotkey v2 script that opens Windows Terminal in the folder shown by the active File Explorer window. If it cannot resolve a folder path it falls back to launching Windows Terminal normally.
- Precompiled EXE (will be published in Releases) for users who don't want to install AutoHotkey.

## Features

- Single-file AutoHotkey v2 script (easy to read and modify).
- Opens Windows Terminal (`wt.exe`) in the folder shown by the active Explorer window.
- Graceful fallback if no valid Explorer path is found.
- Easily rebind the hotkey or change the command used to open the terminal.

## Requirements

- Windows 10 / Windows 11
- Windows Terminal installed (`wt.exe` must be available in PATH)
- AutoHotkey v2 to run the `.ahk` source, or download the precompiled EXE from Releases.

## Quick start

1. Download the source file `terminal-in-folder.ahk` and double-click it (requires AutoHotkey v2), or download the precompiled `terminal-in-folder.exe` from the Releases page and run it.
2. With an Explorer window active, press Ctrl+Alt+T to open Windows Terminal in that folder.

Example: the default hotkey in the script is Ctrl+Alt+T (`^!t`).

## How it works (short)

1. Checks whether the active window is a File Explorer window (`ahk_class CabinetWClass`).
2. Iterates Shell.Application windows to find the matching Explorer instance and reads `window.Document.Folder.Self.Path`.
3. If a valid path is found, runs `wt.exe -d "<path>"`. Otherwise runs `wt.exe`.

## Customize

- Change the hotkey: edit the hotkey definition line in `terminal-in-folder.ahk` (AHK v2 syntax). Example: use Win+T by replacing `^!t::` with `#t::`.
- Use a different terminal or flags: modify the `Run` lines in the script.

## Compiling your own EXE (optional)

If you prefer an EXE (for distribution or to avoid installing AutoHotkey):

1. Install AutoHotkey v2 (includes Ahk2Exe or use the standalone Ahk2Exe compatible with AHK v2).
2. Open Ahk2Exe and build `terminal-in-folder.ahk` into an EXE.

Note: Precompiled AHK exes can sometimes be flagged as false positives by antivirus software. If that happens, either compile locally or run the `.ahk` source with AutoHotkey v2.

## Troubleshooting

- Nothing happens when pressing the hotkey:
  - Ensure the script/EXE is running (check the system tray).
  - Confirm the active window is a File Explorer window.
  - Ensure Windows Terminal (`wt.exe`) is installed and in PATH.
- Windows Terminal opens but not in the expected folder:
  - Some Explorer windows (e.g., special shell folders or elevated windows) may not expose a standard folder path.
  - Network paths or permission restrictions can prevent correct detection.
- Antivirus flags the EXE:
  - Build the EXE locally or run the `.ahk` file directly.

## Security & Privacy

The script only reads the path of your active File Explorer window and launches `wt.exe` locally. It does not send any data out of your machine.


## Releases

I will publish a precompiled `terminal-in-folder.exe` on the Releases page for convenience. The source `terminal-in-folder.ahk` will remain available for review and recompilation.

---

# 현재 탐색기 폴더에서 Windows Terminal 열기 (AutoHotkey v2)

간단한 AutoHotkey v2 스크립트로, Ctrl+Alt+T 단축키로 현재 활성화된 파일 탐색기 경로에서 Windows Terminal을 엽니다.

리포지토리 구성:
- `terminal-in-folder.ahk` — 활성 파일 탐색기 창의 폴더에서 Windows Terminal을 여는 AutoHotkey v2 스크립트입니다. 경로를 확인할 수 없으면 기본적으로 Windows Terminal을 실행합니다.
- 미리 컴파일된 EXE (릴리스에 업로드 예정) — AutoHotkey를 설치하지 않은 사용자를 위한 빌드.

## 주요 기능

- 단일 파일(AHK v2) 스크립트로 간단히 사용 및 편집 가능
- 활성 탐색기 창의 폴더에서 바로 Windows Terminal(`wt.exe`)을 엽니다
- 탐색기 경로를 찾지 못할 때에도 안전한 폴백 동작 제공
- 단축키나 실행 명령을 쉽게 변경할 수 있음

## 요구사항

- Windows 10 / Windows 11
- Windows Terminal 설치 (`wt.exe`가 PATH에 있어야 함)
- 소스 `.ahk`를 실행하려면 AutoHotkey v2 필요, 또는 릴리스의 EXE 사용

## 빠른 시작

1. `terminal-in-folder.ahk`를 다운로드하여 더블클릭으로 실행(AHK v2 필요)하거나, 릴리스에서 미리 컴파일된 `terminal-in-folder.exe`를 다운로드하여 실행하세요.
2. 탐색기 창을 활성화한 뒤 Ctrl+Alt+T를 누르면 해당 폴더에서 Windows Terminal이 열립니다.

기본 단축키는 Ctrl+Alt+T (`^!t`)입니다.

## 작동 원리 (간단)

1. 활성 창이 파일 탐색기인지(`ahk_class CabinetWClass`) 확인합니다.
2. Shell.Application의 윈도우들을 순회해 해당 탐색기 인스턴스를 찾고 `window.Document.Folder.Self.Path`를 읽습니다.
3. 유효한 경로가 있으면 `wt.exe -d "<path>"`로 실행하고, 없으면 `wt.exe`를 실행합니다.

## 사용자 지정

- 단축키 변경: `terminal-in-folder.ahk`의 첫 줄(혹은 핫키 정의)을 편집하세요. 예: Win+T로 바꾸려면 `^!t::`를 `#t::`로 변경합니다.
- 다른 터미널이나 옵션을 사용하려면 스크립트 내 `Run` 라인을 수정하세요.

## EXE로 컴파일하기(선택)

1. AutoHotkey v2를 설치하고 Ahk2Exe로 `terminal-in-folder.ahk`를 빌드하세요.
2. 빌드한 EXE를 배포하거나 개인적으로 사용하세요.

참고: AHK로 컴파일한 EXE는 일부 백신에서 오탐이 발생할 수 있습니다. 이럴 경우 로컬에서 직접 빌드하거나 소스 `.ahk`를 실행하세요.

## 문제 해결

- 단축키가 동작하지 않을 때:
  - 스크립트/EXE가 실행 중인지(시스템 트레이 확인) 확인하세요.
  - 활성 창이 탐색기인지 확인하세요.
  - Windows Terminal(`wt.exe`)이 설치되어 PATH에서 접근 가능한지 확인하세요.
- 터미널이 예상 경로에서 열리지 않을 때:
  - 특수 폴더나 권한 문제로 경로를 노출하지 않는 탐색기 창이 있을 수 있습니다.
  - 네트워크 경로 또는 권한 제한 문제일 수 있습니다.
- EXE가 백신에 의해 차단될 때:
  - 로컬에서 빌드하거나 소스 `.ahk`를 실행하세요.

## 보안 및 개인정보

스크립트는 로컬의 활성 파일 탐색기 창 경로만 읽고 `wt.exe`를 실행합니다. 외부로 데이터를 전송하지 않습니다.


## 릴리스

편의를 위해 미리 컴파일된 `terminal-in-folder.exe`를 Releases에 업로드할 예정입니다. 소스는 계속 공개됩니다.
