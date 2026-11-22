# VESTIGE — 현재 작업 상태 (AI 협업용 진입점)

> **P1-E 통합 QA 준비 (2026-11-22):** `feature/chapter1-p1e-qa-harness`에서 브란 E/T 겹침 좌표 테스트를 수정하고 `scripts/run_p1e_qa.py`를 작성했다. Godot 4.5.1 기반 G 규칙+7개 Chapter I 테스트의 종료코드·로그·JSON 실행 결과를 수집하도록 구성했으며 실 사용자 데이터 HOME/XDG/APPDATA 분리 기능을 추가했다. **이 세션에는 Godot/저장소 로컬 실행 환경이 없어 테스트는 미실행**이다. P1-E 완료가 아니라 환경 확보 및 실기 테스트 대기 상태. 인계: 해당 브랜치 `docs/handoffs/chapter1-p1e-integration-qa.md`. 코드 문서 브랜치·main에 미병합.

> **P1-D 저장 검증 갱신 (2026-11-22):** `feature/chapter1-story-save-validation`에서 G 월드 v23의 선택적 `story` 검증기, `world_store.gd` 연계, 임시 v22/v23·손상 primary/.bak 복구·미승인 추론 거부 테스트를 작성·커밋했다. **Godot 및 실제 저장 회귀 실행 미검증**이므로 저장 호환성 검증 완료라고 표시하지 않는다. S v1→G v23 자동 병합은 수행하지 않았으며 별도 결정 필요. 인계: 해당 코드 브랜치의 `docs/handoffs/chapter1-story-save-validation.md`. 이 문서 브랜치와 `main`에는 코드 미병합.

> **통합 안정화 갱신 — P1-C (2026-11-22)**: `feature/chapter1-integration-hardening`에서 증거 조합 서버 요청의 응답 누락/재전송 방지, 연결 해제 시 송신 전 피어 검사와 대화·보드 UI 정리, 기존 E 시설/스승 기능과 T NPC 대화 분리 코드를 추가했다. 신규 replay 테스트와 브란 E/T 회귀 테스트를 작성했으나 **Godot/ENet 미실행**, 기존 네트워크 송신 오류는 해결 미확인 상태다. 자세한 내용은 코드 브랜치 `docs/handoffs/chapter1-integration-hardening.md`. `main` 및 이 문서 브랜치에는 해당 코드를 병합하지 않았다.

> **후속 구현 갱신 — P1-B3 (2026-11-22)**: `feature/chapter1-evidence-board-integration`에서 N 수첩→증거 조합 UI와 `chapter1_reconstruct` 서버 RPC가 추가되었다. I03/I04/I07은 서버의 개인 증거 소유권·지역·생존·중복 검사로 제한한다. 새 테스트 두 파일은 **작성되었지만 Godot/ENet 실행 미검증**이다. 인계 문서는 `docs/handoffs/chapter1-evidence-board-integration.md` (해당 코드 브랜치). 문서 브랜치는 기능 변경을 병합하지 않았다.

> **후속 구현 갱신 (2026-11-22, 별도 코드 브랜치)**: `feature/chapter1-dialogue-session`에서 P1-B2 브란·세라·카엘 대화 선택지 UI와 서버 소유 세션(거리·지역·생애·토큰·허용 선택지·만료) 코드가 추가되었다. Godot·ENet 실제 실행 미검증이며, `docs/handoffs/chapter1-dialogue-session.md`에서 변경 내용·테스트 명령을 확인해야 한다. 이 문서 브랜치에는 해당 코드 변경이 병합되지 않았다. 기존 P1-B1 진행표의 ‘NPC 대화 미연결’은 P1-B2 브랜치에서 코드 연결 완료·검증 대기라는 후속 사실로 해석한다.


> 2026-11-22 기준. 이 파일은 **기존 `docs/PROJECT_STATUS.md`를 대체하지 않는다.** 원래의 0.5.19 게임 기능 점검표를 기준으로 유지하면서, 별도 제1장 통합 작업의 진행 상황과 AI 협업 문서 링크를 제공한다.

