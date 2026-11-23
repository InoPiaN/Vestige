# Core-First Architecture
2026-11-23 · P0 설계. 실제 기준 673dd1a(qa/chapter1-p1i-macos-input). 이번 문서의 목표 구조는 아직 전체 구현이 아니다.

## 확인된 현황
- root main=8b1f152, 원본 체크아웃=f9c4a35, 기존 게임=4ba2c21. 새 fetch로 safe-module-port=4a3a2af 및 후속 브랜치 확인.
- 현재 기준은 안전 이식→입력→세션→조합→저장 검증→회귀/탐색→Mac 입력까지 누적된673dd1a. 버전23을 유지하며 G의 world/investigation 보존.
- eb20830의 건물 깊이 표현 실험은 governance31f20d8에서 보류된 것으로 기록되어 제외. 과거 로컬 codex/chapter1-integration의 미커밋 v24 작업도 별도 보존/미채택. 그 트리의1045/화면19 결과는 이 브랜치의 검사 결과가 아니다.
- remote design/ad81304에서 DEC-02AC까지의 확정 기록과 DEC-02AD 대기 표시 확인. DEC-02AW 정본은 현재 확인한 소스에 없다. AD~AW 내용을 추정하지 않는다.
- 과거 docs/PROJECT_STATUS.md는0.5.19 위주이며 제1장 후속 코드를 모두 반영하지 않으므로 코드와 함께 읽는다.

## 실제 폴더·진입점
desktop/project.godot → desktop/main.tscn → main.gd(Node).
main은 코드로 UI/PixelWorld를 생성하고 single/server/client를 선택한다. 프로젝트에 Autoload 항목은 없다. RefCounted 정적 규칙이 Dictionary를 인자로 받아 갱신하며 scene마다 월드 상태를 소유한다. 별도 ECS/전역 이벤트 버스도 없다.

