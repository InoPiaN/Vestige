# VESTIGE P1-B3 — N 수첩 기반 증거 조합 보드 + 서버 검증 RPC

2026-11-22 · 기준 `feature/chapter1-dialogue-session`, 작업 브랜치 `feature/chapter1-evidence-board-integration`.

## 작업 결과

**구현 코드 (실행 미검증):** 기존 S에서 이식한 `evidence_board_panel.gd`와 `evidence_board_rules.gd`를 G 게임 `main.gd`에 연결했다. N키 수첩에서 별도 '제1장 · 증거 두 개 조합하기' 버튼으로 보드를 열 수 있다.

```text
N 수첩 / 발견한 E 기록 (개인 소유)
  -> 사건 재구성 버튼 / evidence_board_panel.gd (2 logical IDs)
  -> single: Chapter1Bridge.reconstruct
  -> client: chapter1_reconstruct(first,second,request_id) RPC
  -> server: peer identity, village, life/alive/online, personal evidence ownership
  -> evidence_board_rules.gd: exact pairs, source links, idempotent inference
  -> personal story.chapter1.inferences + G version23 save
  -> only submitting peer gets reply and refreshed redacted snapshot
```

- 제한적 증거 조합: **I03 = E05+E07**, **I04 = E06+E08**, **I07 = E07+E13**. 순서 반전도 허용하며 증거 두 개는 서로 달라야 한다.
- `Chapter1Bridge.reconstruct` 및 기존 `BoardRules.evaluate`를 그대로 사용하여 서버가 미보유 증거/중복/불일치 결합을 거부한다.
- 클라이언트는 논리 증거 ID 두 개만 보낸다. 서버가 `peers[peer]`로 인물 정체성을 결정한다. response는 요청 ID로 현재 pending request와 대조해 지연된 응답을 표시하지 않는다.
- `accepted=true`일 때에만 단독 저장을 수행한다. 기존 G 저장 version 23 유지. 타인의 story는 기존 snapshot redaction으로 계속 제거한다.
- 보드가 열려 있을 때 이동·Tab/다른 단축키 입력을 막고 ESC/닫기를 통해 N 수첩으로 돌아온다. **기존 E 조사, F 사망 조사, L/K/M/I 등 모달, NPC 대화 등 다른 진입점은 유지**한다.
- 빈 증거 보드의 첫 열기에서 안내 문구가 누락되던 `fingerprint` 초기값을 보정했다.
- 신규 Godot 테스트 두 개를 만들었다. **테스트 추가와 PASS는 다르다.**

## 변경 파일

| 경로 | 영향 |
|---|---|
| `desktop/main.gd` | 수첩 → 보드 UI, 클라이언트 RPC → 서버 authority → 응답/저장, 입력 모달 |
| `desktop/story/evidence_board_panel.gd` | 첫 열기 때 빈 증거 안내 갱신 |
| `desktop/tests/test_chapter1_board_integration.gd` | N/보드 UI, E05+E07, 중복/저장/복귀 |
| `desktop/tests/test_chapter1_reconstruct_rules.gd` | 다중 인물 증거 격리, 지역 제한, I03/I04/I07, 챕터 미완료 확인 |
| `docs/handoffs/chapter1-evidence-board-integration.md` | 이 문서 |

**무변경:** `desktop/world.gd`, `world_store.gd`, `investigation.gd`, `chapter1_rules.gd`, `evidence_board_rules.gd`, 사용자 저장, main.

## 검증 결과 (구분 필수)

- 코드 패턴/참조 경로의 **정적 확인 11/11 PASS** — 이 결과는 Godot 컴파일·테스트 PASS를 의미하지 않는다.
- 새 GDScript 두 개는 작성되었지만 **Godot 실행 환경 부재로 미실행**.
- 기존 게임 G 761 / 스토리 S 279 과거 결과는 각 **기존 코드 브랜치**에 한정되며 현재 통합판에 재적용 불가.
- **실제 ENet 실험·두 클라이언트·지연 응답·네트워크 오류 재현 미실행.** 이전 `channel 0, max channels: 0` 실패는 여전히 위험 요인.

## Codex 실행 순서

기존 사용자 월드를 사용하지 말고 격리된 임시 fixture/worktree에서 Godot 4.5.1을 사용한다.

```sh
git fetch origin
git status --short --branch
# 원본 작업/스태시 보호 후 별도 worktree 등에서 checkout
python3 scripts/verify_rules.py
godot --headless --path desktop --script res://tests/test_chapter1_port_contract.gd
godot --headless --path desktop --script res://tests/test_chapter1_input_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_dialogue_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_board_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_reconstruct_rules.gd
```

**수동 시나리오**
1. N → 사건 재구성, 증거 없는 상태 안내/조합 거부/ESC 복귀, E 반복 기록 중복 방지.
2. E05+E07 → I03 단 한 번, E06+카엘 진술 E08 → I04, E07+E13 → I07; 순서 뒤집기, 비매칭, 동일 선택, 이미 기록한 추론 거부.
3. 재접속/저장/새 삶 이후 `story`와 생애 격리; I06과 최종 결말은 미확정.
4. 두 ENet 클라이언트: A만 가진 증거를 B가 ID만 전송해도 조합 불가, 인증 peer/region/거리/생애 검사.
5. 고의로 요청 ID를 중복·지연·순서 변경; 클라이언트 표시가 현재 요청 외의 응답으로 오염되지 않는지 검사.
6. 게임 전체 이동·시설·NPC 대화·수첩·F 조사·장비·제작 회귀, 실제 NPC/증거 위치 도달성.
7. 이전 S ENet 서버 송신 오류를 최소 재현하여 수정할 때까지 네트워크 성공으로 보고하지 않기.

## 알려진 위험 / 다음 작업

- **가장 먼저** 실제 Godot 파싱 실패나 새 테스트 실패를 수정한다. 테스트를 삭제/완화해 통과시키지 말 것.
- `chapter1_reconstruct`는 `request_id`와 pending response를 사용하지만 서버 요청 단위 중복 시퀀스의 별도 기록은 아직 없다. 규칙의 추론 재적용 금지가 결과 중복을 제한하지만, 네트워크 E2E 검증은 필수.
- 보드 열기 권한은 Chapter1Bridge의 village/alive/online에 종속된다. 장소 스케치·충돌/선택 UI 가독성은 실기 확인 필요.
- 네트워크 세션 토큰은 NPC 대화용; 증거 보드에서는 각각 검증된 개인 조사 기록을 기준으로 별도 서버 정본 판정한다.
- 차기 단계는 **통합 안정화 및 저장/ENet 회귀** 우선. 새로운 이렌 사건 결말과 생성형 AI 개발은 승인/선행 검증 이전에는 추가하지 않음.

## 협업 규칙

`docs/ai-collaboration-governance` 브랜치의 `AGENTS.md`, `ARCHITECTURE.md`, `DEVELOPMENT_WORKFLOW.md`, `PROJECT_STATUS.md`를 함께 참조한다. 이 문서 전용 브랜치와 코드 브랜치의 역할을 혼동하거나 무작정 병합하지 않는다.
