# Migration Plan
2026-11-23. 빅뱅 교체 금지. 사용자 저장/현재 스태시/타 브랜치 미커밋 변경은 적용하지 않는다.

| 단계·대상 | 재사용/이동 경계 | 영향/검증 | 롤백 |
|---|---|---|---|
| P0 | 실제673dd1a와 원격 계보/로컬 WIP 분류, 문서 계약 | 기존 규칙 기준선, 정본 누락 기록 | 문서 커밋 되돌리기; 런타임 영향 없음 |
| P1-A (이번) | content-free Runtime/Module, 테스트 전용 확장 | 독립 Node만 사용. main/world/store/씬/RPC 무변경. 권한·중복·snapshot·정리 단위 검사와 기존 회귀 | 새 파일/테스트 커밋 revert. 월드 저장 이관 없음 |
| P1-B | 기존 world 읽기/명령 어댑터와 composition root | game mode·life 소유·모듈 off·구독 정리 검사. 미착수 | 어댑터 등록 해제, 기존 경로 유지 |
| P1-C | Store I/O 재사용, validator 등록·모듈 저장 배치 | v1~23 fixture, story 유무·손상·미래버전·백업 실패, 원본 byte 보존 | 구포맷 파일 유지/별도 backup. 구앱으로 신포맷 열지 않기 |
| P2 | 접속→이동→상호작용→저장→재접속 | 실제 입력/발판·신규 건물·저장 좌표 겹침, E/T/N, 두 클라이언트 | 기능 플래그/구 루프 유지, 별도 fixture에서 재현 |
| P3-1 NPC 지식/기억/관계/대화 | chapter1_dialogue/관계 함수 + main 세션 | 진술/객관 사실 분리, 생애·지역·세션·사망·중복검사 | 한 서비스 단위 원복 |
| P3-2 NPC 행동/생활 | npc_life·world.advance 재사용 | 일정·부재 시간·서버 정지·저장 중복 처리 | 기존 일정 계산기로 복귀 |
| P3-3 조사 | 기존 사망 조사와 Chapter1 별개 도메인 보존 | 실물 소유/관찰 기록·타인 정보 투영/추론 | 기존 bridge 어댑터 유지 |
| P3-4 이벤트/퀘스트 | requests/expedition/travel 분리 규칙 | 의도된 반복·보상1회·전이/재시작 | 기능별 기존 규칙 호출 |
| P3-5 History/Journal | events/journal/books/graves/life | 출처·시각·사망 후 보존·공개 권한 | 기존 정형 기록 유지 |
| P3-6 Gameplay | items/storage/craft/professions/combat | 개별 장비/품질/강화/수리·전투 수치 회귀 | 분야별 어댑터만 해제 |
| P4 콘텐츠 | Chapter1/Ash Village 데이터를 등록 | 정본 vs 구현 대조. DEC-02AD~AW 원문 확인 전 해당 내용 보류 | 콘텐츠 manifest 교체, 기존 ID aliases 유지 |
| P5 지속성 | 동일 domain service+싱글/ENet adapter | 서버 재시작/재접속/권한/모듈 off 보존 | 안정 프로토콜/복사 저장으로 롤백 |
| P6 확장 | 신규 NPC/지역/UI/PNG 등 | Core 수정 없이 추가되는지 파일 diff·행동 확인 | 신규 패키지만 비활성 |

## 이번 변경과 저장/프로토콜
현재 branch는 저장 v23과 기존 RPC 그대로다. 별도 local WIP의 v24 포맷을 가져오지 않는다. 독립 Core snapshot은 테스트에서만 JSON 왕복하며 user:// 저장에 쓰지 않는다. 앞으로 v23에 modules 필드를 추가한다면 선택적 확장 vs 버전 증가·구버전 유실 위험을 비교하고 별도 방안부터 승인/검증한다.
기존 can_send_to_peer의 peer 목록 검사만으로 모든 disconnect 경쟁을 해결했다고 가정하지 않는다. 현재 기준 ENet 검사를 실제 실행하고 다른 WIP의 송신 오류와 결과를 분리한다.

## 보존·누락
- 원본 f9c4a35, .venv-asset, local-main-world-before-evidence-board 스태시 유지.
- codex/chapter1-integration의 v24 미커밋 작업은 별도 트리에 그대로 남고 현재 기준에 포함하지 않는다. 1045 규칙/19 UI와 종료 ENet 오류 이력을 보존한다.
- safe-port4a3a2af는 최신 fetch로 확인. 모듈 내용과 후속 실제연결을 재사용한다.
- DEC-02AW라는 최신 지시의 범위는 알고 있으나 확인한 design tip에는 AC까지와 AD 대기만 있다. AD~AW 항목 목록을 지어내지 않는다. P4 상세 백로그는 원문/저장 위치 확인 후 작성.
