# Core-first P0 / P1-A 인수인계
2026-11-23 · 이번 범위: **P0 검증 완료 / P1 진행 중 / P1-A 독립 계약 검증 완료**.

## 1. 브랜치와 커밋
- 작업 트리: `/Users/junheejang/Documents/Vestige/worktrees/core-modular-architecture`
- 브랜치: `feature/core-modular-architecture`. 원격 추적 해제. 원격 push/PR/기본 브랜치 병합 없음.
- 기준 `673dd1a` (qa/chapter1-p1i-macos-input). 안전 이식 `4a3a2af` 및 후속 입력·세션·조합·저장·QA를 이미 포함하므로 중복 이식하지 않았다.
- P0 로컬 커밋 `0d40d82`. P1 구현 커밋은 이 문서를 포함한 Git 이력에서 확인한다.
- 원본 f9c4a35와 `.venv-asset/`, 기존 스태시를 유지했다. 다른 worktree의 v24 미커밋 작업은 보존하며 채택하지 않았다.

## 2. 분석한 기존 구조
project→main scene→main Node. Autoload 없음. main이 입력·패널·ENet·대화 세션을, world가 시뮬레이션/행동을 조정한다. 개별 제작·생활·조사 규칙은 RefCounted 정적 함수다. v23 저장과 파일 교체/백업 경로가 존재한다.
`ARCHITECTURE.md` 기능 표와 `DEPENDENCY_MAP.md`, 정적 참조 JSON을 함께 읽는다. 정적 그래프는 동적 호출/Dictionary 상태 공유를 모두 설명하지 않는다.

## 3. 결합 문제
main의 UI/입력/네트워크 혼재, world의 중앙 prepare/act, store의 콘텐츠 전용 validator, 여러 모듈의 공유 Dictionary 변이가 주요 경계다. 기존 사망 사건 조사와 고정 제1장 조사는 별개 도메인이므로 파일을 덮어써 통합하지 않는다.
기존 테스트는 `/tmp` 파일명을 공유한다. 이전 WIP에서 생성한 v24 합성 fixture가 v23 쓰기 방어와 충돌해 4개 테스트가 timeout에 도달했다. 제한을 넓힌 실행에서도 동일하게 재현됐다. 상위 버전 보호를 완화하지 않았다.
해당 4개 테스트의 합성 파일과 .bak 총8개만 `/tmp/vestige-core-prior-fixtures-20261123/`로 이동 보관했다. 사용자 저장에는 접근/삭제하지 않았다. 테스트별 고유 디렉터리 지원은 후속 하네스 개선 과제다. 이 브랜치와 v24 작업의 테스트를 동시에 실행하지 말 것.

## 4. 구현한 계약
- GameModule: ID/의존성/버전/초기 상태/검증/reducer/활성·비활성 hook.
- ModuleRuntime: 등록 당시 메타데이터 고정, 의존 선등록, 활성 의존 보호, 비활성화 시 상태 보존, 역순 정리.
- 상태/이벤트 복사, JSON 값/깊이 검증, 성공 이벤트만 중복 기록, Signal 완료 통지와 재진입 방어.
- 독립 snapshot format1, 등록된 모듈 전체 검증 후 원자적 복원. 미래 버전·누락·중복 영수증 거부.
- 신뢰된 composition root가 정하는 single/server/client 실행 역할. client dispatch 거부는 실제 네트워크 인증 구현이 아니다.
- 모듈당1024개 처리 ID 한도. 한도 초과를 거부하며 조용히 과거 ID를 삭제하지 않는다. 실제 게임 채택 전에 체크포인트/저널 정책 필요.

## 5. 파일 변경
P0 필수 6개 문서와 `docs/architecture/dependency-baseline.json`. 기존 DEVELOPMENT_ROADMAP은 새 우선순위로 갱신하고 과거 기능 현황은 PROJECT_STATUS/handoffs에 유지.
P1 새 코드: `desktop/core/game_module.gd`, `desktop/core/module_runtime.gd`.
신규 모듈 추가 실험: `desktop/tests/fixtures/observation_module.gd`, `desktop/tests/test_core_runtime.gd`.
보고/검증: 이 문서, CODEX_HANDOFF 상단 안내, `docs/architecture/validation/*`.
기존 desktop 추적 파일 변경은 **0개**. main/world/store/investigation/씬/RPC/기존 테스트는 수정하지 않았다.

