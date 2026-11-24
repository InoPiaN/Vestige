# Core P1 준비: 회귀 테스트 파일 격리
2026-11-23 · 브랜치 feature/core-modular-architecture · 이전 기준 9f1076c.

## 완료한 변경
기존 테스트 21개의 `/tmp/...` 리터럴을 테스트 전용 `TestPaths.path()`로 교체했다. 테스트 기대값·행동·검증 조건은 변경하지 않았다.
새 helper는 실행 환경의 VESTIGE_TEST_ROOT 아래에 PID와 시작 tick으로 구분되는 디렉터리를 만든다. 같은 프로세스에서는 동일 파일명이 같은 경로를 가리켜 저장/복원·백업 검사를 유지한다. runner 없이 직접 실행하면 OS 임시 디렉터리 아래에서 동일한 격리를 적용한다.
verify_rules.py는 실행마다 tempfile.mkdtemp로 고유 루트를 생성하고 자식 프로세스에 전달한다. Godot 로그와 stdout/stderr도 해당 실행 루트로 분리한다. timeout에서도 출력이 남으며 종료 코드/SCRIPT ERROR 검사는 유지한다. 실행 시작 시 ARTIFACTS 경로를 출력한다.
실패 조사와 재현을 위해 임시 산출물은 자동 삭제하지 않는다. 사용자 저장과 이전 작업 fixture를 이동·수정·삭제하지 않는다. 전체 기존 `/tmp` 파일 정리 명령을 사용하지 말 것.

## 검증
- 격리 후 전체 규칙 999 PASS, 실패0.
- 두 runner를 동시에 시작하여 각각 999 PASS, 실패0. 실행 루트·프로세스별 fixture·로그 경로가 분리되었음을 확인.
- 기존 테스트를 역변환해 이전 HEAD와 비교: 테스트 조건 변경 없음.
- Core/게임 코드/main/world/store/RPC 변경 없음. 이번은 하네스 단계로 ENet/실제 GUI를 다시 실행하지 않았다.
- 결과: docs/architecture/validation/isolation-*.txt 및 isolation-scope.json.

## 다음 어댑터 범위 (설계 확정, 아직 미구현)
P1-B 첫 대상은 제1장 증거 상호작용 한 경로다. 기존 main.interact → perform/command → Chapter1.inspect → Investigation.inspect를 재사용한다.

1. **읽기 투영**: actor의 생존·직접 조종·room을 확인한 뒤 nearby 증거 ID와 사용 가능 여부만 복사 반환한다. prepare/ensure를 호출해 조회가 상태를 변경하지 않도록 한다. 타인 story나 미발견 증거의 fact/inference를 반환하지 않는다.
2. **명령 실행**: 신뢰된 싱글/서버 호출자가 확정한 actor ID를 받는다. 클라이언트 payload의 actor/life/권한을 신뢰하지 않는다. 서버 main이 기존 peers[remote_sender_id]를 해석하는 경계는 유지한다. 실행 시 생애·위치·생존·offline·지역을 다시 검증하고 기존 inspect를 호출한다.
3. **결과**: UI용 메시지와 이번에 새 증거가 기록됐는지를 분리한다. 문자열 내용으로 성공을 추정하지 않는다. 중복/거절/늑대 차단은 성공 이벤트를 만들지 않는다.
4. **Core 연결 순서**: 먼저 기존 동작과 어댑터의 동등성 테스트. 다음에 composition root의 단일 호출 지점만 교체한다. Core에는 Chapter1 preload를 추가하지 않는다.
5. **저장 경계**: world.people[id].story가 유일한 영구 소유자다. 동일 증거를 Runtime에 복제해 이중 저장하지 않는다. Core 후속 이벤트는 저장 소유권/실패 원자성 정책이 결정되기 전 붙이지 않는다. v23·RPC 인자는 유지한다.
6. **비활성화/롤백**: 기존 검사 경로로 복귀하는 단일 구성 지점을 둔다. 증거/이력 데이터는 지우지 않는다. 비활성화 시점의 UI 후보와 실행 시점 조건을 재검증한다.

## 완료 조건과 위험
검사 대상: 싱글/서버 동일 결과, 미등록 actor·죽음·offline·타지역·거리·늑대·중복·생애 변경·조회 무변이·개인 정보 비공개. 연결 후에는 기존 E 시설/조사 우선순위, T 대화, 모달, ENet 두 클라이언트 회귀를 수행한다.
저장 실패 후 이미 변이한 상태/이벤트를 어떻게 처리할지는 기존 world.save_world 계약과 함께 해결해야 한다. 이 문제를 건너뛰어 성공 이벤트를 발행하지 않는다. 실제 모듈 재접속/서버 재시작 검증은 여전히 P1-C/P2 미착수다.

## 운영 상태
P0 검증 완료, P1-A 독립 계약 검증 완료, 테스트 격리 검증 완료, P1-B 어댑터 구현 미착수. 로컬 커밋만 수행하며 push/PR/main 병합 없음. 새 실행본 제작·사용자 저장 변경 없음.
