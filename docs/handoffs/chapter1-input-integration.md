# P1-B1 제1장 조사 E/N 연결 — 인계

기준 `feature/chapter1-safe-module-port`, 대상 브랜치 `feature/chapter1-input-integration`.

## 이번 커밋으로 연결한 부분

- `desktop/main.gd`가 `Chapter1Bridge`와 Chapter I 증거 정의를 읽는다.
- 잿불 마을에서 E키를 누르면 1.125 반경 내 제1장 증거가 먼저 검토된다. 다른 지역/실내에서는 기존 시설·조사 기능이 그대로 우선한다.
- 클라이언트는 `command("chapter1_inspect", evidence_id)` intent만 서버에 제출한다. 서버의 Bridge가 실제 인물 상태, 지역, 거리, 중복, 늑대 게이트를 다시 확인한다.
- 싱글도 같은 Bridge 경로를 호출한다. 수집 후 기존 `Rules.save_world`를 사용한다.
- N키는 `Chapter1.notebook` 읽기 화면을 표시한다. 다른 모달 위에 무작정 열지 않으며 현재 조사 화면에서 다시 N을 누르면 닫힌다.
- `send_snapshot`에서 다른 플레이어 `story`를 제거해 비공개 조사 단서를 전송하지 않는다. 기존 사망 조사/유품 필터는 그대로 사용한다.
- 신규 smoke test: `desktop/tests/test_chapter1_input_integration.gd`.

## 상태

이 작업은 **P1-B1 E/N 입력 연결**이다. NPC 선택지 UI, 대화 세션, I03/I04/I07 네트워크 조합 연결은 **미구현**. 전체 P1-B 완료라고 표시하지 않는다.

**실행 미검증**: 이 변경 환경에는 Godot 바이너리가 없었다. 코드 읽기·브랜치 diff 검사만 완료했다. 신규 테스트는 계획/실행 스크립트이며 PASS 결과가 아니다.

## Codex 실행 순서

1. 실제 사용자 저장 파일 대신 임시 사본/별도 Godot user data 폴더를 사용한다.
2. Godot 4.5.1 기준 `godot --headless --path desktop --script res://tests/test_chapter1_port_contract.gd`.
3. `godot --headless --path desktop --script res://tests/test_chapter1_input_integration.gd`.
4. `python3 scripts/verify_rules.py` 기존 G 761항목 회귀 재실행.
5. 게임 싱글에서 이렌의 집 책장 E → N 기록 확인, 반복 E, 다른 지역 같은 좌표, 건물 충돌·접근성, 기존 F 사망 조사, E 대장간/서재/집, I/B/M/L/K 키 영향 점검.
6. 멀티에서는 서버와 클라이언트가 정확히 같은 커밋인지 확인. 2인 조사에서 타인 story 필드 미전송, 서버 거리 검증, 저장/재접속을 검사한다.
7. S에서 보고된 ENet channel0/max channels0 오류를 별도 재현·수정한다. 실제 네트워크 검증 전까지 멀티 완료로 표시하지 않는다.

## 보류·주의

- NPC 실제 대화는 후속 P1-B2에서 *서버 소유 세션과 선택지 권한*을 먼저 구현한 다음 연결한다. `Chapter1Bridge.talk`을 임의 클라이언트 명령에 직접 연결하면 안 된다.
- 제1장 종결을 강제로 열지 않는다. 미확정 카엘 책임/이렌의 최후를 확정하지 않는다.
- 기존 G 사망 사건 `desktop/investigation.gd`를 덮어쓰지 않는다.
- 저장 v23을 임의로 증가시키지 않았지만, 새 `story` 필드에 대한 별도 형태 검증과 손상된 데이터 거부는 후속 작업이다.
- `Chapter1Investigation.nearby`는 증거 좌표만 판단한다. 기존 건물과 길찾기 충돌로 접근 불가능한 장소가 있는지 실제 플레이가 필요하다.
- `main.gd` 기존 ENet 연결 수명 오류와 다른 패널/제작 기능은 수정하지 않았다.
