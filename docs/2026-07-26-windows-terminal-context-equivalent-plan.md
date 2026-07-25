# Windows Terminal 컨텍스트 메뉴 동등 동작 전환 검토 및 구현 계획

- 작성일: 2026-07-26
- 대상 저장소: `CtrlAltT-OpenWindowsTerminalOnWorkingFolder`
- 대상 파일: `terminal-in-folder.ahk`, `README.md`
- 이번 단계 범위: 가능성 분석과 구현 계획만 작성
- 이번 단계 제외: AHK 수정, EXE 빌드, 릴리스, 레지스트리 변경

> 구현 상태: 검토 후 승인되어 v3의 `terminal-in-folder.ahk`와 README에 반영 완료. 아래 내용은 구현 전 검토 및 검증 계획 기록입니다.

## 결론

구현 가능합니다.

단, Windows의 `"Windows 터미널에서 열기"` 메뉴 항목이나 그 COM 셸 확장을 프로그램으로 호출하는 방식은 사용하지 않아야 합니다. 그 방식은 메뉴가 등록되지 않았거나 셸 확장이 차단된 PC에서 작동하지 않으므로 요구사항과 정면으로 충돌합니다.

대신 다음 두 동작을 독립적으로 구현하면 사용자가 보는 결과는 컨텍스트 메뉴를 누른 것과 같아집니다.

1. 현재 활성 Explorer 탭의 실제 파일시스템 폴더를 Explorer의 객체 모델에서 읽습니다.
2. 그 폴더를 프로세스 작업 디렉터리로 지정한 뒤 `wt.exe -d .`를 실행합니다.

이 방식은 주소창 텍스트, 주소창의 편집 상태, Explorer 표시 언어, 클립보드, 키 입력 시뮬레이션 및 컨텍스트 메뉴 등록 여부에 의존하지 않습니다.

다만 “경로 전달 자체”를 완전히 없앨 수는 없습니다. 공식 컨텍스트 메뉴도 Explorer로부터 대상 폴더의 파일시스템 경로를 얻어 Windows Terminal에 전달합니다. 없앨 수 있는 것은 경로가 아니라, 경로를 **주소창 UI에서 복사하는 취약한 과정**입니다.

## 공식 컨텍스트 메뉴가 실제로 하는 일

Windows Terminal의 공식 셸 확장 `OpenTerminalHere`는 다음 순서로 동작합니다.

1. Explorer가 제공한 선택 항목 또는 현재 폴더 뷰에서 `IShellItem`을 구합니다.
2. `SIGDN_FILESYSPATH`로 실제 파일시스템 경로를 구합니다.
3. 패키지 안의 `WindowsTerminal.exe`에 `-d "<경로>"`를 전달합니다.
4. `CreateProcessW`의 `lpCurrentDirectory`에도 같은 경로를 지정합니다.

근거:

