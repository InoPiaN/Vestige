# VESTIGE P1-H — 실제 화면/충돌 시각 QA 및 조작 UI 점검

기준: `qa/chapter1-p1g-navigation-interactions`
작업: `qa/chapter1-p1h-visual-collision`
날짜: 2026-11-22

## 1. 실제 실행 증거

**최종 검증 커밋:** `1d5a440b6509fd9b3112688548684e276a3f7fa3`
**성공 GitHub Actions:** https://github.com/InoPiaN/Vestige/actions/runs/45013001030
**PNG + JSON + ENet 로그:** https://github.com/InoPiaN/Vestige/actions/runs/45013001030/artifacts/14751021141

- Ubuntu 24.04 / Godot 4.5.1.stable.official / Xvfb 가상 디스플레이.
- 기존 Godot 규칙: **38개 스크립트/937 PASS 라벨/FAILURES []**.
- 제1장 독립 QA: **8개 스크립트** 전부 통과. 게임 규칙 937에 포함되므로 합계 중복 주의.
- P1-E 실행기: **9/9 검사 묶음 PASS**.
- P1-F 실 ENet: 실제 서버+A/B+같은 생애 재접속 **PASS**, 각 클라이언트 exit 0 및 `SCRIPT ERROR` / `Unable to send packet` 검출 0. 서버 종료는 QA runner의 의도적 SIGTERM, graceful 종료는 미검증.
- P1-H 별도 화면 검사: **실제 1280x800 PNG 6장 생성 PASS**. `capture_p1h_visual.gd`로 viewport frame await 후 저장, PNG 파일 존재/차원/저장 성공 단언.
- QA 캡처에서 한글 미지원 문제가 보였으나 GitHub Actions Ubuntu의 `fonts-noto-cjk` 설치 후 동일 스크립트에서 **한국어 표시 정상**을 화면 확인.
- GUI 렌더 캡처는 `xvfb-run`을 사용한 별도 단계이며 기존 headless `verify_rules.py`에 섞지 않음. 초판 CI 45012314940의 visual test headless hang은 테스트 분리로 해결.

## 2. 캡처 시나리오

| 파일 | 확인 내용 |
|---|---|
| `01-spawn-actual.png` | 실제 시작 마을 화면, 기본 인물(9,9), 지도와 건물 배치, HUD 표시 |
| `02-spawn-collision-overlay.png` | **붉은 사각형=World.walkable 실제 건물 충돌**; 청록 십자=초기 인물 위치; 노랑/파랑 원=증거·NPC 상호작용 거리 |
| `03-iren-house-e01.png` | 이렌의 일기 E01 근처, 일상 UI와 조사 안내 |
| `04-notebook.png` | 발견한 일기와 추론이 구분되는 N 수첩 UI |
| `05-evidence-board.png` | 제1장 증거 조합 모달과 발견 증거 목록 |
| `06-sera-dialogue.png` | 세라 NPC의 현재 대화·선택지 UI |

스크린샷은 GitHub Actions 아티팩트에 14일 보존. 이 브랜치의 저장 파일이나 실제 게임 월드에 스크린샷을 추가하지 않음.

## 3. 실제 발견 사항

### UI-01 한글 렌더

초판 Ubuntu Xvfb 렌더 화면에서는 한국어가 네모/깨진 글자로 표시됐다. 기존 `main.gd` UI는 Apple SD Gothic Neo·Malgun Gothic·Noto Sans CJK KR 계열의 시스템 글꼴을 요청한다. 해당 Ubuntu에 한글 폰트가 없었던 것이 원인. **CI 렌더 환경에 Noto CJK 글꼴 설치**로 해결. 게임 글꼴 자산이나 Mac/Windows 동작은 변경하지 않았다.

### UI-02 조사 단축키의 낮은 발견성

기존 우측 HUD 도움말에는 `N 조사 수첩` 및 `F 사망 사건 조사` 설명이 누락되어 있었다.
`desktop/main.gd`의 오른쪽 도움말 텍스트만 최소 수정하여 `WASD/E/T/N/SPACE/SHIFT/F/J/L/M/Q`를 표시했다. 5줄/13px로 배치하고 별도 시각 캡처 테스트에서 `N 조사 수첩` 및 `F 사망 조사`가 실제 Label에 존재하는지 검사했다. **기존 키 동작은 변경하지 않았다.**

