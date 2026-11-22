# Current Architecture Report
기준일 2026-11-22. 코드 분석 기준은 게임 G=`4ba2c21`, 조사 S=`f9c4a35`, 공통 조상=`8b1f152`. 이 문서는 통합된 게임의 존재를 주장하지 않는다.

## 실제 저장소와 작업 위치
- 원본 체크아웃: `/Users/junheejang/Documents/Vestige`, `feature/chapter1-evidence-board`.
- 게임 작업 트리: `worktrees/professions-and-skills`, `codex/village-requests`.
- 이번 문서 작업 트리: `worktrees/technical-baseline-audit`, `codex/technical-baseline-audit`, G에서 분기.
- main은0.3.1 기준점이다. 최신 조사/0.5.19 게임은 아직 main에 없다.
- 원본의 미추적 `.venv-asset/`, `stash@{0}`의 main/world 변경은 보존했다. 상세 커밋은 branch-manifest.json.
- Git에 남은 /private/tmp의 과거 작업 트리들은 prunable 표시가 있다. 이번에 정리하거나 복구하지 않았다.
- 전체 실제 추적 파일 목록은 game-tracked-files.txt / story-tracked-files.txt. .tools·builds·실제 사용자 저장·가상환경은 이 목록과 별개다.

## 폴더 구조
| 경로 | 역할/차이 |
|---|---|
| desktop/project.godot, main.tscn | Godot 설정과 Vestige Node 진입점.1280×800, Compatibility 렌더러 |
| desktop/main.gd | 실행 모드, UI 생성, 입력, ENet, 저장 호출을 함께 관리하는 조정자 |
| desktop/world.gd | Dictionary 월드 생성·이동·시간·전투·행동 디스패치·저장 진입 |
| desktop/pixel_world.gd, portrait.gd | Node2D 기반 픽셀 월드/캐릭터 표현. 일반 TileMap 기반 제작 체계가 아님 |
| desktop/items.gd, inventory_panel.gd | 아이템 정의·수량과 소지품 UI. G는 품질·개별 장비까지 확장 |
| desktop/*_panel.gd | G의 제작·보관·장터·강화·직업·여행·의뢰 UI |
| desktop/world_store.gd | G 전용: 저장 구조 검증·백업·교체 쓰기 |
| desktop/investigation.gd | G: 사망 사건/유산 조사. S: 고정 제1장 증거 수집. 서로 다른 모듈 |
| desktop/story/*.gd, dialogue.gd | S 전용: 논리 증거 매핑·제1장 상태/추론·조합 UI·NPC 대화 |
| desktop/tests/ | 각 계열의 GDScript 규칙·UI 객체·ENet 검증 |
| scripts/ | G의 verify_rules 및 분야별 network/render/export 도우미. S에는 test_desktop_network.py |
| docs/, docs/handoffs/ | 기획·과거 구현 기록. 브랜치마다 다르며 최신 코드와 대조 필요 |
| artifacts/art/ | 검토용 렌더 이미지. 런타임 전체 아트 라이브러리와 구분 |
| game.mjs, server.mjs, public/, test/ | 기존 Node 웹 시제품. Godot 주 실행 경로와 분리 |
| tools/asset_mcp/ | S 계보의 선택적 이미지 후보 생성·검토 후 허용 자산 반입. 게임 AI/지식 그래프가 아님 |
| .tools/, builds/ | 로컬 Godot 도구와 설치형 패키지, Git 추적 제외 |

G의 규칙 모듈은 professions/expedition/travel/npc_life/foraging/village_requests, home_crafting/craft_quality/craft_mastery/craft_plan/craft_supply, house_interior/house_storage, sword_upgrade/armor_upgrade/forge_repair/village_market, death_belongings/evidence_items/witness로 나뉜다. 대부분 RefCounted 정적 함수가 Dictionary를 직접 갱신한다. 메인 UI와 규칙은 분리되었지만, 중앙 world/main에 연결 로직이 집중돼 있다.

## 실행 흐름
`project.godot → main.tscn → main.gd._ready()`
1. --server이면 ENet UDP27180, 최대8명 서버. 그 외에는 코드로 UI를 생성한다.
2. single: 생성 UI/이어하기 → load_world/born → mode=single.
3. client: ENet 접속 → 48자리 토큰 등록 → 서버가 인물 매핑 → 권한별 snapshot.
4. _physics_process: 이동 → Rules.tick/advance → 화면 갱신. 클라이언트는 방향만 전송하고 서버가 이동 판정한다.
5. 입력/UI → perform/command → 규칙 → 결과 안내·snapshot·저장. 서버 snapshot 약0.1초, 이동 입력 약0.05초, 주기 저장10초.
6. 창 종료·접속 종료에서 부재 전환/저장. G의 체험23종은 별도 저장 파일을 사용한다.

G의 일반 행동은 world.act 중심이나, S의 대화와 reconstruct는 main.command/run_dialogue/submit_evidence_combination에 별도 경로가 있다. 통합 때 UI만 복사하면 권한 검증이 누락될 수 있다.

## 상태와 저장
| 항목 | G | S |
|---|---|---|
| world 버전 | 23,1~22 이관 | 1만 로드 |
| 개인 상태 | people[id], life, room, 장비·제작·직업·notebook·requests | people[id], story.visits/evidence/chapter1 |
| 공동 상태 | time, wolf, graves/books, estate/cases, 유품·시장·지역·채집 등 | time, wolf, graves/books |
| 조사 범위 | cases[life] + 개인 notebook, 물리 증거/유품 | 개인 story.evidence 원본 → 논리 evidence_links → inferences |
| 저장 안전성 | 타입/참조 검사, .tmp 검증, .bak 복구, 미래 버전 거부, 부재 처리 시 checkpoint | JSON 임시 쓰기/백업, 버전1 확인. G 수준의 구조 검증/복구 없음 |
| 생애 | 별도 life ID, 사망 후 유품·주택 기록 | 새 born에서 개인 story 초기화 |
| 부재 시간 | 싱글 로드 때 경과 계산; 서버 시작은 simulate_absence=false | load_world에서 경과 계산; 서버에도 동일 함수 |

두 계열 모두 기본 single-world.json/shared-world.json 경로를 사용한다. S로 G의 실제 저장을 열면 버전23을 로드하지 않고 fresh 상태를 반환하므로 이후 저장 시 기존 파일을 대체할 위험이 있다. 통합 검증 전에 저장 복사본과 별도 사용자 데이터 경로를 강제해야 한다. G가 버전1을 지원한다는 사실만으로 S의 story 보존·검증·노출 권한까지 보장되지는 않는다.

## 싱글/멀티 데이터 흐름과 권한
- 싱글은 같은 규칙을 로컬에서 호출. 모달 열림 시 월드 일시정지.
- 멀티는 지속되는 서버 월드에 client intent 전달; 토큰→peer 대응, 유효한 방향/명령 빈도 검사. Steam 인증은 없다.
- G: Investigation.redact가 사건 진실·비공개 보관함·다른 인물 조사/진행 등을 제거한다.
- S: 다른 인물 story/journal/events 제거, 대화 세션 서버 관리, request_id로 늦은 응답 구분, 끊기는 peer snapshot 방어.
- 서로의 필터를 합쳐야 한다. S의 snapshot을 통째로 적용하면 G의 cases/유품/제작 난수 등 내부 정보가 노출될 수 있다. G만 유지하면 S의 story가 노출될 수 있다.
- 현재 서버 권한 검증은 운영 보안 완성을 의미하지 않는다. 대량 접속·악성 패킷·권한 경계·장기 운영은 별도 검증 필요.

## 기술 기준점
이번 실제 사용 엔진은4.5.1.stable.official.f62fdbde1. 일부 S 커밋 제목의4.7 언급은 이번4.7 실행 검증 증거가 아니다. G 761항목, S 12스크립트279항목을 각각 재실행했다. 통합 실행/Windows 실기/실제 플레이는 이번 범위에 포함되지 않는다. 검증 상세는 VALIDATION_RESULTS.md.
