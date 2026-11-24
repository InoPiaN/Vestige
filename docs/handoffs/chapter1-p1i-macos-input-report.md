# VESTIGE P1-I — macOS Godot QA / 키보드 모달 충돌 해결

기준: `qa/chapter1-p1h-visual-collision`
작업 브랜치: `qa/chapter1-p1i-macos-input`
일자: 2026-11-22

## 목적 및 변경 영향

현재 집 그림/물리 충돌 판정은 무단으로 변경하지 않고 실제 Mac 환경에서 게임 규칙·키보드 입력·ENet 접속 검증을 실행한다. 실제 이슈로 확인된 **N 조사 수첩 위에 L/M/I 다른 UI가 겹쳐 열리는 버그**만 최소 패치한다.

### 변경 파일

| 파일 | 변경 내용 |
|---|---|
| `desktop/main.gd` | `panel.visible`일 때 다른 모달 단축키 차단. 기존 사망 사건 조사 내 숫자 1/2 지목 선택은 이전처럼 처리. ESC/N·대화 세션 동작 보존 |
| `desktop/tests/test_chapter1_keyboard_modals.gd` | 실제 `InputEventKey` 객체를 `_unhandled_key_input`에 전달해 E/T/N/L/M/I/ESC, 수첩/보드, 대화·대장간 충돌, 타 지역 NPC 권한 점검 |
| `.github/workflows/chapter1-p1e-qa.yml` | Linux 회귀 CI에 QA 브랜치 추가 |
| `.github/workflows/chapter1-p1i-macos.yml` | **신규** macos-15 러너에서 공식 macOS universal Godot 4.5.1을 실행, 기존 게임+Chapter I 테스트와 서버/클라이언트 실제 ENet 재접속 검사, JSON·로그 아티팩트 업로드 |

수정하지 않은 기능: `world.gd`, `world_store.gd`, `pixel_world.gd` 렌더링과 collision, 기존 게임 데이터 저장, `main` 및 운영 배포.

## 재현된 실패와 수정

- **최초 Linux 실패**: <https://github.com/InoPiaN/Vestige/actions/runs/45013391445>의 `test_chapter1_keyboard_modals.gd` 14 PASS / 3 FAIL. 열린 수첩에서 L 요청, M 지도, I 소지품이 겹쳐 표시됨. 기존 코드에서 모달 입력 차단 조건을 L/M/I 처리보다 뒤에 뒀기 때문.
- **수정**: `main.gd`의 E/T/N 키 처리 경로는 유지하면서 `chapter1_board` 다음에 `panel.visible` 단독 guard 추가. 단, 사망 사건 조사 UI가 사용하는 숫자 1/2 `identify`는 guard 안에서 계속 허용. 기존의 뒤쪽 중복 처리 구문 제거.
- **실행 검증 결과**: 같은 `07974da7` 코드에서 Linux/Native Mac 두 환경 모두 PASS. 테스트 단언을 삭제·약화하지 않았다.

## 실제 성공 증거

| 환경 | GitHub Actions | 검증 내용 |
|---|---|---|
| **macOS 15** / 공식 Godot 4.5.1 universal | <https://github.com/InoPiaN/Vestige/actions/runs/45013495217> | **9/9 검사 묶음 PASS**, 기존 규칙 스크립트에서 **TOTAL 954 FAILURES []**. ENet 임시 월드 생성, A/B 실 클라이언트 및 동일 캐릭터 재접속 **PASS**. Server/client `SCRIPT ERROR`와 `Unable to send packet` 미검출 |
| **Ubuntu 24.04** / 공식 Godot 4.5.1 | <https://github.com/InoPiaN/Vestige/actions/runs/45013495180> | 기존 G+Chapter I 9/9 검사 묶음 PASS, 가상 화면 캡처 및 ENet 실 클라이언트 검사 PASS |
| macOS 원문 로그 | <https://github.com/InoPiaN/Vestige/actions/runs/45013495217> 아티팩트 | `p1e-report.json`, `p1f-report.json`, `existing_game_rules.log`, 클라이언트·서버 로그 |
| Linux 원문 로그 | <https://github.com/InoPiaN/Vestige/actions/runs/45013495180> 아티팩트 | 동일 QA 리포트 및 PNG 캡처 |

954는 Godot rule runner의 모든 `PASS:` 라벨 수이며, Chapter I 8개 스크립트의 개별 결과는 여기에 포함된다. 9/9는 기존 규칙 묶음 1 + Chapter I 독립 실행 8 묶음의 통과 횟수다. **숫자를 중복 합산하지 않는다.**

ENet 서버 exit `-15`는 테스트 실행기 종료 단계의 **의도적인 SIGTERM**이다. graceful shutdown/연결 직전 경쟁 상태를 전부 확인했다는 뜻이 아니다.

## 여전히 미검증 / 결정 필요

1. 이 성공은 **GitHub 호스티드 Mac 러너의 headless 실행**이며, 사용자 MacBook의 실시간 GUI 렌더, 실제 키보드/마우스 입력 지연, 화면 배율, 스프라이트-충돌 외곽선 일치의 실기 플레이 확인은 아니다.
2. 기존 사용자의 로컬 스태시 및 새 집 배치가 현재 작업 브랜치에 포함되었는지 **미확인**. 로컬 미커밋 변경·원본 세이브를 보호해야 한다.
3. 건물 지붕의 시각적 오버행을 콜라이더로 취급할지 장면 깊이 표현으로 남길지 사용자 결정 전에는 `World.walkable`을 확대하지 않는다.
4. 엔딩/정본 사건 진실, 운영 멀티 인증·보안, 클라우드 배포는 범위 밖.
5. `main`에 병합하지 않았고 별도 QA 브랜치에서만 원격 커밋.

## Codex 다음 작업

- `qa/chapter1-p1i-macos-input`를 별도 worktree에서 열고 `desktop/main.gd` 수정의 모달 입력 우선순위를 점검.
- Mac 실기에서 기존 데이터가 아닌 백업한 테스트 저장을 사용해 **첫 시작 위치 (9,9)**, E01 이렌 집 입구, 예배당, 대장간 E/브란 T, 세라 대화 N/ESC/L/M/I 조작을 수동 재현.
- 기존 로컬 충돌 문제가 계속되면 사용자 개인 스태시를 임의 pop 하지 말고, 스태시의 월드/건물 좌표와 `World.walkable`의 차이를 분석해 별도 좁은 수정 브랜치 제안.
- G 기본 회귀와 ENet 실행 결과/본 문서를 `docs/ai-collaboration-governance`의 현재 작업 규칙에 따라 업데이트.
