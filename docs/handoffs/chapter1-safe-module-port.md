# VESTIGE 제1장 안전 이식 — Codex 인계

- 기준 브랜치: `codex/village-requests` (G 0.5.19 / 저장 v23)
- 작업 브랜치: `feature/chapter1-safe-module-port`
- 조사 출처: `feature/chapter1-evidence-board` (S)
- **완료 범위:** 제1장 규칙·고정 증거·NPC 대화·증거 조합 UI 모듈을 이름 충돌 없이 이식, 월드 v23 적합성용 독립 테스트 초안 추가
- **미완료 범위:** 게임 월드/메인 UI/RPC 연결, 실제 월드 동선·충돌 검증, 신규 저장 마이그레이션, Godot·ENet 실실행 테스트
- **원칙:** 구현된 파일이 있다고 해서 전체 챕터가 플레이된다는 뜻이 아니다. 이 브랜치를 main에 병합하지 않는다.

## 이식한 모듈

| 신규 경로 | 출처 및 변경 |
|---|---|
| `desktop/story/chapter1_rules.gd` | S의 챕터 상태/증거 논리 ID/추론/관계 규칙 유지 |
| `desktop/story/chapter1_investigation.gd` | S의 E01/E05/E06/E07/E08/E13 조사 기능; 기존 `desktop/investigation.gd` **보존** |
| `desktop/story/chapter1_dialogue.gd` | S의 브란·세라·카엘 증거 조건 대화; 내부 preload를 챕터 조사 경로로 변경 |
| `desktop/story/evidence_board_rules.gd` | I03/I04/I07 두 증거 조합 검증 |
| `desktop/story/evidence_board_panel.gd` | 기존 보드 UI 클래스 유지 |
| `desktop/story/chapter1_bridge.gd` | G 월드에 맞춘 village 영역/생존/online 게이트 및 호출용 얇은 어댑터 |
| `desktop/tests/test_chapter1_port_contract.gd` | 저장 v23과 증거/지역 격리의 테스트 초안 |

## 안전 경계

1. G의 `desktop/investigation.gd`는 사망 사건·유품·증거 아이템 전용이다. **교체하지 않는다**.
2. 새로운 제1장 기록은 `people[id].story` 아래에 보관한다. 이는 G의 `notebook`과 별개다.
3. `Chapter1Bridge.prepare_person`은 새 생애/기존 저장 모두에 대해 호출 가능한 보완 함수다. G의 `World.born`이나 `World.outfit`은 이번 변경에서 수정하지 않았다.
4. 직접 조사·대화·조합은 `room == village`, 살아 있고 접속된 인물만 가능하다. 지역별 좌표가 중복되어도 외부 지역에서 조사 불가.
5. Chapter1Bridge.talk은 인증된 NPC 대화 세션을 **스스로 인증하지 못한다**. 네트워크에서는 반드시 서버 관리 세션, 거리, request_id, 세션 만료/종료를 추가한다. 특히 E08을 일반 클라이언트 명령으로 직접 생성하지 않는다.
6. 데이터 보존을 위해 G의 `world_store.gd` 저장/복구 경로를 유지하고 실제 사용자 저장 파일은 테스트에 사용하지 않는다. 통합 후 story 필드의 구조 검증을 추가하는 작업이 필요하다.
7. 캐릭터 사망 후 재생성 시 이전 `story`를 자동 계승하지 않도록 한다. 단, 생애 기록은 별도 역사 저장과 연결할 수 있다.
8. S의 증거 좌표는 G 월드의 집·건물·충돌 영역과 아직 통합되지 않았다. 동일 좌표 도달성과 E키 우선순위는 수동+헤드리스 검증이 필요하다.
9. 카엘의 장치 조작·사건 책임과 이렌의 최후는 **미확정**이다. 추가 증거를 만들어 엔딩을 임의 개방하지 않는다.
10. 모듈 이식은 병합 전 단계로, **실제 ENet 송신 오류가 아직 남아 있다**. 서버 로그의 `channel 0, max channels: 0` 경로를 재현·점검해야 한다.

## Codex가 이어서 할 일

**01-B 연결 전 검증**
1. `godot --headless --path desktop --script res://tests/test_chapter1_port_contract.gd` 실행해 G 0.5.19 기반 정합성을 확인하고 실패 시 최소 수정.
2. G의 테스트 `python3 scripts/verify_rules.py` 실행하고 회귀를 보존한다.
3. 마을 내 이렌 집(16,6) 및 조사 지점의 이동 가능성, 대장간·서재의 E 우선순위를 확인한다.
4. G의 World.born/outfit/load_world에 연동할 위치를 설계한다. 일단 save v23 변경을 피하고 단계별 fixture를 사용한다.

**이후 분리된 구현 커밋**
- E/N 조사 진입점을 기존 E 상호작용과 충돌 없이 연결
- 서버 관리 NPC 대화 세션과 Chapter I 선택지 연결
- 증거 보드 2개 조합 I03/I04/I07 검증
- 새 생애/story 보존·redact 정책 보완
- ENet 재연결/서버 종료 송신 오류 회귀 해결

**통과하지 않은 검증을 완료로 표시하지 말 것.** Godot 실행, ENet, 실기 플레이, 저장 마이그레이션은 이 변경만으로 해결되지 않았다.

## 설계 참조

`VESTIGE_Design_Knowledge_v2_6_Architecture_Diff.zip`의 `architecture_diff/` 및 `vertical_slice/`.
