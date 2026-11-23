# Dependency Map
2026-11-23 · 실제 기준673dd1a. dependency-baseline.json은 literal load/preload 정적 참조를 기록한다. 동적 문자열·Dictionary key 변이·signal 연결은 별도 코드 분석이 필요하며 이 목록만으로 결합을 모두 설명하지 않는다.

## 실제 주요 의존
- project.godot → main.tscn → main.gd.
- main → world, pixel_world, panel들, Chapter1 bridge/investigation/board. UI 이벤트와 RPC가 같은 노드에서 분기.
- world → travel/forage/professions/expedition/market/craft/house/investigation/store 등. 각 prepare/valid를 중앙에서 명시 호출.
- world_store → 각 save validator + Chapter1 save_contract. **Core 후보가 특정 콘텐츠를 직접 아는 결합**.
- Chapter1 bridge → chapter1 investigation/dialogue/rules/board; dialogue → investigation → chapter rules.
- 기존 investigation → witness/evidence_items/house_storage/death_belongings; 제1장과 상태 scope가 다르므로 통합 파일 교체 금지.
- pixel_world → world 및 아트 helper; UI/renderer가 규칙 const·상태 Dictionary를 직접 읽음.
- inventory/storage/market은 items와 개별 gear 모델을 공유. 인벤토리 형식 교체는 제작·강화·유품까지 영향.
- main peers/inputs/session/request-id는 실행/연결 수명. world 상태와 혼합 저장하지 않음.
- Autoload 없음. 전역 singleton을 추가할 필요가 확인되지 않았다.

## 결합 분류
| 구분 | 현황 | 우선 조치 |
|---|---|---|
| 잘 분리된 규칙 | craft_quality/mastery, npc_life, chapter1_rules, evidence_board_rules | 함수/검사 재사용 |
| 부분 분리 | Chapter1 bridge, world_store, panels | 명시적 계약 어댑터 추가 |
| 강한 결합 | main 입력·세션·UI·RPC, world의 prepare/act/validation 분기 | 한 경로씩 이관; 일괄 Manager 재작성 금지 |
| 데이터 결합 | 같은 p/world Dictionary를 여러 모듈이 변이 | 소유자·read projection·명령 경계 정의 |
| 콘텐츠 결합 | Chapter1 이름을 main/store가 직접 참조 | 최종적으로 composition root 등록, Core는 내용 모름 |
| 표현 결합 | 절차형 draw 코드와 월드/콘텐츠 const | 이후 asset key/Resource adapter; PNG 교체로 로직 영향 금지 |

## 이번 P1 의존 (목표/검증 대상)
tests/fixtures/observation_module → core/game_module → Godot RefCounted
tests/test_core_runtime → core/module_runtime → core/game_module/JSON value contract → Godot Node/Signal
main/world/store/기존 콘텐츠 → 새 core 참조는 **추가하지 않는다**. 따라서 초기 실험의 성공과 실제 게임 이관 성공을 구분한다.

## 영향 확인 방법
변경 전후 기존 런타임 파일 hash/diff가 동일한지 확인하고 동일 runner로 기준선/회귀를 비교한다. Core에 res://story·world·items·아트 preload가 없어야 한다. 초기 실험 모듈 추가 시 Core·기존 기능 diff가 없어야 한다.