- [Windows Terminal `OpenTerminalHere::Invoke` 공식 소스](https://github.com/microsoft/terminal/blob/4f225a56aff245bbb9d1400f266c20e1747cc580/src/cascadia/ShellExtension/OpenTerminalHere.cpp#L26-L74)
- [현재 Explorer 폴더 뷰를 얻는 공식 소스](https://github.com/microsoft/terminal/blob/4f225a56aff245bbb9d1400f266c20e1747cc580/src/cascadia/ShellExtension/OpenTerminalHere.cpp#L173-L208)
- [Directory 및 Directory Background에 셸 확장을 등록하는 공식 manifest](https://github.com/microsoft/terminal/blob/4f225a56aff245bbb9d1400f266c20e1747cc580/src/cascadia/CascadiaPackage/Package.appxmanifest#L220-L229)
- [`-d`/`--startingDirectory` 공식 문서](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments)

따라서 이 작업의 목표는 공식 셸 확장 DLL을 재사용하는 것이 아니라, 그 DLL의 아래 계약을 AHK에서 독립적으로 재현하는 것입니다.

> 활성 Explorer 폴더의 실제 파일시스템 경로를 얻고, 그 경로에서 Windows Terminal의 기본 프로필을 연다.

## 현재 구현에서 확인된 문제

현재 `terminal-in-folder.ahk`는 다음 방식으로 경로를 구합니다.

1. `Alt+D`를 보내 주소창을 활성화합니다.
2. `Ctrl+C`를 보내 주소창 내용을 클립보드로 복사합니다.
3. 최대 0.6초 동안 클립보드를 기다립니다.
4. 표시 문자열에서 드라이브/UNC 경로를 정규식으로 추출합니다.
5. 추출한 경로를 `wt.exe -d "<경로>"`에 다시 문자열로 넣습니다.

구체적으로 `terminal-in-folder.ahk:55-95`가 주소창/클립보드 처리이고, `terminal-in-folder.ahk:15-20`이 Terminal 실행 처리입니다.

이 구조에는 다음 문제가 있습니다.

- 단축키를 누를 때 주소창이 편집 중이면 “현재 폴더”가 아니라 아직 이동하지 않은 입력 문자열을 복사할 수 있습니다.
- Explorer의 키 포커스를 주소창으로 옮깁니다.
- 사용자의 클립보드를 저장·교체·복원하므로 다른 클립보드 프로그램이나 동시 복사와 경합할 수 있습니다.
- 고정된 `Sleep 50` 및 `ClipWait(0.6)` 타이밍에 의존합니다.
- Explorer의 표시 문자열을 다시 파일시스템 경로로 해석해야 합니다.
- 드라이브 루트의 끝 `\`와 명령행 따옴표 문제를 별도 보정해야 합니다.

또한 README의 설명은 현재 코드와 일치하지 않습니다. README는 `Shell.Application`과 `window.Document.Folder.Self.Path`를 사용한다고 설명하지만, 실제 코드는 주소창 복사 방식을 사용합니다.

## 과거 COM 구현이 Windows 11 탭에서 실패한 이유

초기 버전은 `Shell.Application.Windows`를 순회하고 Explorer 최상위 HWND가 같은 항목의 `window.Document.Folder.Self.Path`를 읽었습니다. Windows 10의 단일 폴더 창에서는 충분하지만, Windows 11의 탭 Explorer에서는 불충분합니다.

현재 PC에서 읽기 전용으로 확인한 결과:

- Explorer 최상위 창 하나에 여러 `ShellTabWindowClass` 탭이 존재합니다.
- `Shell.Application.Windows`에는 탭별 항목이 따로 존재합니다.
- 같은 창의 모든 탭 항목이 동일한 최상위 `window.HWND`를 반환합니다.
- 각 탭의 `IShellBrowser::GetWindow` 결과는 서로 다른 탭 HWND입니다.
- 활성 탭은 최상위 Explorer 창의 첫 번째 `ShellTabWindowClass`와 대응했습니다.

즉, 최상위 HWND만 비교하면 어느 탭이 활성 탭인지 판별할 수 없습니다. 현재 HEAD `9dc92f2`가 주소창 복사 방식으로 전환된 이유와도 일치합니다.

## 권장 설계

```text
Ctrl+Alt+T
  |
  +-- Desktop 활성 -> A_Desktop
  |
  +-- Explorer 활성
  |     |
  |     +-- Windows 11 탭 HWND 확인
  |     |
  |     +-- Shell.Application.Windows 순회
  |     |
  |     +-- 최상위 HWND와 탭 HWND가 모두 맞는 항목 선택
  |     |
  |     +-- window.Document.Folder.Self.Path 읽기
  |
  +-- 실제 디렉터리인지 검증
          |
          +-- 성공 -> 해당 폴더를 작업 디렉터리로 `wt.exe -d .`
          |
          +-- 실패 -> 기존과 같이 기본 `wt.exe`
```

### 1. 활성 Explorer 창 판별

현재의 `CabinetWClass` 및 `ExploreWClass` 판별은 유지할 수 있습니다. Desktop의 `Progman`/`WorkerW` 처리도 유지합니다.

### 2. Windows 11 활성 탭 판별

Explorer 최상위 HWND 아래의 `ShellTabWindowClass1` HWND를 구합니다. 현재 Windows 11 Explorer에서 이 핸들이 활성 탭에 대응합니다.

그 다음 `Shell.Application.Windows`의 각 항목에 대해:

1. `window.HWND`가 활성 Explorer 최상위 HWND와 같은지 확인합니다.
2. 해당 COM 항목을 `IShellBrowser`로 질의합니다.
3. `IShellBrowser`의 `IOleWindow::GetWindow`를 호출해 그 항목의 탭 HWND를 얻습니다.
4. 얻은 탭 HWND가 `ShellTabWindowClass1`과 같은 항목만 선택합니다.
5. 선택된 항목의 `window.Document.Folder.Self.Path`를 읽습니다.

AHK v2 구현 시 HWND 반환값은 64비트 환경에서도 잘리지 않도록 `Ptr` 크기로 취급해야 합니다.

`IShellBrowser::QueryActiveShellView`는 현재 표시되는 Shell view를 얻기 위한 공식 API이고, `IFolderView`는 폴더 객체를 얻는 공식 인터페이스입니다.

- [`IShellBrowser::QueryActiveShellView` 문서](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ishellbrowser-queryactiveshellview)
- [`IFolderView` 문서](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-ifolderview)

이번 저장소에는 `Shell.Application`에서 이미 제공되는 `Folder.Self.Path`만 필요하므로, 처음부터 전체 `IFolderView` vtable을 직접 구현할 필요는 없습니다. 활성 탭 HWND를 정확히 매칭하는 최소 COM 호출만 추가하는 편이 유지보수성이 좋습니다.

### 3. Windows 10 및 탭이 없는 Explorer

`ShellTabWindowClass1`이 없으면 기존 COM 방식처럼 최상위 HWND가 같은 Explorer 항목의 `Folder.Self.Path`를 사용합니다. 탭이 없는 환경에서는 동일 HWND에 대응하는 실제 폴더 뷰가 하나이므로 이 경로가 충분합니다.

### 4. Terminal 실행

권장 실행 형태는 개념적으로 다음과 같습니다.

```text
명령행: wt.exe -d .
작업 디렉터리: Explorer COM에서 얻은 실제 폴더 경로
```

이렇게 하면 실제 경로 문자열을 Terminal 명령행에 다시 삽입하지 않아도 됩니다.

Windows Terminal은 호출 프로세스의 현재 디렉터리를 기존 Terminal 인스턴스로 넘기고, `-d .` 같은 상대 경로를 그 호출 디렉터리 기준으로 평가하도록 구현되어 있습니다. 공식 소스 주석도 기존 Terminal 창에 `wt -w 0 nt -d .`를 전달하는 경우를 명시적으로 다룹니다.

- [호출 프로세스의 CWD를 전달하는 공식 소스](https://github.com/microsoft/terminal/blob/4f225a56aff245bbb9d1400f266c20e1747cc580/src/cascadia/WindowsTerminal/WindowEmperor.cpp#L122-L133)
- [`-d .`를 호출 CWD 기준으로 처리하는 공식 소스](https://github.com/microsoft/terminal/blob/4f225a56aff245bbb9d1400f266c20e1747cc580/src/cascadia/TerminalApp/TerminalPage.cpp#L708-L744)
- [상대 starting directory 평가 관련 공식 소스](https://github.com/microsoft/terminal/blob/4f225a56aff245bbb9d1400f266c20e1747cc580/src/cascadia/TerminalApp/TerminalPage.cpp#L1590-L1608)

이 선택의 장점:

- 공백, 한글, 일본어, `&`, `%` 등이 포함된 실제 경로를 명령행에 인용할 필요가 없습니다.
- `D:\` 같은 드라이브 루트의 끝 `\`와 따옴표 충돌 보정이 필요 없습니다.
- `NormalizeDir`와 `MakeWtDirArg`의 대부분을 제거할 수 있습니다.
- Terminal의 `windowingBehavior` 설정에 따른 새 창/기존 창 탭 동작은 기존 `wt.exe` 호출과 동일하게 유지됩니다.

### 5. 파일시스템 폴더만 허용

공식 Terminal 셸 확장도 대상이 `SFGAO_FILESYSTEM`이 아니면 메뉴를 숨깁니다. 따라서 다음 가상 위치에서는 억지로 경로를 만들지 않아야 합니다.

- 홈
- 내 PC
- 네트워크 루트
- 검색 결과
- 제어판
- 휴지통
- 기타 `::{CLSID}` Shell namespace

`Folder.Self.Path`가 실제 디렉터리이고 `DirExist(path)`가 참인 경우에만 해당 폴더에서 Terminal을 엽니다. 그렇지 않으면 현재 동작처럼 인수 없는 `wt.exe`를 실행합니다.

### 6. 컨텍스트 메뉴가 없는 PC 지원

새 구현은 아래 항목을 조회하거나 호출하지 않습니다.

- `OpenTerminalHere` verb
- Windows Terminal 셸 확장 CLSID
- `Directory\Background\shell` 레지스트리 키
- 우클릭 메뉴 UI

따라서 메뉴가 사용자 설정으로 숨겨졌거나, 셸 확장이 차단되었거나, Portable/비패키지 Terminal을 사용해 메뉴가 원래 없는 PC에서도 `wt.exe`만 실행 가능하면 작동합니다.

경계는 명확합니다.

- **메뉴가 없음 + `wt.exe` 사용 가능:** 지원 대상
- **Windows Terminal이 설치되지 않음:** 실행할 프로그램 자체가 없으므로 지원 불가
- **Terminal은 설치됐지만 app execution alias가 꺼져 `wt.exe`를 찾을 수 없음:** 명확한 오류 처리 또는 별도 실행 파일 탐색 정책이 필요

초기 구현에서는 현재 README 요구사항인 “`wt.exe`가 PATH에서 사용 가능”을 유지하는 것이 가장 단순합니다. 별도 경로 탐색은 실제 요구가 확인된 뒤 추가하는 편이 좋습니다.

## 사용하지 않을 접근

### 컨텍스트 메뉴 verb 직접 호출

`FolderItem.InvokeVerb`, `ShellExecute` 또는 셸 확장 CLSID를 통해 `OpenTerminalHere`를 호출하는 방식은 메뉴/COM 등록이 없는 PC에서 실패합니다. 이번 요구사항에는 부적합합니다.

### 주소창 키 입력/클립보드 폴백

새 기본 경로가 실패했을 때 다시 `Alt+D`, `Ctrl+C`로 돌아가면 주소창 상태 비의존이라는 목표가 깨집니다. COM에서 활성 탭을 확정하지 못한 경우에는 잘못된 탭에서 여는 것보다 기본 `wt.exe` 폴백이 안전합니다.

### 창 제목 또는 탭 이름으로 경로 매칭

동일한 이름의 폴더가 여러 탭에 열릴 수 있고, Explorer 창 제목은 현지화되며 전체 경로가 아닙니다. 탭 이름 문자열이 아니라 탭 HWND를 비교해야 합니다.

### 레지스트리에 자체 컨텍스트 메뉴 설치

사용자는 메뉴를 추가해 달라고 요청한 것이 아닙니다. 관리자 권한, 레지스트리 오염 및 제거 절차가 생기므로 범위 밖입니다.

## 구현 순서

### 1단계: 경로 획득 함수 교체

- `GetExplorerActiveTabPath()`의 주소창/클립보드 코드를 제거합니다.
- `GetExplorerCurrentFolder(explorerHwnd)` 형태의 COM 기반 함수를 추가합니다.
- Windows 11에서는 탭 HWND까지 매칭합니다.
- Windows 10/탭 없음에서는 최상위 HWND 매칭으로 동작합니다.
- COM 예외는 함수 내부에서 실패로 처리하고 빈 문자열을 반환합니다.

### 2단계: 실행 인자 단순화

- `wt.exe -d "<실제 경로>"` 조합을 `wt.exe -d .` + AHK `Run`의 작업 디렉터리 지정으로 교체합니다.
- `NormalizeDir()`와 `MakeWtDirArg()`는 실제 사용 필요성을 재검토하고, 불필요하면 제거합니다.
- 경로를 찾지 못했을 때의 인수 없는 `wt.exe` 폴백은 유지합니다.

### 3단계: 문서 정합성 수정

- README 영문/한글의 “작동 원리”를 실제 구현과 일치시킵니다.
- 주소창/클립보드를 건드리지 않는다는 점을 기능 및 보안 설명에 반영합니다.
- 가상 폴더에서는 기본 Terminal로 폴백한다는 점을 명시합니다.
- 메뉴 존재 여부와 무관하지만 `wt.exe`는 필요하다는 지원 경계를 명시합니다.

### 4단계: 검증

코드 수정 후 아래 항목을 실제 AHK v2 실행으로 검증합니다.

| 구분 | 검증 항목 | 기대 결과 |
|---|---|---|
| Windows 11 탭 | 왼쪽/오른쪽/중간 탭 각각 활성화 | 항상 활성 탭 폴더에서 열림 |
| 동일 창 다중 탭 | 최상위 HWND가 같은 여러 탭 | 비활성 탭 경로를 잘못 선택하지 않음 |
| 주소창 상태 | 주소창 보기, 편집 중, 자동완성 표시 중 | 주소창 입력과 무관하게 실제 현재 폴더에서 열림 |
| 포커스 | 파일 목록, 탐색 창, 주소창 | 경로 결과가 동일하고 기존 포커스를 바꾸지 않음 |
| 클립보드 | 텍스트/이미지/파일 복사 상태 | 단축키 실행 전후 내용이 바뀌지 않음 |
| Windows 10 | 탭 없는 Explorer | 현재 창 폴더에서 열림 |
| Desktop | `Progman`, `WorkerW` | 현재 사용자 Desktop에서 열림 |
| 드라이브 루트 | `C:\`, `D:\` | 별도 `\.` 보정 없이 루트에서 열림 |
| 문자 | 공백, 한글, 일본어, `&`, `%` 포함 경로 | 정확한 폴더에서 열림 |
| 네트워크 | 접근 가능한 UNC 경로 | 해당 UNC 폴더에서 열림 |
| 가상 폴더 | 홈, 내 PC, 검색, 휴지통 | 잘못된 경로를 넘기지 않고 기본 Terminal 폴백 |
| 메뉴 미등록 | Terminal 메뉴 숨김/차단 상태 | `wt.exe`가 있으면 정상 작동 |
| Terminal 창 상태 | 실행 중인 창 없음/있음 | Terminal 설정에 맞는 창/탭에서 같은 CWD 사용 |
| 실패 처리 | `wt.exe` 없음 | AHK 예외가 무시되지 않고 정책에 맞게 처리됨 |

Terminal 안에서는 PowerShell의 `Get-Location` 또는 CMD의 `cd`로 실제 시작 디렉터리를 확인합니다. PowerShell profile 등 사용자의 셸 초기화 스크립트가 시작 직후 다른 폴더로 이동할 수 있으므로, 필요하면 profile을 제외한 깨끗한 검증도 병행합니다.

## 완료 조건

- 단축키 처리에 `SendInput`, `Alt+D`, `Ctrl+C`, `ClipboardAll`, `ClipWait`, 고정 `Sleep`이 없습니다.
- Windows 11에서 활성 탭이 첫 번째 탭이 아니어도 정확한 폴더에서 열립니다.
- 주소창이 편집 중이어도 입력 내용을 실행 경로로 오인하지 않습니다.
- 클립보드와 Explorer 포커스를 변경하지 않습니다.
- 드라이브 루트, Unicode 경로 및 UNC 경로가 동작합니다.
- Terminal 컨텍스트 메뉴 또는 관련 레지스트리 등록이 없어도 `wt.exe`가 있으면 동작합니다.
- 가상 폴더나 COM 조회 실패 시 비활성 탭 경로를 임의로 선택하지 않습니다.
- README 영문/한글 설명이 실제 구현과 일치합니다.

## 리스크와 블로킹 포인트

### `ShellTabWindowClass`는 공개 호환성 계약이 아님

Windows 11 Explorer의 탭 HWND 클래스와 자식 순서는 문서화된 장기 API가 아닙니다. 따라서 미래 Explorer 업데이트에서 변경될 가능성은 남습니다.

하지만 주소창 키 입력 방식보다 영향 범위가 훨씬 작습니다.

- Explorer UI에 키를 보내지 않습니다.
- 주소창 표시 형식과 현지화에 의존하지 않습니다.
- 클립보드 타이밍에 의존하지 않습니다.
- 경로 값 자체는 `Shell.Application`의 폴더 객체에서 받습니다.

실제 구현 전에 현재 Windows 11 버전에서 `ShellTabWindowClass1`과 `IShellBrowser::GetWindow`의 대응을 AHK v2로 한 번 더 검증하고, 검증 실패 시 잘못된 탭을 고르지 않는 폴백을 유지해야 합니다.

### 완전한 “공식 API만 사용”은 AHK 단일 파일 범위를 키움

공식 셸 확장처럼 Explorer가 직접 `IObjectWithSite`를 주는 환경에서는 현재 `IFolderView`를 바로 얻을 수 있습니다. 외부 단축키 프로그램은 Explorer가 제공한 site 안에서 실행되는 셸 확장이 아니므로, 동일한 객체 연결을 그대로 받을 수 없습니다.

네이티브 C++ 셸 통합 도우미를 추가하면 공식 인터페이스를 더 직접적으로 사용할 수 있지만, 단일 AHK 파일이라는 저장소의 장점을 잃고 빌드/배포 복잡도가 크게 증가합니다. 현재 요구에는 권장하지 않습니다.

### “메뉴와 완전히 같은 내부 호출”과 “메뉴 없는 PC”는 동시에 만족할 수 없음

메뉴의 COM 객체를 그대로 호출하면 그 객체가 없는 PC에서는 실패합니다. 따라서 내부 구현의 완전한 동일성이 아니라, 사용자 관점의 결과 및 Terminal 시작 계약의 동등성을 목표로 해야 합니다.

## 최종 권고

다음 구현 단계에서는 기존 주소창/클립보드 경로를 제거하고, **Explorer 활성 탭 HWND 매칭 + `Folder.Self.Path` + `Run "wt.exe -d .", path`** 조합으로 교체하는 것이 가장 적절합니다.

이 방식은 요청한 “우클릭을 시뮬레이트하지 않지만 `Windows 터미널에서 열기`와 같은 효과”를 내며, 해당 메뉴가 없는 PC에서도 `wt.exe`만 있으면 작동합니다.
