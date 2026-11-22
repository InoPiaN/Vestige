# Feature Inventory
기준일2026-11-22. G=codex/village-requests@4ba2c21, S=feature/chapter1-evidence-board@f9c4a35. **각 브랜치의 제한된 구현**과 **전체 목표**를 구분한다. verified는 기록된 환경·검사 범위만 뜻하며 출시 완료가 아니다.

| 기능 | 실제 구현과 경로 | 구현 상태 / 검증 |
|---|---|---|
| 캐릭터 생성·장비 외형·소지품 | 양쪽 main/items/inventory. G는 방향 애니메이션·개별 장비·품질·확장 목록 | 양쪽 구현. 해당 test_customization/inventory 재검증 |
| 이동·전투·시간·노화·부재 | 양쪽 world. G는 사거리/시야·원정·방어구·스킬 확장 | 시제품 구현, 규칙 재검증. 장기 운영/실제480일 자연사 미검증 |
| 제작·대성공·숙련·강화·수리 | G home_crafting/craft_*/sword_upgrade/armor_upgrade/forge_repair | 구현·자동 회귀 통과. 종합 경제 밸런스 부분 |
| 시장·되사기·재고 | G village_market, market_panel | 구현·자동 회귀 통과 |
| 주택·보관·유품·기록 전승 | G investigation/house_*/death_belongings/evidence_items | 고정집1채 범위 구현·회귀 통과. 자유 건축/다중 소유·상속 미구현 |
| 일기·서재·묘지 | 양쪽 world/main, G는 집/장비 기록 확장 | 정형 이벤트 집계 구현. 생성형 일기 미구현 |
| 직업·스킬 | G professions | 전사·사냥꾼 입문, 능동4개/준비2칸 구현·회귀 통과. 직업 전체/경지 미구현 |
| 지역·NPC 일정·채집 | G travel/npc_life/foraging | 마을2+숲길, NPC2명 고정 일정, 채집3종 구현·회귀 통과 |
| 반복 의뢰 | G village_requests | 게시판2/의뢰3개 구현·회귀 통과. 동적 수요 생성 미구현 |
| 사망 사건 조사 | G investigation/witness/evidence_items | 구성된 사건·목격·유품·범인 지목 구현·회귀 통과. 임의 사건 자동 추리 미구현 |
| 브란·세라·카엘 대화 | S dialogue/main | 거리·세션·증거 분기 구현, dialogue/kael/UI 재검증. G에는 미통합 |
| E 증거 조사·N 수첩 | S investigation/main | 출처·발견시각/순서·사실/추정·중복/개인 상태 구현. investigation/UI 재검증 |
| E01/E05/E06/E07/E08/E13 | S investigation, chapter1_rules | 5개 현장 증거+카엘 진술1개 획득 경로 구현. 관련 검사 통과 |
| 증거 두 개 조합 | S story/evidence_board_* | I03/I04/I07 로컬 검증·UI 연결 구현,19검사 통과. 실제 ENet 조합 전용 E2E 테스트 없음 |
| 관계·기억 | S chapter1_rules.relationship_event/관계 dict | 상태/중복 방지 함수와 단위 검사만. 주민의 자율 기억·상호 관계 행동은 미구현 |
| 제1장 결말·제2장 | S can_resolve/resolve/finish_epilogue | 함수/상태 뼈대 있음. 필요한 증거 획득·선택 UI·종합 플레이 연결 없음. 완료 처리 금지 |
| 저장·멀티 | G version23, S version1; ENet | 개별 계열 구현. 상호 저장 호환/통합 네트워크 미검증 |
| AI 자산 도구 | S tools/asset_mcp | 선택적 후보 생성/검토 반입 코드. 이번 API·과금 실행 없음. 게임 지식/대화 AI와 별개 |
| Steam 출시 | export 설정·로컬 Mac/Windows 패키지 | 시제품 패키징만. Steamworks/Cloud/인증/스토어 출시 미구현 |

## 반드시 미확정으로 유지할 내용
- E08의 사실은 “카엘이 그렇게 진술했다”이다. 진술 내용 전체가 객관적 진실이 되는 것은 아니다.
- I03=현장 흔적과 가동 기록의 제한적 연결, I04=표식과 방문 진술 대조, I07=기록과 도구 파편 연결.
- 카엘의 실제 조작·의도·책임, 사고 원인, 이렌의 최후는 확정하지 않는다.
- I01/I02/I05/I06과 E03/E04/E09/E10/E11 등 함수 내 참조는 획득 가능한 구현이 아니다. 미제공 명세와 후속 증거로 표시한다.
- chapter_completed/chapter2_letter_received 변수가 있다는 사실은 챕터 완료 플레이의 구현 증거가 아니다.
- legacy 서재의 “이렌의 마지막 장/마지막 일기” 문구는 기존 텍스트이다. 정식 사망 확정으로 해석하지 않도록 통합 단계에서 설계 담당자 검토가 필요하다.

## 계획만 존재하거나 기반 수준인 목표
NPC 지식·장기 기억 그래프, 자율 사건과 죽음의 인과 추적, 규칙 기반 행동 트리, 통합 이벤트/퀘스트 상태 머신, 자유 건축과 상속, 부활·경지·수명 연장, 추가 지역/절차 던전/다양한 직업·장비, 생성형 대화와 동적 퀘스트, Steam 운영·Windows 실기 품질은 미완료다.

이번 S 실제 ENet 회귀는 서버 종료/전송 오류로 전체 FAIL이다. 클라이언트 일부 PASS를 멀티 완료로 확대하지 않는다. 상세 로그는 VALIDATION_RESULTS.md.

## 검증 해석
G의 이번761항목은 개별 규칙 회귀 결과다. 이전0.5.19의 Mac UI17개/ENet 검증 기록은 과거 증거로 유지하며 이번에 화면/빌드를 재검증했다고 표시하지 않는다.
S의 이번279항목에는 헤드리스 UI 객체 검사가 포함된다. 실제 사람 조작·픽셀 가독성·전체 챕터/조합 RPC 성공 증거로 확대하지 않는다.
검증은 브랜치+커밋+환경+테스트+시나리오별로 기록한다. 두 브랜치의 PASS 합계로 통합 성공률을 만들지 않는다.
