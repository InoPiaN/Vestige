# VESTIGE P1-G — 캐릭터 생성 위치·건물 충돌·제1장 동선 Godot QA

2026-11-22 · QA 브랜치: `qa/chapter1-p1g-navigation-interactions`
**실제 성공 실행:** https://github.com/InoPiaN/Vestige/actions/runs/45010353735
**GitHub Actions 원본 로그:** https://github.com/InoPiaN/Vestige/actions/runs/45010353735/artifacts/14750025601

## 범위 및 아키텍처 영향

- 게임 코드 `desktop/main.gd`, `desktop/world.gd`, `desktop/world_store.gd` **변경하지 않음**.
- 새 `desktop/tests/test_chapter1_navigation_regression.gd`는 게임의 실제 `World.walkable`·`World.move`를 사용해 기본 시작 위치(9,9)에서 주요 제1장 장소로 접근하는 경로를 0.5타일 BFS로 산출하고 각 구간을 `World.move`로 재현한다.
- E01 이렌의 집 입구, E05 예배당 흔적, E06 표식, E07 장치 로그, E13 도구 파편의 도달성·실제 E 조사 반경을 검증한다. 늑대 전투 게이트만 명시적으로 해제된 테스트 fixture이며 실제 전투 통과를 나타내지 않는다.
- 브란·세라·카엘의 근접 접근과 T 대화 UI, 브란/대장간의 E 기존 시설 우선/T 대화 분리, 다른 지역의 동일 좌표에서 제1장 접근 금지, 월드 저장 v23 보존을 확인한다.
- 건물 충돌은 `World.walkable`의 대장간·서재·여관·집의 충돌 사각형 기준으로 확인한다. **픽셀 월드가 그리는 새 건물 스프라이트와 이 사각형이 정확히 일치하는지는 미검증**이다.
- `scripts/run_p1e_qa.py`에 새 테스트를 추가하고 `.github/workflows/chapter1-p1e-qa.yml`의 자동 실행 브랜치를 확장했다.

## 실제 검증 결과

- GitHub Actions: **PASS** (Ubuntu 24.04 / Godot 4.5.1)
- `p1e-report.json`: **9/9 검사 묶음 PASS** (기존 전체 규칙 1 + Chapter I 테스트 8), FAIL 0.
- 기존 `verify_rules.py`: **38개 Godot 테스트 스크립트 / 937개 PASS 라벨 / FAILURES []**. Chapter I 테스트 8개도 포함하므로 별도 8개 결과와 중복 합산하지 않음.
- 새 `test_chapter1_navigation_regression.gd`: **43 PASS / 0 FAIL**, 기본 생성 지점·5개 조사 지점·3 NPC·건물 충돌·E/T 우선/지역 격리/저장 검증.
- P1-F 실제 ENet: `p1f-report.json` **PASS**, fixture 생성, A/B 두 클라이언트, A 동일 캐릭터 재접속. Server/client `SCRIPT ERROR`, `Unable to send packet` 검출 0. 서버 종료 code -15는 QA 실행기의 의도적 SIGTERM으로, graceful 종료 검증은 아님.

## 테스트가 보장하지 않는 범위

1. macOS 실기 GUI 렌더링과 손으로 키보드 조작한 동작·프레임률은 **미실행**. CI는 Ubuntu headless Godot.
2. **신규로 그린 집의 시각적 외곽선**이 `World.walkable` 충돌 사각형과 정확히 맞는지 미검증. 과거 보고된 '집을 만들면서 시작 위치가 겹쳐 이동 불가' 현상이 모든 다른 로컬 브랜치/스태시에서 재현되지 않는다고 단정할 수 없음. 현재 G 기반 기본 시작 좌표(9,9)는 walkable이고 World.move로 이동됨.
3. 사용자 Mac 로컬 스태시 `local-main-world-before-evidence-board`의 미반영 변경은 QA 브랜치에 자동 적용하지 않았다. 사용자 작업 트리·원본 저장 파일 미접촉.
4. 실제 플레이에서 늑대 전투, F 유품 조사 키, 내비게이션 표지/아이콘, 화면 가림, 메모리 UI 가독성까지 보장하지 않는다.
5. 데이터 형식/서사 미확정 사항과 운영 인증·지연 네트워크·종료 레이스 검증은 별도 작업.

## Codex 또는 Mac 작업자 수동 QA 체크리스트

1. `git status --short --branch`로 로컬 미커밋 변경·스태시 확인. 원본 게임 저장 백업 후 별도 worktree에서 `qa/chapter1-p1g-navigation-interactions` 확인.
2. Mac Godot 4.5.1에서 새 캐릭터 생성 후 **키를 누르기 전** 최초 위치(9,9)와 화면에 그려지는 집/울타리/스프라이트가 겹치지 않는지 확인. W/A/S/D 첫 이동·각 방향 3타일 이상 이동·벽 충돌 후 반대방향 탈출을 영상/스크린샷으로 기록.
3. 이렌 집 입구 책장 E → N 수첩, 예배당 석판·표식·로그·도구 파편 접근. 실제 늑대 전투 상태에서 조사 잠금과 전투 후 해제 확인.
4. 대장간 E 이용 + 브란 T 대화, 서재 E 이용 + 세라 T 대화, 카엘 E/T 대화, 대화 중 이동·공격·ESC/N 우선순위 확인.
5. F 사망 사건 조사, G 유품, I 가방, L 의뢰, M 지도, K 기술, B 창고 및 상호 충돌 검사.
6. 저장→종료→재접속 후 스토리/증거/추론의 출처·순서 보존. 원본 `user://single-world.json`에 테스트용 수정 금지.
7. 발견된 충돌/접근 불가 좌표를 플레이어/건물의 월드 좌표·스크린샷·브랜치/커밋·재현 순서와 함께 `docs/handoffs/`에 남김.

## 남은 결정

- 시각 건축물과 실제 월드 충돌 판정의 경계 일치 여부는 Mac 실기 확인 후 좁은 별도 패치로 결정.
- `main` 병합은 아직 승인/실행하지 않았다. 테스트 통과가 기능 브랜치 병합 승인 자체는 아니다.
