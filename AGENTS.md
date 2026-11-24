# VESTIGE 작업 규칙
2026-11-23. 사용자 최신 지시를 우선한다. Core-first 개발의 정본 안내는 docs/ARCHITECTURE.md와 docs/DEVELOPMENT_ROADMAP.md다. 기존 origin/docs/ai-collaboration-governance의 역할·저장 보호 규칙을 재사용하되 최신 지시로 갱신했다.

- ChatGPT: 설계·정본·기억/관계·계약·검토. Codex: 실제 코드 분석·구현·작은 이관·검증·로컬 커밋. 설계 문서가 코드 구현의 증거는 아니다.
- 시작할 때 branch/HEAD/status/worktree/stash와 관련 파일을 확인한다. 기존 스태시 자동 적용·미커밋 덮어쓰기 금지.
- 현재 기준: qa/chapter1-p1i-macos-input@673dd1a의 G0.5.19+분리된 제1장 모듈. docs/handoffs의 P1-I 등은 과거 제1장 작업 단계명이며 새 Core P1과 구분한다.
- main 직접 수정/병합, 원격 push/PR 생성은 별도 사용자 지시 없이 하지 않는다. 작업 브랜치는 feature/core-modular-architecture.
- 이번 허용 범위 P0와 제한적 P1. 세계 저장 v23·RPC 계약·기존 게임 루프를 일괄 교체하지 않는다. 큰 변경은 영향·이관·복구 계획부터 문서화한다.
- Core는 콘텐츠 이름/ID를 참조하지 않는다. Godot Node/Scene/Signal/Resource/ENet을 재사용한다. 불필요한 ECS·Manager·Autoload 추가 금지.
- 기존 investigation.gd(사망/유품)와 story/chapter1_*(고정 제1장)를 덮어쓰지 않는다.
- 새 인터페이스는 상태 소유자·권한·범위·수명·오류·저장·비활성화 계약과 검사 증거를 함께 기록한다.
- 단위별 파싱/관련 테스트/전체 회귀. 실패와 미실행을 구분한다. 헤드리스 UI 객체 검사는 실제 사람의 플레이 검증이 아니다.
- 사용자 저장 삭제/테스트 사용 금지. 합성 fixture/임시 경로 사용. 빌드는 이번 범위 밖이며 기존0.5.19 실행본 유지.
- 카엘의 조작·책임/이렌 최후를 임의 확정하지 않는다. 확인하지 못한 DEC 정본은 보류한다.
- API 과금·AI 이미지 생성·불필요한 그래픽 작업 금지.
- 보고: 브랜치/커밋, 분석, 결합 문제, 인터페이스/파일, 재사용, 검사, 잔여 문제, 다음 작업. 단계 상태는 미착수/진행 중/구현 완료/검증 완료/보류.
