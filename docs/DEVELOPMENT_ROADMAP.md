# VESTIGE Core-First Development Roadmap
2026-11-23 사용자 최신 지시가 이전 콘텐츠 중심 로드맵/6단계 순서를 대체한다. 과거 기능 이력은 docs/handoffs와 docs/PROJECT_STATUS.md에 유지한다. 과거 Chapter1 P1-A~J와 아래 Core P0~P6는 서로 다른 단계명이다.

| 단계 | 현재 상태 | 선행 조건 / 완료 기준 |
|---|---|---|
| P0 구조 분석·설계 | 진행 중(이번 문서/기준선 확정 후 검증 완료) | AGENTS/ARCHITECTURE/CONTRACTS/MIGRATION/DEPENDENCY/ROADMAP, 실제 기준선과 한계 |
| P1 Core 안정화 | 진행 중(최소 독립 계약만 이번 구현) | 상태→Signal 이벤트→수명→저장/버전→권한 순서. 이번은 독립 모듈 실험, 실제 월드 어댑터 미착수 |
| P2 Core Gameplay Loop | 미착수 | 실제 접속·이동·상호작용·저장·재접속·좌표 충돌 검사 |
| P3 공통 기능 모듈 | 미착수 | NPC 지식/기억/관계/대화→생활→조사→퀘스트→역사/Journal→Gameplay |
| P4 기존 콘텐츠 이식 | 보류(정본 범위 확인 필요) | 기존 코드 재사용. DEC-02AW 원문 확인, 새 진실 추가 금지 |
| P5 싱글·멀티 지속성 | 미착수 | 동일 규칙, 권한·공개 snapshot·재접속·모듈 off·서버 재시작 |
| P6 신규 기능/그래픽 | 미착수 | 앞 단계 안정성·실제 독립 확장 증명 후 사용자 지정 콘텐츠 |

## 바로 진행하는 P1-A
기존 게임에서 호출하지 않는 작은 ModuleRuntime과 GameModule을 추가하고 테스트용 observation module을 주입한다. 등록·의존·활성/비활성·정리, 복사 상태, idempotent event, Signal 완료 통지, 독립 JSON envelope 복원, client 변이 거절을 검증한다.
별도 Manager/Autoload/ECS를 도입하지 않는다. 이 실험은 “실제 게임에 신규 콘텐츠 등록 후 싱글·멀티 재접속까지 성공”이라는 필수 확장 검증을 대체하지 않는다.

## 다음 P1-B/P2
1. 이번 계약을 기준으로 기존 world 서비스의 읽기 투영/명령 어댑터 하나 설계.
2. 모듈 snapshot 배치와 v23 호환 정책, 허용되지 않은 콘텐츠 비공개 투영 설계.
3. 테스트 오브젝트 상호작용을 실제 게임 구성 지점에서 등록. 기존 기능/Core 수정 없이 추가 가능한지 파일 diff 기록.
4. 모듈 활성/비활성, 저장/재접속, 실제 ENet 두 클라이언트와 부정 권한 요청까지 검사.
5. 첫 생성(9,9)/문·모서리·이렌 집/예배당/시설 E·NPC T/N·ESC를 실제 조작 확인. 건물 지붕 그래픽과 발판 충돌을 혼동하지 않기.

실행 결과는 docs/handoffs/core-modular-p0-p1.md에 기록한다. 검증 완료는 해당 테스트 범위에 한정하며 전체 P1~P5 완료로 확대하지 않는다. 원격 push/PR·main 병합·API 과금·이미지 생성 없음.
