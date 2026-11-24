# P1-C 미저장 상태·재시도 구현
2026-11-24 · feature/core-modular-architecture · 기준305c217.

## 구현
content-free core/save_checkpoint.gd가 저장 경로별 pending 상태를 소유한다. main이 기존 Rules.save_world Callable을 주입한다. single/server만 저장할 수 있고 client는 writer 호출 전 거부한다. bool 결과를 보존하며 실패 원인을 임의 분류하지 않는다. pending은 메모리에만 존재하며 v23에 필드를 추가하지 않는다.
main의 실행 중 월드 저장 호출을 checkpoint_current로 통일했다. 조사 외 자동 저장·대화·재구성·disconnect·종료·하루 진행의 저장도 동일 상태를 갱신한다. 원래 호출 시점·저장 내용은 유지한다. 이렇게 해야 다른 경로의 성공 후에도 실패 표시가 남지 않는다. 시작 전 demo opening 저장은 기존 성공 검사 그대로이며 실행 월드 서비스 범위 밖이다.
싱글 실패 시 지속적인 미저장 Label과 저장 재시도 Button을 표시한다. 재시도는 도메인 행동을 다시 실행하지 않고 현재 월드만 저장한다. 추가 행동의 결과도 현재 snapshot에 포함한다. 성공하면 안내/버튼을 숨긴다. 실패 시 자동 저장은 기존10초 주기로 계속 재시도하며, 종료 실패는 기존처럼 종료를 막고 조종 상태를 복원한다.
서버는 동일 pending 상태와 기존10초 자동 저장을 사용한다. 실패/복구 전이 때 기존 remote_message RPC로 접속자에게 안내한다. 실패 중 새 접속자에게도 알린다. 클라이언트의 수동 서버 저장 명령을 추가하지 않았다. 기존 RPC 인자와 snapshot/저장 형식 변경 없음.

## 범위와 재사용
신규: desktop/core/save_checkpoint.gd, desktop/tests/test_save_status.gd.
수정: desktop/main.gd, 관련 계약·로드맵·인수인계·검증 기록.
world.gd/world_store.gd/조사 규칙/ModuleRuntime은 그대로 재사용했다. Core는 콘텐츠·파일 경로를 preload하지 않는다. 영구 완료 이벤트, outbox, 새 저장 버전, 사용자 저장 이관은 도입하지 않았다.

## 검증
Godot4.5.1 전체1072 PASS(이전1058+신규14), 실패0. git diff --check 통과.
신규 검사: client writer 차단, 빈 월드 거부, 경로별 상태, 실제 .tmp 장애 후 UI 안내/버튼 표시, 버튼 Signal로 실패·성공 재시도, 추가 gold 변경과 증거/이벤트 보존, client 파일 불변, 서버 자동 저장 복구, 종료 실패 후 pending 유지·직접 조종 복원.
초기 테스트에서 SceneTree 상수의 Node 한정 누락과 _process 대신 실제 _physics_process를 호출해야 하는 오류를 수정했다. 게임 동작 검사 조건을 완화하지 않았다. 멈춘 해당 테스트 프로세스만 종료했다.
ENet 실제 서버+primary/observer+동일 생애 재접속 PASS. packet_error/script_error 없음. 서버 -15는 하네스 정리 종료다. ENet 하네스는 정상 저장 경로이며, 저장 실패·복구 안내가 네트워크 양쪽 화면에 실제 표시되는 실패 주입 시나리오는 아직 미검증이다.
UI는 실제 Godot 컨트롤의 visible 상태와 pressed Signal을 헤드리스로 검사했다. 실제 창의 배치/시각적 조작 QA는 미실행이다. 서버 재시작·전원 손실 내구성도 이번 완료 범위가 아니다.
로그: docs/architecture/validation/save-status-rules.txt 및 save-status-enet.json.

## 한계
pending은 마지막 저장 실패 여부이며 모든 프레임 변경을 추적하는 일반 dirty flag가 아니다. 성공 직후 진행된 시뮬레이션은 다음 기존 자동 저장 대상이다. pending을 영구 데이터와 혼동하지 않는다.
서버 안내는 기존 메시지 영역을 사용하므로 이후 메시지에 덮일 수 있다. 지속적인 클라이언트 배지/수동 서버 재시도는 이번에 추가하지 않았다. 세션 메타데이터 공개 계약이 필요한 후속 작업이다.
프로세스 강제 종료 시 미저장 메모리를 복구할 수 없다. 실패 자동 재시도10초는 기존 정책이며 오류 분류/지수 백오프는 미구현이다. callback은 신뢰된 composition root 전용이며 악성 플러그인 격리 API가 아니다.

## 다음 단계
1. 서버 저장 실패를 실제 ENet 두 클라이언트에 주입하여 실패/복구·재접속 안내 검증.
2. 실제 창에서 미저장 안내·버튼 배치·모달/입력 충돌 확인.
3. Core 테스트 모듈 snapshot 배치/저장 소유권과 서버 재시작 계약 설계. 영구 이벤트는 그 이후.

P1-C 최소 상태·재시도 구현 및 자동 검증 완료, P1 전체는 진행 중이다. 사용자 저장·스태시·다른 worktree는 보존했다. 이번 변경은 로컬 커밋이며 원격은 이전 승인된 b545155 상태다. 배포/PR/기본 브랜치 병합 없음.