## 먼저 읽을 문서

- [공통 AI 작업 규칙](AGENTS.md)
- [실제 코드 아키텍처](ARCHITECTURE.md)
- [개발·검증 절차](DEVELOPMENT_WORKFLOW.md)
- [게임 0.5.19 기능 상세](docs/PROJECT_STATUS.md)
- [Git 기존 작업 방식](docs/GIT_WORKFLOW.md)
- [P1-A 제1장 모듈 이식 인계](docs/handoffs/chapter1-safe-module-port.md)
- [P1-B1 E/N 입력 연결 인계](docs/handoffs/chapter1-input-integration.md)
- [2026-11-22 기술 기준점 감사 — 별도 브랜치](https://github.com/InoPiaN/Vestige/tree/codex/technical-baseline-audit/docs/technical-baseline)

## 분리된 작업 계열

| 기준 | 브랜치 | 확인 범위 |
|---|---|---|
| 기본 | `main` | 0.3.1 계열. 최신 게임 본편 기준이 아님 |
| 게임 G | `codex/village-requests` | Godot 0.5.19, 직업/장비/제작/주택/지역/생활/의뢰/저장 v23 |
| 스토리 S | `feature/chapter1-evidence-board` | 제1장 증거/대화/추론/보드. 원래 G와는 분리 |
| P1-A | `feature/chapter1-safe-module-port` | G를 기준으로 제1장 스토리 모듈을 이름 충돌 없이 추가 |
| P1-B1 | `feature/chapter1-input-integration` | `main.gd`에 E 조사/N 수첩/서버 inspect 및 타인 story 비공개 연결 |
| 협업 문서 | `docs/ai-collaboration-governance` | 본 문서 등 4대 규칙·상태 문서, Codex 인계. **게임 코드 변경 없음** |
| 기술 감사 | `codex/technical-baseline-audit` | G/S 기능 재확인·충돌표·로드맵 (이 문서 브랜치에는 자동 병합되지 않음) |

최종 실제 작업 브랜치나 로컬 worktree가 어디인지는 개발자가 `git status`로 재확인해야 한다. GitHub만으로 사용자 컴퓨터의 미커밋 변경·스태시를 확인할 수 없다.

## 구현 완료 (범위 제한)

- **G 게임 계열**: 캐릭터 생성, 이동/전투, 장비/제작·강화/수리, 집/보관/유품, 지역 여행, NPC 2명의 일정, 채집, 고정·반복 의뢰, 활동 일기, 사망 사건 조사 및 로컬 ENet 기반; 상세는 `docs/PROJECT_STATUS.md`.
- **P1-A 이식 계열**: Chapter I `chapter1_rules`, `chapter1_investigation`, `chapter1_dialogue`, `evidence_board_rules`, `evidence_board_panel`, `chapter1_bridge` 코드 및 단위 테스트 초안.
- **P1-B1 통합 코드**: E키 Chapter I 조사, N키 수첩, `chapter1_inspect` 서버 경로, snapshot의 타인 `story` 제거. 작성된 Godot 스모크 테스트 존재.
- **중요 한계:** P1-B1은 코드 연결 상태이며 **Godot 실행과 실제 게임 통합 플레이는 아직 미검증**이다.

## 개발 중 / 검증 필요

| 순위 | 작업 | 현재 상태·검증 게이트 |
|---|---|---|
| P0 | 문서 기반 브랜치·실행환경 확인 | 본 문서 작성 시 원격 Git 트리/브랜치/PR만 확인. 실제 로컬 상태 미확인 |
| P1 | P1-A/P1-B1 통합 검증 | 신규 `test_chapter1_port_contract.gd`, `test_chapter1_input_integration.gd` 실행 전 |
| P2 | 서사 NPC 대화 UI/서버 세션 | 브리지 코드만 존재; E/N 통합 브랜치 메인에 미연결 |
| P3 | I03/I04/I07 증거 보드·재구성 RPC | 로직·보드 클래스 존재, 실제 UI/RPC 통합 미연결 |
| P4 | 저장/생애 형식 검증·미래/손상 버전·복구 | 새 `story` 필드의 구조 검증 및 안전한 fixture 이관 미완료 |
| P5 | 실제 ENet 재접속·종료 오류 수정 | S 감사에서 `channel 0, max channels: 0` 송신 실패. 통합판에서 원인 미확정 |
| P6 | 게임 회귀 + 수동 플레이 | G 761 검사와 주요 UI/지역/시설/전투/사망 조사 재실행 필요 |

## 아직 미구현인 목표

- 싱글 캠페인 실제 최종 엔딩/본편 멀티 해금 및 공유 허브·지역 인스턴스.
- 세계 전역 자율 NPC 목표·기억·관계 엔진, 세계 사건에서 생성되는 동적 퀘스트.
- 완전한 세계 역사/생애 연대기/권한 있는 Archive UI, 생성형 AI 대화.
- 자유 건축·다중 주택 상속, Steam 인증/운영/클라우드, Windows 실기 출시 검증.
- 제1장 미확정 결말/카엘 장치 조작/이렌 최후는 **저자 승인 전 추론 또는 사실로 고정 금지**.

## 최근 검증 기록 (커밋 분리)

| 대상 | 과거 기록 | 현재 브랜치로 승계 가능? |
|---|---|---|
| G `codex/village-requests@4ba2c21` | 2026-11-22 Codex 감사: 규칙 761 PASS | **아니오** — 변경된 통합판에서 재실행 |
| S `feature/chapter1-evidence-board@f9c4a35` | 헤드리스 279 PASS | **아니오** — 별도 브랜치/코드 |
| S 실제 ENet | **FAIL** — 송신 channel0/max channels0 | 위험 잔존, 재현·수정 필요 |
| P1-A/P1-B1 `feature/chapter1-input-integration` | 코드 파일/QA 스크립트 작성, **실제 Godot 실행 미검증** | 검사 전 완료 판정 금지 |
| 협업 문서 브랜치 | 문서 구조·기존 코드 근거 검토 | 기능 회귀 검사 대상 아님 |

## PR / CI

- 2026-11-22 GitHub에서 확인한 열린 PR: **#1** `docs/vestige-story-concept-v0-3` → main; **#2** `feature/ai-mcp-asset-pipeline` → main. 현재 게임 통합 P1 브랜치에 대해 확인된 공개 PR 없음.
- 기준 브랜치의 전체 Git 트리 조회에서 `.github/workflows/`가 보이지 않았다. **해당 브랜치에 GitHub Actions CI 없음으로 추정**되지만, 조직 외부 CI나 다른 브랜치 설정은 미확인.
- 로컬 미푸시 커밋, 임시 브랜치, 외부 CI/배포 상태는 미확인.

## 결정 필요

1. P1-B1 Godot/ENet 테스트 결과를 확인한 뒤, P1-B2 NPC 세션/보드 연결을 시작할지 결정.
2. G의 집/서재와 S 이렌 집/세라의 위치·명칭·서사 충돌 처리 규칙.
3. 저장 v23에 신규 `story`의 형태 검증 및 오래된 스토리 v1 별도 이관 정책(실제 저장 자동 결합 금지).
4. 사용자 로컬 이동·충돌 복구 스태시의 검토/적용 범위. 무단 pop 금지.
5. Godot 4.5.1 기준을 유지할지 엔진 업그레이드 시 별도 검증할지.
6. 운영 공개/PR 생성/병합/새 콘텐츠 확정은 필요 시 사용자 승인.

## 다음 작업자의 첫 명령

```sh
git fetch origin
git status --short --branch
git log -5 --oneline
git switch feature/chapter1-input-integration  # 로컬 변경이 없는 경우에만
python3 scripts/verify_rules.py
godot --headless --path desktop --script res://tests/test_chapter1_port_contract.gd
godot --headless --path desktop --script res://tests/test_chapter1_input_integration.gd
```

원격의 체크아웃이 곧 개인 로컬 작업 상태가 아니라는 점에 주의. 변경이 있으면 별도 worktree와 fixture로 진행한다.
