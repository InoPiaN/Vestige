# Module Contracts
2026-11-23 · P0에서 고정한 최소 P1 계약. 기존 API를 일괄 대체하지 않는다.

## 상태와 소유권
| 상태 | 현재 소유자 | 목표 경계/수명 |
|---|---|---|
| time/world/시장·채집 등 공동 상태 | world.gd와 각 규칙 | World 서비스, 월드 수명 |
| 인물 hp/장비/직업 | world.people[id], 관련 규칙 | Player/Gameplay 서비스, 생애별 |
| 개인 story/evidence/inferences | chapter1 규칙, people[id].story | Investigation/Content 소유, life별 |
| notebook/cases/유품 | 기존 investigation 관련 모듈 | History/Investigation, 생애 이후 보존과 공개 권한 분리 |
| session/request_id/peer | main.gd | Network/Session, 연결 수명; 저장하지 않음 |
| panel/선택/렌더 | UI Nodes | 로컬 화면 수명; 서버 상태 아님 |
| P1 실험 모듈 상태 | ModuleRuntime 내부, 모듈 ID별 | 독립 runtime 인스턴스. 기존 world와 아직 연결 없음 |

다른 모듈 내부 Dictionary를 수정하는 대신 공개 명령·반환 결과를 이용한다. 이번 Runtime은 상태를 deep copy해서 전달/반환한다. 기존 코드 전체가 이미 이 원칙을 따른다고 주장하지 않는다.

## P1 최소 인터페이스
GameModule: module_id(), dependencies(), state_version(), initial_state(), valid_state(state), reduce(state,event), on_enable(), on_disable().
ModuleRuntime:
- register_module(module): 고유 ID, 의존 모듈 선등록, 초기 상태 검증. 등록 시 자동 활성화하지 않음.
- enable_module(id): 의존 모듈 활성 요구. 중복 활성은 부작용 없음.
- disable_module(id): 활성 의존자가 있으면 거부. 상태/중복 처리 이력 보존.
- unregister_module(id): 비활성이고 참조 의존자가 없는 경우만. 제거는 명시적 상태 삭제이므로 일반 비활성화와 구분.
- dispatch(id,event): 신뢰된 single/server Runtime만 변이, 활성 모듈에 전달. client는 거절. 호출자가 payload에 권한 값을 넣어도 무시.
- state_for(id): 복사본만 반환.
- snapshot()/restore(data): 모듈 envelope 복사/검증. restore는 비활성 상태에서만 전체 검증 후 원자적으로 적용. 모르는 모듈/미래 포맷·다른 state_version은 거부; 데이터를 버리거나 자동 다운그레이드하지 않음.
- shutdown()/tree exit: 역순 비활성/정리. Signal 수신자는 Godot 객체 수명 또는 명시적 disconnect로 해제한다.

등록 시 ID·의존성·버전 메타데이터를 고정한다. 변경하려면 비활성화·등록 해제 후 새로 등록해야 한다. 모듈 코드는 신뢰된 프로그램 코드이며 악성 플러그인을 격리하는 sandbox가 아니다. JSON 깊이는64로 제한한다.
모듈 ID는 비어 있지 않은 영구 문자열, 버전은 양의 정수. 중복/자기 의존/누락 의존은 거부한다. 선등록 요구로 순환 의존을 만들지 않는다.

## 이벤트/Signal
event={id:String, type:String, payload:Dictionary}. 이것은 검증된 도메인 이벤트를 적용하기 위한 실험 계약이지 외부 RPC 패킷이 아니다. actor_id/life/location/권한 검증은 P2 어댑터가 실제 서버 상태로 확인해야 한다.
reduce는 자기 상태 복사본과 이벤트 복사본을 받아 {accepted:bool,state:Dictionary}를 반환한다. 거절/잘못된 결과는 기존 상태를 바꾸지 않는다. 외부 I/O·다른 모듈 호출은 reducer에서 하지 않는다.
적용 성공 후 event_committed(module_id,event_id,event_type) Signal을 발행한다. payload/내부 상태를 Signal로 공유하지 않아 수신자의 Dictionary 수정이 다른 수신자에게 전파되지 않는다. 별도 전역 이벤트 버스·Autoload는 만들지 않는다.
중복 키=(module_id,event.id). 성공한 ID만 저장하고 재전송은 거부한다. 실패는 재시도 가능. 1024개 한도에 도달하면 새 이벤트를 명시적으로 거절하며 과거 ID를 조용히 버리지 않는다. 장기 저널/체크포인트 압축은 P3 작업이다. Signal 수신 중 재진입 dispatch/생명주기 변이는 거절한다.

## 저장 envelope 및 제한
실험용 {format_version:1,modules:{module_id:{state_version:1,state:{...},processed_event_ids:[...]}}}.
유한 JSON 값만 허용하며 Object/Callable/Vector2/NaN/비문자열 key는 거부한다. 실제 월드 파일에 쓰지 않는다. disabled 모듈도 snapshot에 남는다. 상태 버전이 달라지면 모듈별 명시적 migrator를 먼저 설계해야 한다.
모듈 활성 상태는 실행 구성의 책임으로 자동 복원하지 않는다. restore는 모든 등록 모듈이 명시되어야 한다. 누락/알 수 없는 모듈은 fail closed; 원본 envelope는 호출자가 보존한다.

## 기존 규칙을 재사용할 경계 (아직 제안)
- 입력 의도→Interaction 서비스: E 시설/조사, T NPC, N 수첩 우선순위를 보존.
- Chapter1 bridge를 content adapter로 유지, 공통 Investigator가 발견/추론 상태 계약을 소유하도록 순차 분리.
- Store는 안전한 파일 I/O를 유지하고 모듈 validator 등록을 composition root로 이동. Core에 Chapter1 이름을 넣지 않기.
- Network adapter는 peer→actor를 해석, 신뢰된 명령만 서비스 호출, 공개 snapshot을 생성. 새 Runtime의 client 거절은 인증/인터넷 보안을 대체하지 않는다.
- UI는 결과를 구독하되 규칙 변경은 요청 경로로만. PNG 교체는 Resource 매핑만 바꿔야 하며 현재 procedural art 전체 교체는 P6이다.

## 엔티티/컴포넌트 경계 (설계, 어댑터 미구현)
공개 content_id(정의), entity_id(월드 내 개체), life_id(생애), peer_id(일시 연결)를 구분한다. world_id+entity_id로 월드 간 오인 참조를 방지하고, 사망 기록은 life_id를 보존한다. Node instance ID나 peer ID를 영구 식별자로 저장하지 않는다. 기존 life/room/token 필드를 즉시 이름 변경하지 않고 P1-B에서 변환 어댑터로 매핑한다.
기능 확장은 Godot 자식 Node/RefCounted 서비스로 구성하고 소유자 해제 시 구독과 자원을 정리한다. 이번 Runtime 모듈 ID는 엔티티 ID가 아니며 단일 모듈 내부 다수 인물 상태의 분할·권한 계약은 아직 구현하지 않았다.
