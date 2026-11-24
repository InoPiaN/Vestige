# VESTIGE P1-B2 — 제1장 NPC 대화 세션 통합 인계

작성: 2026-11-22. 코드 기준 `feature/chapter1-dialogue-session`, 원본 `feature/chapter1-input-integration`.

## 작업 요약 / 범위

- **구현 코드 추가**: E키로 브란·세라·카엘과 접촉, 기존 종이 기록 모달 내부 선택지 버튼, 게임 내 싱글 대화 결과 저장, ENet 서버 전용 대화 세션/허용 선택지/범위/생애 검증.
- **보존**: E키 증거 조사 우선, F키 사망 사건 조사, N 수첩, G 0.5.19의 `world.gd`, `world_store.gd`, 장비/제작/시설/지역/스태시 및 원래 저장 v23.
- **미포함**: 증거 보드 I03/I04/I07 E2E UI, 범용 NPC 장기 기억, 대화 LLM, 스토리 진실 확정, ENet 기존 송신 버그 수정.

## 영향 분석 / 주요 코드 경로

`Player E -> main.interact -> Chapter1Bridge.nearby_npc -> local talk OR server RPC open -> Chapter1Bridge.talk -> Dialogue.talk -> personal story + p.events -> existing World.save_world`.

- `desktop/main.gd`: NPC 상호작용 분기와 `show_chapter1_dialogue`, 버튼 제어, RPC `chapter1_dialogue_open/choose/end/reply`, 서버 세션 `dialogue_sessions`.
- `desktop/tests/test_chapter1_dialogue_integration.gd`: 싱글 기준 세라/카엘 대화, UI/선택지, 소문 1회 기록, 다른 지역 차단, 저장 v23 복원 테스트.
- `desktop/story/chapter1_bridge.gd`, `chapter1_dialogue.gd`: **변경 없음**, 기존 거리/생존/월드 지역 제한 및 출처를 그대로 사용.
- `world.gd`, `world_store.gd`, `investigation.gd`: **변경 없음**.

### 서버 검증

1. 클라이언트는 NPC ID를 보내지 않고 **대화 시작 의도만** 보낸다. 서버가 실제 위치에서 1.125 타일 안의 NPC를 찾는다.
2. 접속 peer별로 생애 ID, NPC ID, 난수 토큰, 당시 허용 선택지 ID, 만료시각(60초)을 서버 메모리에 보관한다.
3. 선택 명령마다 token/peer/생애/지역/거리/만료/이전 허용 선택지를 검사한 후에만 `Dialogue.talk` 실행.
4. 대화 중 서버는 입력 이동 방향을 0으로 유지; 종료·로그아웃 시 세션 삭제.
5. `kael_token` 선택은 해당 플레이어가 E06을 획득한 경우에만 허용. E08은 기존 `Dialogue.talk` 경유, 미확정 진실 보호.
6. 초기 인사·소문 등 변경 사항은 기존 저장 v23에만 기록; 계정/타인에 자동 공유하지 않음.
7. UI는 ESC, N, 닫기 버튼으로 대화 종료. 기존 다른 모달을 대화 위에 열지 않도록 제한.
8. 대화 시작 요청은 서버에서 짧은 간격 제한(250ms).

**위 1~8은 코드상 도입된 규칙이다. Godot·ENet 실행 확인 전까지 verified가 아니다.**

## 테스트 실행 계획 (Codex)

깨끗한 독립 worktree와 시험용 월드 경로를 사용. 실제 `single-world.json`, `shared-world.json` 보존.

```sh
python3 scripts/verify_rules.py
godot --headless --path desktop --script res://tests/test_chapter1_port_contract.gd
godot --headless --path desktop --script res://tests/test_chapter1_input_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_dialogue_integration.gd
```

### Godot 수동 QA

- 잿불 마을 세라 E → 소문 → 다시 소문(이벤트 1회) → ESC 종료 → 재진입/저장 후 계속.
- 브란 근처 E 대화 → 대장간 시설 조작 접근이 가려지지 않는지 확인.
- 카엘 E → E06 없이 금속 표식 선택 불가 → E06 수집 후 해당 선택 가능 → E08은 **진술**로만 기록.
- 마을 밖/집 실내, 사망·부재 인물은 대화 불가. 플레이어는 다른 지역의 같은 좌표에 있어도 해당 NPC와 대화할 수 없어야 한다.
- 대화 중 공격·회피·지역이동, N/ESC, L/M/I 등 UI 간섭과 신규 인물의 기록 초기화 검사.
- 실제 인물 이동으로 NPC 좌표에 도달 가능한지 확인.

### 멀티(최우선)

- 두 ENet 클라이언트 접속, 서버와 동일 커밋 사용; 두 인물이 NPC 근처에서 각각 대화.
- 서버 응답의 token과 이전에 수신하지 않은 선택지 ID를 위조해 제출해도 상태가 변하지 않아야 한다.
- 다른 플레이어가 얻은 E06/E08을 자신이 소유하지 않았을 때 선택할 수 없어야 한다.
- 세션 중 다른 지역 이동/거리 이탈, peer disconnect, 만료, token 재사용/중복 요청을 검사.
- 서버 재시작/재접속: 원래 대화 **세션은 복원되지 않아야** 하지만 확정된 개인 이벤트/증거 기록은 복원되어야 한다.
- snapshot에서 다른 사람의 `story`가 제거되어야 한다.
- **이전 S 계열 ENet FAIL**: `Unable to send packet on channel 0, max channels: 0` 재현 및 송신/종료 경로 수정 전까지 네트워크 완료 표시 금지.

## 미실행/위험

- 이번 개발 도구 컨테이너에 Godot 바이너리가 없어 **실제 Godot 파싱, GDScript 테스트, ENet 테스트, Mac 실기 테스트 모두 미실행**.
- 서버 RPC 재접속 경계, 입력 보안·세션 TTL UX, 저장 v23의 추가 story 구조 검증, 실경로 NPC 접근성은 검증되지 않았다.
- 그 밖의 `main.gd` 공용 입력·패널 코드와의 부작용은 실제 플레이/회귀 검사 필요.
- 실 사용자 파일, 운영 서버, `main` 브랜치, 새 콘텐츠/서사 원본은 변경하지 않음.

## 업무 인수인계 / 다음 순서

1. **먼저 테스트**: 현재 작업 브랜치에서 Godot 파싱 + 3종 계약/통합 검사 + 기존 규칙.
2. 실패가 있으면 테스트를 삭제하지 않고, 최소 수정 후 동일 브랜치에 커밋/인계.
3. 실제 ENet 2인 세션·위조/만료 검증 및 기존 송신 버그 재현.
4. P1-B3 증거 조합 보드(I03/I04/I07) 및 재구성 RPC 설계·구현은 위 단계 안정화 후.
5. 새 장기 기억/AI 대화는 별도 범위이며 이렌의 최후·카엘 책임을 임의 확정하지 않음.

### 협업 규칙

이번 기능 브랜치에는 공통 `AGENTS.md`가 아직 병합되지 않았을 수 있으므로 `docs/ai-collaboration-governance` 브랜치의 `AGENTS.md`, `DEVELOPMENT_WORKFLOW.md`, `PROJECT_STATUS.md`, `ARCHITECTURE.md`를 함께 참조한다. 문서 브랜치를 다른 기능 브랜치에 무작정 병합하지 않는다.
