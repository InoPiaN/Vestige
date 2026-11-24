# P1-E Godot 4.5.1 실제 CI 실행 검증 보고서

날짜: 2026-11-22 (UTC / KST 같은 날짜)
기준: `ci/chapter1-p1e-godot-verification@9383bd43c7c127172c288b3f3c536493ae67cc3f`
실제 성공 실행: https://github.com/InoPiaN/Vestige/actions/runs/45000435950

## 결과

- **GitHub Actions job conclusion: success**
- OS: Ubuntu 24.04 / Godot 4.5.1.stable.official.f62fdbde1 / Python 3.12.3
- QA runner summary: **8/8 PASS, 0 FAIL**
- 기존 전체 Godot 규칙 실행기: **37개 test_*.gd 스크립트 / PASS 라벨 894개 / FAILURES []**
- 별도 Chapter I 7개 테스트: 각각 PASS, 총 PASS 라벨 133개. 기존 894개에 이미 이 7개 테스트가 포함되어 있으므로 894+133을 독립 검증 수치로 더하지 않는다.
- 증거 출처/저장 v23/.bak 복구/대화/입력/조합/재전송에 대한 헤드리스 회귀 검증은 해당 스크립트가 포괄하는 범위에서만 **verified**.
- 아티팩트: https://github.com/InoPiaN/Vestige/actions/runs/45000435950/artifacts/14744834585 (14일 보존).

| 실행 묶음 | 실제 상태 |
|---|---|
| 기존 `verify_rules.py` | PASS, 894 PASS 라벨, 37개 테스트 스크립트 |
| `test_chapter1_port_contract.gd` | PASS, 16 |
| `test_chapter1_input_integration.gd` | PASS, 11 |
| `test_chapter1_dialogue_integration.gd` | PASS, 18 |
| `test_chapter1_board_integration.gd` | PASS, 16 |
| `test_chapter1_reconstruct_rules.gd` | PASS, 21 |
| `test_chapter1_reconstruct_replay.gd` | PASS, 17 |
| `test_chapter1_save_compatibility.gd` | PASS, 34 |

## 처음 실패한 점과 최소 수정

초기 CI: https://github.com/InoPiaN/Vestige/actions/runs/45000350397 — **6 PASS / 2 FAIL**.

1. 기존 `scripts/verify_rules.py`가 Mac Godot 실행 경로 `.tools/godot/Godot.app/Contents/MacOS/Godot`를 하드코딩함. `GODOT_BIN` 환경변수를 선택적으로 읽도록 변경. 환경변수가 없다면 종전 macOS 경로 유지.
2. `desktop/tests/test_chapter1_input_integration.gd`에서 `var count := player.story.evidence.size()`의 GDScript 타입 추론 실패. `var count: int = int(...)`로 수정.
3. `scripts/run_p1e_qa.py`가 하위 게임 규칙 실행기에도 같은 Godot 바이너리를 환경변수로 전달하도록 변경.
4. Godot 공식 릴리스 4.5.1 다운로드 및 별도 GitHub Actions 경로 지정. 이전 테스트 파일을 삭제하거나 테스트 단언을 약화하지 않았다.

## 성공으로 표시하지 않은 범위

- **실제 2클라이언트 ENet session/reconnect tests 미실행**, S 계열에서 기록된 `channel 0, max channels: 0` 오류 해소 여부 미검증.
- Mac GUI 실사용 E/T/N/F, 카메라·건물 충돌·이렌 집 입구 동선 **미실행**.
- 부하/성능, 운영 클라우드 서버, Steam 연동 **미검증**.
- 실패 조건을 의도적으로 검증하는 `test_chapter1_save_compatibility.gd`는 한 단계에서 `ERROR: 월드 저장 실패` 메시지를 기록할 수 있으나, 해당 검사가 고의 손상 저장 거부를 확인했고 테스트 스크립트 종료 코드는 0이었다. 이를 운영 에러가 사라졌다는 의미로 해석하지 않는다.
- `main` 미병합; 코드 작업 및 CI만 별도 브랜치.

## 후속 최우선

1. 기존 `scripts/verify_requests_network.py` 등 2인 ENet 회귀를 CI/실기에서 같은 커밋으로 실행하고 출력/서버 종료 오류 분석.
2. Chapter I 전용 2클라이언트 (E01/E06/E08, 조합 ID 도용, NPC 선택지 토큰 위조, 재접속) 시나리오 검증.
3. Mac 실제 플레이에서 시작 좌표, 이렌 집/예배당/대장간 충돌과 E/T/N/F 우선권 검사.
4. 확인된 실패를 최소 수정하고 CI를 다시 돌린 뒤에만 main 병합을 검토.

이 보고서는 실행 증거가 있는 사항과 개발 계획을 분리한다.