### COLLISION-01 건물 그림과 실제 이동 충돌 영역 차이

- `pixel_world.gd`의 `house(x,y,type)`는 처마·지붕·벽 그림이 중심 좌표 기준 좌우 약 28px, 위 약 45px 이상까지 차지한다.
- `world.gd`의 `World.walkable`은 forge/library/inn/home 중심으로 `Rect2(x-1,y-1.5,2,1.9)` 타일 영역만 이동 불가로 취급한다. 픽셀 환산 시 가로 32px, 세로 30.4px.
- 결과적으로 **지붕/건물 그림이 존재하지만 이동 가능한 영역이 일부 있다**. 이는 의도된 지붕 오버행일 수 있으므로 화면만으로 결함 확정·충돌 확장하지 않았다. 스폰(9,9) 자체는 기존 P1-G에서 World.move로 이동 가능하고 본 P1-H 실제 화면에서 시각적 위치도 확인됐다.
- 사용자 과거 로컬 신규 주택 중첩 사례는 **이 QA 브랜치와 별개 로컬 스태시/월드**의 실제 집 배치 여부 미확인. 이 브랜치의 테스트 통과를 로컬 전체 문제 해결로 주장하지 않는다.

## 4. 변경 목록

| 파일 | 종류/영향 |
|---|---|
| `desktop/main.gd` | **도움말 텍스트 1줄 변경**: N/F 표기, 다섯 줄 조정. 세계 데이터/전투/충돌/상호작용 코드 미변경 |
| `desktop/tests/p1h_visual_collision_overlay.gd` | 테스트에서만 불러오는 충돌·증거/NPC 거리 오버레이 |
| `desktop/tests/capture_p1h_visual.gd` | UI·게임 viewport 캡처 6장 + HUD N/F 확인. 기존 headless 규칙 자동 탐색에서 제외 |
| `.github/workflows/chapter1-p1e-qa.yml` | P1-H 브랜치 실행, Korean fonts + Xvfb 시각 검증, 아티팩트 저장 |
| `docs/handoffs/chapter1-p1h-visual-collision-report.md` | 본 문서 |

새로운 사용자 저장 파일 schema, 장비/전투/의뢰/집 충돌, 권한/RPC, 서사 정본은 변경하지 않았다. 게임 기본 브랜치 `main` 병합·배포 없음.

## 5. Codex와 Mac 수동 QA 인계

1. 원격 `qa/chapter1-p1h-visual-collision` 및 사용자 로컬 worktree/stash의 차이를 확인하고 사용자 저장 파일을 백업.
2. Mac Godot 4.5.1에서 실제 표시·키보드 조작: 새 세계 스폰, 세라 대화, N 수첩, 사건 재구성, 책장/집 입구, 건물 충돌/탈출.
3. `02-spawn-collision-overlay.png`를 비교해 실제 새 집의 렌더 배치와 콜라이더를 특정. 시각적 지붕과 몸체의 충돌 범위를 의도대로 정할지 사용자 결정 필요. 기존 마을 접근성을 깨뜨리는 일괄 collider 확대 금지.
4. UI에서 Korean fonts, N/F/E/T 버튼 설명, 1280x800 창 해상도, 작은 화면·배율, 대화 모달 수용성을 수동 확인.
5. 별도 엔진 실행/통신: `python3 scripts/run_p1e_qa.py`, `python3 scripts/run_p1f_enet.py`; 현재 CI 성과는 GitHub Ubuntu Xvfb 한정.
6. 본 브랜치가 `main`과 다른 계열임을 인지하고 main 병합은 사용자 승인 전 진행하지 말 것.

## 상태

- **implemented:** 시각 QA/폰트 환경/HUD 단축키 발견성 개선.
- **verified:** 동일 커밋의 CI에서 기존 937 검사 기록, 9/9 QA, ENet A/B/재접속, 한글 표시 가능한 PNG 6장.
- **not verified:** 사용자의 Mac 실제 GUI 조작, 로컬 미병합 집 중첩/충돌, graceful ENet 종료 경쟁 상태.
