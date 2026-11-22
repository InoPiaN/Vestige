# ChatGPT ↔ Codex 작업 연속성 인계 (2026-11-22)

## 무엇을 했나

사용자 승인에 따라 프로젝트 개발 규칙과 AI 협업 체계를 **문서 전용 브랜치**에 생성했다.

- 브랜치: `docs/ai-collaboration-governance`
- 기준: `feature/chapter1-input-integration` (P1-B1 조사 연결)
- 생성: 루트 `AGENTS.md`, `ARCHITECTURE.md`, `DEVELOPMENT_WORKFLOW.md`, `PROJECT_STATUS.md`, 본 인계 파일
- 수정하지 않은 파일: `desktop/**`, `scripts/**`, `docs/PROJECT_STATUS.md`, `docs/GIT_WORKFLOW.md`, 실제 사용자 저장/설치 빌드
- main 병합·PR 생성·실제 Godot/ENet 실행 **하지 않음**
- 원격 브랜치 파일 커밋은 사용자 허용 범위에 따라 수행

## Codex 복귀 시 필독 순서

1. `AGENTS.md` — 모든 AI에게 공통으로 적용할 안전/영향 분석/검증/보고 계약
2. `PROJECT_STATUS.md` — 현재 브랜치, 미검증 상태, 결정 필요 사항
3. `ARCHITECTURE.md` — 실제 G 0.5.19+P1-B1 구성 및 미통합 부분
4. `DEVELOPMENT_WORKFLOW.md` — 요구사항 → 영향 분석 → 구현 → 테스트 → 인계
5. `docs/handoffs/chapter1-input-integration.md` — E/N 연결 내역과 Godot 검증 순서
6. 별도 `codex/technical-baseline-audit/docs/technical-baseline/` — 독립 조사 계열 감사·ENet 실패/브랜치 충돌 상세

## 중복·차이 해소 정책

- 기존 `docs/PROJECT_STATUS.md`는 0.5.19 게임의 **기능별 현황표**로 유지한다. 루트 `PROJECT_STATUS.md`는 **브랜치 간 통합과 현재 AI 작업 현황**을 관리한다.
- `docs/GIT_WORKFLOW.md`의 기존 Claude/Codex 작업 보호 규칙은 유지한다. 새 `AGENTS.md`가 이를 대체·삭제하지 않고 강화한다.
- 이전 `docs/CODEX_HANDOFF.md`는 과거 버전 기록이 많다. 최신 기준은 루트 상태 문서와 해당 기능 `docs/handoffs/`.
- 2026-11-22 기술 감사 문서는 별도 브랜치에 있다. 병합하지 않았으며 코드/테스트에 대한 진술은 감사의 **기록된 커밋에서만** 유효하다.
- 최신 작성 시점의 원격 변경은 미커밋/스태시/현재 실행 서버를 보여주지 않는다. 반드시 로컬에서 확인한다.

## 테스트와 남은 차단 요인

- 이번 문서 작업에 기능 코드 변경 없음. 문서 구문/링크/내부 모순을 검토했으며 Godot/ENet 기능 테스트를 새로 실행하지 않았다.
- P1-B1 E/N 통합 테스트는 아직 실행되지 않았다. 이미 작성된 테스트 스크립트가 존재한다는 점과 PASS를 혼동하지 않는다.
- S의 ENet 송신 오류, 신규 story 필드 저장 검증, 대화 세션/RPC, E/F/N 모달·동선·시설 회귀는 후속이다.
- **ChatGPT나 Codex가 임시로 구현을 대신하더라도 동일 `AGENTS.md` 규칙을 반드시 준수한다.**

## 다음 작업 권장

현재 문서 브랜치의 변경만 검토한 후, 별도 코드 브랜치에서 P1-B1 검사와 결함 보수부터 진행. 사용자가 명시하지 않은 새 서사·기능을 추가하지 말고 검증된 구현 차이를 기준으로 계획한다.

### Codex용 시작 문구

> `docs/ai-collaboration-governance`의 `AGENTS.md`, `PROJECT_STATUS.md`, `ARCHITECTURE.md`, `DEVELOPMENT_WORKFLOW.md`, `docs/handoffs/ai-collaboration-governance.md`를 먼저 읽어. 현재 로컬 브랜치/스태시를 보호하면서 `feature/chapter1-input-integration`의 E/N 연결을 검증해. 완료/미완료/검증 실패를 구분하고, 범위 밖 변경과 main 병합은 하지 마.
