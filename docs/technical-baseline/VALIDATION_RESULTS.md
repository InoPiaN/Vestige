# Validation Results
2026-11-22 · macOS / Godot4.5.1.stable.official.f62fdbde1. 아래는 이번 실제 실행 결과다.

| 대상 | 실행 | 결과 | 한계 |
|---|---|---|---|
| G 4ba2c21 | python3 scripts/verify_rules.py | 761 PASS, FAILURES [] | 규칙 회귀. 통합판/Windows/실제 플레이 검사 아님 |
| S f9c4a35 | git archive 임시 복사본의 desktop/tests/test_*.gd 순차 Godot --headless 실행 | 12스크립트279 PASS, 모두 exit0, SCRIPT ERROR 없음 | UI 객체 검사를 포함하지만 실제 화면/조작 확인 아님 |
| S f9c4a35 | python3 scripts/test_desktop_network.py | **FAIL** | 클라이언트 재접속 검사까지 PASS 출력, 서버 로그 ENet 오류로 종료1 |
| 두 계열 | git merge-tree 공통조상 G S | 충돌 표식8경로 확인 | 읽기 전용 예행 분석. 통합 빌드 검사 아님 |

## 실제 네트워크 실패
서버 재시작 후 조사/대화 재접속 시나리오의 클라이언트 검사까지 PASS가 출력됐다. 이후 서버 로그에 다음 오류가 있어 기존 runner가 실패 판정했다.

    ERROR: Unable to send packet on channel 0, max channels: 0
       at: send (modules/enet/enet_packet_peer.cpp:62)
    RuntimeError: Server logged errors

실패 위치는 런너의 마지막 server log 검사다. 연결 해제 시 전송과 peer 수명 경계가 의심되는 조사 대상이지만 원인 확정/수정은 하지 않았다. 재현 최소화와 송신 경로 계측을01단계에서 수행한다. “클라이언트 항목이 통과했으니 멀티 완료”라고 표시하지 않는다.

기존 network_investigation_client.gd는 E01/E05와 대화·서버 재시작을 검사한다. reconstruct/I03/I04/I07 RPC를 직접 호출하는 검사 코드는 기존 network 파일에서 찾지 못했다. 재구성 실제 ENet 전용 검증은 추가해야 한다.

## 독립성·보호
- 테스트 저장은 /tmp 또는 TemporaryDirectory의 합성 월드다. 실제 single-world/shared-world 저장은 열지 않았다.
- S 테스트는 정확한 tip의 git archive 임시 복사본, 네트워크 테스트는 깨끗한 S 원본 커밋 코드로 실행했다.
- G는 기존 깨끗한 0.5.19 작업 트리에서 실행했다.
- main/world 스태시를 적용하지 않았고 .venv-asset를 실행/수정/추적하지 않았다.
- 첫 임시 테스트 준비 스크립트는 호스트 Python의 tarfile filter 미지원으로 게임 실행 전에 종료했다. git archive를 시스템 tar로 푸는 방식으로 수정 후 위12개 검사를 실행했다. 게임 코드 변경은 없었다.
- 문서만 변경하므로 새 실행 패키지 생성/기존 실행본 삭제를 하지 않았다.
- 과거0.5.19 Mac UI17개/서명/두 클라이언트 검증은 이전 기록이며 이번 재실행 항목이 아니다.
- 이전 세 조사 tip은 코드/계보 분석 대상이다.279개는 최신 evidence-board tip에서 실행한 결과이며 각 tip별 재실행이라고 주장하지 않는다.

## 재현
G: codex/village-requests@4ba2c21에서 python3 scripts/verify_rules.py.
S: feature/chapter1-evidence-board@f9c4a35의 별도 임시 복사본에서 각 test_*.gd에 대해 다음 실행:
    
    <Godot4.5.1> --headless --path <임시복사본>/desktop --script res://tests/<파일명>.gd --log-file /tmp/<개별로그>.log

S 네트워크: 해당 tip에서 python3 scripts/test_desktop_network.py. UDP27180 사용, 다른 서버와 겹치지 않게 실행. runner는 임시 저장/서버 프로세스를 정리한다.

evidence/에 이번 요약 로그와 네트워크 전체 로그를 보존했다. 출력의 임시 경로는 사용자 게임 저장 경로가 아니다. 일반 회귀에서 의도된 잘못된 저장 거부 검사는 개별 테스트의 exit/PASS를 기준으로 확인한다.
