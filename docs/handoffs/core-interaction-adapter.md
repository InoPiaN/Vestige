# P1-B 제1장 증거 상호작용 어댑터
2026-11-23. 기준55f1e14, feature/core-modular-architecture. 로컬 커밋만 수행.

## 구현·검증 완료 범위
main의 싱글 perform과 서버 command가 공통 inspect_chapter1 구성 지점을 거친다. 서버 actor는 기존 peers[remote_sender_id]에서 결정하며 클라이언트가 지정하지 않는다. 기존 RPC 인자·속도 제한·저장 위치·snapshot 호출 순서를 유지한다.
새 story/chapter1_interaction_adapter는 콘텐츠 계층이다. Core는 이를 참조하지 않는다. candidate는 prepare/ensure 없이 대상 ID·수집 가능 여부만 반환하고 세계 상태를 수정하지 않는다. 사실·추정·다른 인물 기록은 반환하지 않는다. E 입력은 후보의 can_collect가 false여도 기존처럼 실행해 중복/늑대 안내 메시지를 유지한다.
execute는 신뢰된 실행 역할(single/server), actor, expected_life를 확인하고 기존 Bridge.inspect를 호출한다. 결과는 message와 recorded이며, recorded는 증거 유무의 전후 비교다. 메시지 문자열을 파싱하지 않는다. Bridge가 거절 시 수행하던 초기 상태 보완도 동등성 보존을 위해 유지했다. 조회 무변이와 명령 거절 무변이는 서로 다른 계약이다.
chapter1_interaction_adapter_enabled=false이면 기존 호출 경로로 돌아간다. 이는 콘텐츠 자체 비활성화가 아니라 어댑터 이관의 로컬 롤백 스위치다. 데이터 삭제나 저장 포맷 변화는 없다.

## 변경 파일·재사용
- desktop/main.gd: preload/로컬 스위치, 공통 실행 경계, 대상 조회 교체.
- desktop/story/chapter1_interaction_adapter.gd: 신규 콘텐츠 어댑터.
- desktop/tests/test_chapter1_interaction_adapter.gd: 신규32개 검사.
- 문서: 이 인수인계, MODULE_CONTRACTS/DEPENDENCY_MAP/DEVELOPMENT_ROADMAP/CODEX_HANDOFF 및 adapter 검증 기록.
기존 Chapter1 bridge/investigation/dialogue, world/store, Core Runtime, 조사 데이터/정본은 수정하지 않았다. 새 Manager/Autoload/저장 데이터 복제 없음.

## 검증 결과
Godot4.5.1에서 전체 규칙1031 PASS(기존999+신규32), 실패0. 테스트 중복 설정 제거 후 해당32개를 재실행해 통과했다.
성공/죽음/offline/타지역/거리/늑대/알 수 없는 대상/중복 각각에 대해 기존 Bridge와 전체 월드 상태·메시지 동등성, 싱글/서버 결과 동등성, 다른 인물의 상태 보존을 검사했다. 조회 무변이·제한된 투영·클라이언트 거부·생애 불일치·실행 시 지역 재검증·롤백도 검사했다.
전체 runner에는 기존 키보드 모달/E/T/N·탐색·시설·저장 회귀가 포함된다. 이는 헤드리스 자동 검사이며 이번 실제 GUI 조작은 미실행이다.
실제 ENet 서버+primary/observer+동일 생애 재접속 PASS, script_error/packet_error 없음. 서버 -15는 하네스 정리 종료다. 서버 재시작 지속성은 미검증이다.
검증 파일: docs/architecture/validation/adapter-rules.txt, adapter-focused.txt, adapter-enet.json.

## 권한·저장 제한
expected_life 불일치 거부는 어댑터 계약 단위에서 검증했다. 현재 main은 요청 실행 시 현재 life를 전달하며 기존 RPC에는 요청 시점 life가 없다. 따라서 네트워크에서 지연된 이전 생애 명령을 구분하는 기능을 구현했다고 주장하지 않는다. 향후 프로토콜/세션 세대 계약을 별도 설계해야 한다.
recorded는 메모리 상태만 의미한다. 현재 기존 코드는 변이 후 save_world를 호출하며 실패 시 이미 변이한 상태를 자동 롤백하지 않는다. 이번에는 이 동작을 보존했으며 Core Signal/지속성 성공 이벤트를 발행하지 않는다. 새로운 Runtime에 증거를 이중 저장하지 않는다.
후보 can_collect는 UI 참고 정보다. 실행 권한/거리/늑대 판정의 최종 소유자는 기존 Investigation 규칙이다. 새 증거 유형 추가 시 후보 표시와 규칙 일치 검사도 확장해야 한다.

## 남은 단계·다음 작업
P1-B의 한 상호작용 경로는 구현·자동 검증 완료. 공통 Interaction 전체와 P1 전체는 진행 중이다.
다음은 P1-C 저장 실패 처리 설계: 기존 save_world/checkpoint의 실패 경로를 조사하고, 메모리 변경과 영구 저장 완료를 구분하는 반환 계약·재시도·이벤트 발행 시점을 확정한다. v23 호환 fixture와 실패 주입 테스트를 먼저 준비하고 저장 포맷은 임의 변경하지 않는다.
그 뒤 실제 Core 테스트 모듈 등록·저장·재접속·서버 재시작 실험과 실제 플레이 검증을 진행한다. 사용자 저장·기존 스태시·다른 worktree 변경은 보존한다. 원격 push/PR/기본 브랜치 병합 및 빌드 배포 없음.
