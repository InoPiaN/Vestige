# VESTIGE — P1-C 통합 안정화 / 요청-재연결-입력 충돌 인계

기준일: 2026-11-22
- 기준 브랜치: `feature/chapter1-evidence-board-integration`
- 작업 브랜치: `feature/chapter1-integration-hardening`
- 이 작업은 **실제 Godot/ENet 실행 검증 완료가 아님**. 저장소 읽기/정적 계약 검사 및 패치·신규 테스트 작성 상태다.
- `main`, 원래 사용자 저장, 기존 `world.gd`, `world_store.gd`, `investigation.gd`를 변경하지 않았다.

## 1. 발견한 문제와 수정

### NET-01 증거 조합 요청이 무기한 대기

**원인(코드 경로 검토)**: `chapter1_reconstruct`가 과도한 빈도/너무 긴 증거 ID를 받으면 응답 없이 `return`하여, 클라이언트가 `chapter1_board_pending_request`를 해제하지 못하고 UI가 재조합 요청을 무시할 수 있었다.

**패치**:
- `evaluate_chapter1_reconstruct_request(peer,first,second,request_id,now)`로 서버 검사 분리.
- 등록된 peer의 유효한 요청 번호에 대해 속도 제한/길이 초과/권한 실패라도 명시적 거부 응답 생성.
- peer별 마지막 요청 번호를 기록하여 replay/오래된 요청 번호 거부.
- peer별 100ms 간격 제한을 기존 `last_commands`와 분리.
- disconnect/register 시 재구성 요청 기록을 초기화.
- 클라이언트는 해당 pending request ID에 대응하는 응답만 UI에 적용하고 pending을 해제.
- 중복 조합 자체는 기존 `BoardRules.evaluate`의 이미 검증됨 판정을 보존.

**유의**: 이 처리만으로 악의적 네트워크 트래픽에 대한 운영 보안이 완성된 것은 아니다.

### NET-02 연결 해제 이후 서버의 RPC 송신 위험

**원인(잠재 경로)**: 주기적 snapshot 및 명령·대화 응답에서 서버의 `peers` 매핑만 검사하면, 실제 전송 피어가 해제된 뒤에도 `rpc_id`를 시도할 가능성이 있다.

**패치**: `can_send_to_peer(peer)`에서 서버 모드/등록/멀티플레이어 peer 실제 목록을 검사하고, snapshot·서버 명령·대화·증거 조합 reply 전송을 제한. 연결 실패 시 클라이언트의 대화/조합 UI·pending 상태도 정리.

**중요**: S 브랜치에서 보고된 `Unable to send packet on channel 0, max channels: 0` 문제를 **재현하거나 완전히 해결했다고 주장하지 않는다**. 이 검사는 전송 전 기본 방어일 뿐이며, 송신 직전 연결 해제 등의 경쟁 상태가 남을 수 있다.

### INPUT-01 브란/세라 NPC 대화가 E 시설 상호작용을 가리는 문제

**원인(실제 좌표/코드 검토)**: 브란(7,7.5)과 대장간(5,7), 세라(12,4.5)와 서재(10,4) 주변은 시설/스승의 E 상호작용 반경과 NPC 대화 반경이 근접한다. E가 NPC를 우선하면 기존 시설 기능이 가려질 수 있다.

**패치**: E는 기존 시설·스승·상호작용 우선(단, 이미 연결된 제1장 현장 증거 조사는 기존대로 최우선); 해당 지역에서 E가 다른 대상을 가지면 별도 **T키 NPC 대화**로 접근. 주변 표시도 상황별 E/T 또는 T 설명으로 갱신.

**검증 필요**: 실제 플레이어 경로·충돌·각 시설 가까이 E/T 우선순위, T를 누른 동안 다른 모달 열림/전투 간섭 여부.

## 2. 변경 대상과 영향

| 경로 | 변경 요약 |
|---|---|
| `desktop/main.gd` | RPC 재구성 거부 응답/재전송 차단, 전송 피어 검사, disconnect UI 정리, 시설 E/T 우선순위 |
| `desktop/tests/test_chapter1_reconstruct_replay.gd` | 신규 합성 peer: 미등록/중복/속도 제한/긴 ID/타인 소유권/I03 저장 복원 |
| `desktop/tests/test_chapter1_dialogue_integration.gd` | 기존 세라·카엘 테스트에 브란 E 시설 보존/T 대화 경로 추가 |
| `docs/handoffs/chapter1-integration-hardening.md` | 본 문서 |