## 6. 재사용
Godot Node/RefCounted/Signal/JSON/FileAccess와 기존 테스트 runner 및 ENet 하네스를 사용했다. 새로운 이벤트 버스/ECS/Autoload를 만들지 않았다. 기존 Chapter1 bridge·저장 validator·패널·NPC·제작 시스템은 기준 브랜치 그대로 재사용한다.

## 7. 실행한 검사
Godot4.5.1. 명령:
```
GODOT_BIN=/Users/junheejang/Documents/Vestige/.tools/godot/Godot.app/Contents/MacOS/Godot python3 scripts/verify_rules.py
python3 scripts/run_p1f_enet.py --godot /Users/junheejang/Documents/Vestige/.tools/godot/Godot.app/Contents/MacOS/Godot --logs /tmp/vestige-core-enet-baseline
```
- 기존 규칙 PASS954 + 신규 Core PASS45 = **999 PASS, 실패0**. 초기 fixture 충돌 실행은 별도로 남기며 통과 횟수에 합산하지 않는다.
- Core: 등록/의존, 중복 활성/비활성, 복사 상태/snapshot, 이벤트/Signal 해제·재진입, 거절 후 재시도, 디스크 JSON 복원·복원 원자성, 버전/참조/권한/중복/한도, tree exit/정리.
- ENet: 실제 서버+primary/observer+동일 생애 재접속 PASS. 서버 종료 코드 -15는 하네스 정리. script_error/packet_error 없음. **서버 재시작 후 지속성 테스트는 아님**.
- 신규 Core는 실제 게임에서 미사용이므로 ENet 결과는 기존 게임 경로의 검사다. 독립 single/server 비교는 실제 RPC를 시험한 결과가 아니다.
- Godot headless의 macOS CA certificate 경고가 있었으나 규칙 실패는 아님. 이번에 실제 GUI 조작·최종 빌드/Steam 검증은 실행하지 않았다.
- git diff --check 및 기존 desktop 파일 불변, Core→콘텐츠 역참조 없음 검사.

## 8. 남은 문제
Core를 실제 게임·저장·멀티 snapshot에 연결하지 않았다. P1 전체 완료나 신규 콘텐츠의 실제 SP/MP 재접속 확장성 증명으로 간주하지 말 것.
저장 v23과 새 모듈 envelope의 배치/호환·공개 범위, long-running dedup 정책, 서버 권한 어댑터는 아직 설계/검증 필요. 다른 WIP에서 관찰한 ENet 종료 오류는 해당 트리에 남아 있으며 이번 기준에서 재현되지 않은 것과 구분한다.
DEC-02AW까지라는 요구와 달리 확인한 디자인 tip ad81304에는 AC까지/AD 대기가 있다. AD~AW 정본 확보 전 해당 내용은 보류한다. 카엘의 책임·이렌 최후를 임의 확정하지 않았다.

## 9. 다음 작업
1. 테스트 임시 파일 경로를 실행별로 분리해 브랜치간 충돌 제거.
2. 기존 world에서 상호작용 읽기 투영/명령 어댑터 하나를 정의(P1-B). peer→actor/life/room 권한은 서버에서 검증.
3. v23 호환·모듈 off 상태 보존·저장/공개 snapshot 정책을 먼저 정한 후 composition root 연결(P1-C).
4. 임시 관찰 오브젝트 모듈을 실제 게임에 등록하고 싱글/두 클라이언트/재접속/서버 재시작까지 검사(P2). Core 변경이 필요한 지점을 명시.
5. 저장 좌표와 건물 겹침, E/T/N/ESC·모달·이동·전투를 실제 조작 검증. 이후 NPC→생활→조사 순서로 작은 이관.