| 경로 | 현재 역할 |
|---|---|
| main.gd | 입력/모달/실행 모드/ENet/대화 세션/조합 요청/화면/저장 호출. 약1300줄의 결합 지점 |
| world.gd | 월드/인물 생성, 이동·충돌·시간·전투, act, load/save |
| world_store.gd | 저장v23 및 구버전 검증, .tmp/.bak 교체·복구 |
| story/chapter1_bridge.gd | 게임→제1장 얇은 어댑터, 생존/직접조종/village 게이트 |
| story/chapter1_save_contract.gd | 선택적 people[id].story 구조 읽기 전용 검증 |
| story/chapter1_rules/investigation/dialogue | 증거 매핑/추론/관계, 발견 기록, NPC와 증거별 선택지 |
| professions/foraging/travel/npc_life/village_requests | 이미 분리된 성장/채집/지역/일정/반복 의뢰 규칙 |
| craft_*, house_*, village_market, armor_*, sword_upgrade | 제작·보관·시장·장비 규칙과 상태 초기화 |
| investigation/evidence_items/witness/death_belongings | 별도의 사망 사건·목격·실물 증거·유품 |
| pixel_world/portrait/*_panel.gd | 렌더링/화면. 조건 일부를 직접 규칙에서 읽음 |
| desktop/tests, scripts | 규칙/헤드리스 UI/ENet/렌더 검사. 기준선은 별도 측정 |
| game.mjs/server.mjs/public/test | 보조 웹 시제품. Godot Core의 대체 구현으로 간주하지 않음 |

main.gd에는 Chapter1의 직접 preload와 전용 RPC가 있고, world_store에는 해당 save validator의 직접 참조가 있다. bridge 상단의 “not wired yet” 주석은 현재 main 연결 상태와 맞지 않는 과거 주석이다. 이를 실제 미구현으로 오판하지 않는다.

## 목표 계층과 현재 차이
| 계층 | 목표 | 현재/이번 처리 |
|---|---|---|
| Engine | Godot Input/Node/Scene/Resource/Signal/ENet | 유지 |
| Core | 상태 소유·명령/이벤트·모듈 수명·저장/권한 계약 | 이번에는 독립된 작은 Runtime/Module 실험만. 기존 세계 루프에 연결하지 않음 |
| Feature | NPC/Interaction/Investigation/Quest/History/Gameplay 공개 서비스 | 기존 정적 모듈 재사용, P3에서 작은 어댑터로 순차 이관 |
| Content | Ash Village/Chapter1/NPC/증거/대화 데이터 | 현재 GDScript const와 규칙 혼합. P4에서 승인된 데이터만 분리 |
| Presentation | Scene/UI/스프라이트/효과 | 이번 변경 없음. 장기적으로 asset key→Resource 교체, 규칙은 Texture 경로에 의존하지 않음 |

Content→Feature→Core→Engine. 구성 지점(composition root)은 모듈을 알고 등록할 수 있지만 Core가 콘텐츠를 preload하면 안 된다. main.gd를 즉시 순수 Core로 이름만 바꾸지 않는다.

## 권한·생애·지속성
world.people는 계정/토큰별 현재 인물, life는 새 생애 ID, room은 지역이다. 공개 정의 ID와 인스턴스/생애/네트워크 peer를 구분한다. NPC ID만으로 다른 지역의 동명 좌표에 접근하지 않는다.
싱글은 로컬 권한 규칙, 멀티는 서버만 변이. 클라이언트는 의도만 제출한다. story/사망 진실/유품 비공개 정보는 snapshot 투영에서 제거한다. 48자리 토큰은 Steam 인증이 아니다.
v23 load→검증→보완→(싱글 경과 시간)→checkpoint가 기존 안전 경로다. 모듈 envelope는 이번에 이 파일에 삽입하지 않는다.

## P1 제한적 착수 범위
content-free ModuleRuntime(Node)와 GameModule(RefCounted), 복사된 소유 상태, 등록/의존/활성/비활성/정리, 명시적 이벤트 적용과 Godot Signal 완료 통지, JSON 가능 독립 snapshot을 구현 대상으로 고정한다.
기존 main/world/store/RPC/씬/저장 v23은 변경하지 않는다. 실험 fixture로 계약을 검증해도 실제 게임 루프나 멀티 지속성 완료로 표시하지 않는다. P2 연결 전에 별도 어댑터·저장 envelope 배치·snapshot 공개 정책을 결정한다.

## 기능 현황과 미완료 경계
| 분야 | 실제 구현 | 목표 대비 상태 | 검사 근거 |
|---|---|---|---|
| 이동·충돌·전투·채집·제작·품질·강화·수리 | world 및 개별 규칙/패널 | 구현 완료(현 시제품 범위) | 기존 규칙 테스트, 이번 실제 조작은 미실행 |
| 직업·기술·생활 일정·여행·의뢰 | professions/npc_life/travel/requests | 부분 구현; 전체 콘텐츠 목표 미완료 | 분야별 기존 테스트 |
| 사망·유품·집·보관·일지 | investigation/house/storage/history | 부분 구현; 자유 건축·부활 완성 아님 | 분야별 기존 테스트 |
| 제1장 증거·대화·수첩·제한적 재구성 | story modules+main 연결 | 구현 완료(현재 제한적 조사 범위) | 제1장 자동 검사·ENet; 이야기 전체 완성 아님 |
| 싱글/서버 권한·저장 | main/world/store v23 | 부분 구현; Steam 인증/장기 운영 미완료 | 저장 회귀·실제 ENet 합성 fixture |
| 공통 Core | 독립 ModuleRuntime 실험 | P1 진행 중 | 테스트 전용 모듈, 실제 게임 미연결 |
| 데이터 등록형 콘텐츠·일반 퀘스트 그래프·NPC 기억 AI | 목표 설계 | 미착수 | 구현 증거 없음 |
| Steam 출시·최종 Mac/Windows 품질 | 기존 시제품 빌드 이력만 | 미완료 | 이번 재빌드/실사용 QA 미실행 |

각 분야의 검사 수와 제한은 최신 handoff를 기준으로 한다. 상태는 게임 전체의 완성을 의미하지 않는다.