### 변경하지 않은 것
게임 로직 `world.gd`, v23 저장 `world_store.gd`, G 사망 조사 `investigation.gd`, 기존 `story/chapter1_rules.gd`, I03/I04/I07 추론 규칙, 캐릭터/아이템/경제/주택/여행, 서사 정본.

## 3. 검증 상태

**정적 읽기 기반 확인:** guard/peer 확인/응답/시설 우선/기존 테스트 파일 존재 등 13/13 조건 확인. 구문 파싱이나 Godot runtime 검증은 아니므로 이것을 Godot 13 PASS로 보고하지 않는다.

**신규/기존 Godot 테스트 실행:** **모두 미실행**. 현재 ChatGPT 도구 컨테이너에는 `godot`·`godot4` 실행 파일이 없으며 git remote URL의 네트워크 DNS도 연결되지 않았다. GitHub connector로 파일 열람·패치·커밋 비교만 수행했다.

**ENet 실제 재접속/2인 E2E:** 미실행. 기존 S 감사의 server log 오류는 미해결 위험으로 유지.

## 4. Codex 재현·검증 우선순위

개발자 로컬 작업물·스태시·사용자 원본 저장을 보호하고 별도 worktree와 `/tmp` QA 저장으로 실행한다.

```sh
git fetch origin
git status --short --branch
git worktree add ../vestige-p1c feature/chapter1-integration-hardening
cd ../vestige-p1c
python3 scripts/verify_rules.py

godot --headless --path desktop --script res://tests/test_chapter1_port_contract.gd
godot --headless --path desktop --script res://tests/test_chapter1_input_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_dialogue_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_board_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_reconstruct_rules.gd
godot --headless --path desktop --script res://tests/test_chapter1_reconstruct_replay.gd
```

### 반드시 수동·네트워크 테스트

1. G 기존 761 규칙, 제작·전투·마을 의뢰·주택/유품·지역 탐험 회귀. 새로운 검사 결과로만 PASS 기록.
2. E01 현장 조사 → N 수첩 → E05/E07 + I03 → 세라 대화 → 저장/로드. E06/E08 I04, E07/E13 I07도 확인. 미확정 결말은 해금하지 않는다.
3. 브란/세라 주변 E로 시설·스승 진입, T로 대화, 카엘 E/T 대화; 모든 모달 및 공격·회피/이동 차단 확인.
4. ENet 서버+두 클라이언트: 타인 `story` snapshot 비공개, 타인 증거 ID로 조합 거부, 서버 위치·생애·접속 상태, token/선택지 위조 방지, 중복/과속/긴 증거 ID 응답 및 UI pending 해제, reconnect/logout 후 공개 범위/기록 보존.
5. **네트워크 오류**: 서버 재시작·연결 해제 직후 reliable reply/snapshot, 서버 종료 패킷 송신 반복 재현. 기존 송신 오류가 남으면 FAIL 유지하고 최소 재현 로그/stack path 보존.
6. Windows 실기 및 장시간 성능은 별도 검증. Godot 엔진 버전은 감사 기준 4.5.1 우선.

## 5. Codex 다음 작업

- 우선 위 검사들의 **실제 실패를 수집**하고 최소 패치로 고친 뒤 동일 명령으로 재실행.
- `can_send_to_peer` 실제 ENet 순서가 로그 오류를 막는지 확인. 실패하면 실제 송신 경로·disconnect lifecycle 분석 후 변경 계획 수립.
- 저장 v23의 새 `story` 필드 형식 검증/오래된 스토리 이관은 **구조 정책 승인 필요** 항목이며 임의 대규모 마이그레이션 금지.
- 테스트 삭제/하향으로 PASS시키지 않는다. `main` 병합·원본 저장 편집·운영 배포는 별도 승인 없이 금지.

## 참고 문서

- 이전 작업: `docs/handoffs/chapter1-evidence-board-integration.md`, `chapter1-dialogue-session.md`
- AI 공통 규칙(별도 문서 브랜치): `docs/ai-collaboration-governance` → `AGENTS.md`, `DEVELOPMENT_WORKFLOW.md`, `PROJECT_STATUS.md`.
