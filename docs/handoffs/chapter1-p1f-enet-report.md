# VESTIGE P1-F — 실 ENet 2클라이언트·재접속 검증 결과

- 기록일: 2026-11-22
- 브랜치: `ci/chapter1-p1f-enet-two-client`
- 검증 커밋: `e779967ebc7c8a577c93514b1228f576a2a64bd5`
- 실제 성공 실행: https://github.com/InoPiaN/Vestige/actions/runs/45009079062
- 로그 아티팩트: https://github.com/InoPiaN/Vestige/actions/runs/45009079062/artifacts/14748504367
- Godot 4.5.1.stable.official.f62fdbde1 / GitHub Actions Ubuntu 24.04

## 실제 실행 결과

### P1-E 단위/회귀
- `scripts/run_p1e_qa.py` 8/8 실행 묶음 **PASS**, 0 FAIL.
- 기존 `scripts/verify_rules.py` GDScript 테스트에서 `TOTAL 894 FAILURES []`.
- Chapter I 7개 독립 호출 테스트 모두 PASS. 기존 전체 검사에도 포함되므로 중복 합산 금지.

### P1-F 실 ENet

**PASS** — 별도 Godot 프로세스로 임시 월드 fixture 생성→ENet 서버 1개→클라이언트 A와 B 동시 접속→A 연결 종료 후 동일 캐릭터 A 재접속.

| 검사 | 결과 및 한계 |
|---|---|
| fixture 생성 | PASS, 새 /tmp 월드만 사용 |
| 클라이언트 A 기본 게임·스토리 snapshot | PASS, 소유한 E05/E07 기록 보유 |
| 타인 `story` 비공개 | PASS, 양쪽 snapshot에서 타인 개인 기록 없음 |
| A의 E05+E07 → I03 | PASS, 서버가 본인 소유 증거만 사용해 추론 승인 |
| B가 A 증거 ID로 조합 시도 | PASS, B에게 해당 추론/증거 없음 |
| A의 이동 RPC→세라 접근 | PASS, 근접 거리 조건 확인 |
| NPC 대화 대상 및 세션 | PASS, 서버가 Sera 선택·세션 토큰 전달 |
| 잘못된 대화 토큰 | PASS, 소문 상태 미변경 |
| 정상 대화 선택지 | PASS, 세라 소문의 출처 제한 기록 및 기존 I03 유지 |
| 세션이 열린 상태로 A 종료 | 테스트 수행, 서버 disconnect 처리 후 재접속 |
| 동일 캐릭터 A 재접속 | PASS, E05/E07·I03·소문 복원 |
| 재접속 UI | PASS, 이전 클라이언트 대화 토큰·화면 미복원 |
| 재접속 시 가짜 대화 선택 | PASS, 기록 손상/미확정 결말 해금 없음 |
| 서버/client `SCRIPT ERROR` | 검출 0 |
| `Unable to send packet` | 검출 0 |
| 서버 종료 | 테스트 종료 시 의도적 SIGTERM(code -15). 정상적인 게임 내 graceful shutdown까지 검증한 것은 아님 |

수정 전 첫 ENet 실패(run 45008432587)는 A가 재구성 응답을 받은 직후 snapshot 수신 전에 상태를 읽은 테스트 동기화 문제.
두 번째 ENet 실패(run 45008541309)는 A가 접속하기 전 서버의 offline-life 시뮬레이션으로 NPC와의 거리가 벌어진 탓. 실제 위치까지 `movement` RPC로 걸어간 다음 NPC 대화를 실행하도록 테스트 수정. 네트워크 서버 판정을 느슨하게 바꾸지 않았음.
`45008924067`에서 A/B 동시 검사가 PASS했고, `45009079062`에서 재접속 단계까지 PASS.

## 변경 사항

| 파일 | 변경 |
|---|---|
| `desktop/tests/network_chapter1.gd` | fixture, A/B 실제 ENet 교환, 소유권, NPC 토큰, 서버 이동, 재접속 상태 검증 |
| `scripts/run_p1f_enet.py` | 서버·2 클라이언트·재접속 프로세스 조율, 개인 사용자 영역 HOME/XDG 격리, 자동 정리, 실패 로그·JSON 결과 기록 |
| `.github/workflows/chapter1-p1e-qa.yml` | 기존 Godot QA 뒤 ENet 2인/재접속 실실행 추가, 실패해도 아티팩트 보존 |
| `desktop/main.gd` | P1-F 진단용 임시 trace를 넣었다가 제거. **최종 게임 동작 변경 없음** |
| `docs/handoffs/chapter1-p1f-enet-report.md` | 본 문서 |

## 현재 확인하지 못한 범위

- 이 성공은 **fixture와 이 실행 커밋의 ENet 시나리오**에 한정됨. S 원래 브랜치의 `channel 0, max channels: 0` 실패를 모든 시점·모든 네트워크 상황에서 없앴다는 보증 아님.
- 게임 UI 실제 플레이·Mac 렌더링·캐릭터 최초 생성 및 이렌 집 입구 충돌 확인 미실행.
- 서버 `SIGTERM` 후 로그에는 송신 에러가 없었지만, RPC 송신 직후 연결 해제·graceful 종료 경쟁 상태를 반복 부하 테스트한 것은 아님.
- 운영 인증/계정 소유 검증: 프로토타입 ID 토큰을 신뢰하는 방식이며 외부 인증 보안 검증 없음.
- 네트워크 지연/패킷 손실/요청 재정렬 및 적대적 클라이언트 주입 기반 침투 테스트는 별도 필요.
- 정본 사건 진실·카엘 책임·이렌의 최후 미확정 유지.

## Codex 후속 작업

1. 이 브랜치의 GitHub Actions 로그/아티팩트를 읽고 `p1f-report.json` 및 A/B/reconnect/server 로그 검토.
2. 로컬 macOS Godot 4.5.1에서 같은 `python3 scripts/run_p1f_enet.py --godot /path/to/Godot --logs /tmp/vestige-p1f` 재실행.
3. 게임 첫 시작 위치, 이렌 집·예배당 동선, E/T/N/F, NPC 상호작용 HUD, 수동 저장/재실행 확인.
4. 종전 S branch ENet 종료 직후 송신 문제는 별도 반복 시나리오로 회귀. 데이터 보존·작업 브랜치 분리 준수.
5. `main` 병합·배포 전에 네트워크 성능, 계정 인증/보안, 실제 Mac UI 검증 계획에 사용자 승인 필요.

## 작업 상태

- `implemented`: 전용 네트워크 fixture, ENet 실행기, CI 워크플로.
- `verified`: P1-E 8/8 + P1-F fixture 서버/2클라이언트/재접속의 열거된 동작.
- `not_verified`: GUI 수동 플레이, 반복 graceful shutdown, 인터넷 환경 멀티, 보안 인증.
- `git`: 기능 CI 브랜치에만 커밋/푸시, `main` 병합/PR 없음.
