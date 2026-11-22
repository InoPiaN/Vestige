# P1-D — Chapter I 저장 v23 호환성·손상 차단·백업 복구

**기준:** `feature/chapter1-integration-hardening`
**현재 작업:** `feature/chapter1-story-save-validation`
**날짜:** 2026-11-22

## 1. 기존 코드 확인

- `desktop/world.gd`의 `World.save_world/checkpoint/load_world`는 `world_store.gd`에서 월드 전체를 검증한 후 `.tmp`·`.bak`을 관리한다.
- `world_store.gd`의 `valid/history_valid`는 기존 G 게임 숫자·장비·노트·집·사망 사건을 검사했으나 새 Chapter I `people[id].story` 내부 구조는 검사하지 않았다.
- `story/chapter1_investigation.gd.ensure`와 `chapter1_rules.gd.ensure`는 누락/타입 오류 필드를 보완하는 함수다. **저장 원본을 먼저 유효성 검사하지 않으면 손상된 증거/추론이 정리·교체될 위험**이 있다.
- G의 `version=23`과 S의 독립 `version=1` 월드 파일은 서로 다르다. S 파일을 G에 무단 합치지 않는다.

## 2. 변경 내용

| 파일 | 변경 |
|---|---|
| `desktop/story/chapter1_save_contract.gd` | **신규 검증기:** story 없는 저장 허용, 있으면 타입·증거 ID·발견 순서·시간·사실/추정 출처·논리 매핑·추론 조건·NPC 관계·결정 구조 확인 |
| `desktop/world_store.gd` | 기존 `Store.valid` 내 사람별 검사에 `StorySaveContract.valid_person` 1개 검증 단계만 추가 |
| `desktop/tests/test_chapter1_save_compatibility.gd` | story 없는 v23/v22, E01 저장, 손상 입력 차단, .bak 복구, 사실/출처 위변조·미지원 I06·미지원 스키마·미래 저장 버전 거부, 보존·중복 로드 테스트 |
| `docs/handoffs/chapter1-story-save-validation.md` | 본 인계 및 검증 상태 |

### 정책 — 자동 데이터 삭제/수정 없음

1. **기존 `story` 필드가 없는 1~23 저장은 이전처럼 허용**한다. 제1장 기록을 임의 생성하지 않는다.
2. `story`가 존재하면 알려진 Chapter I 데이터 구조를 검사하고, 오류가 있으면 `Store.valid`에서 거부한다.
3. 저장 함수는 잘못된 새로운 데이터로 기존 원본을 덮어쓰지 못한다. 기존 로더는 잘못된 primary 대신 유효한 `.bak`을 검사한다.
4. primary/backup 모두 유효하지 않으면 `World.load_world`는 빈 Dictionary를 반환하고 실제 게임 UI는 오류를 표시한다. **자동 fresh/reset로 파일을 대체하지 않는다.**
5. version 23은 바꾸지 않는다. S의 독립 v1 세계를 G v23에 자동 합치는 마이그레이션은 만들지 않았다.
6. 미확정 I06, 신원 확인, 카엘의 책임·이렌의 최후를 생성하거나 확정하지 않는다.
7. 다른 플레이어의 `story`는 기존 스냅샷 privacy guard로 계속 비공개 유지한다.

### 호환 정책의 주의점

- 이 검증기는 G v23의 Chapter I 코드가 만든 **현재 기록 형태**를 기준으로 한다. `story`가 존재하지만 필수 `chapter1` 구조가 없는 **일부 다른 계열/구형 테스트 저장**은 유효한 게임 파일이라도 거부될 수 있다. 이것은 자동 복구 손실보다 안전한 차단이며 해당 계열 fixture는 별도 승인/마이그레이션 검토가 필요하다.
- 이미 승인된 게임 v23의 공통 저장 유효성·백업 복구 경로를 **재사용**한다. 새 파일 포맷 버전이나 덮어쓰기 규칙은 도입하지 않는다.
- 데이터 검증이 있다고 해서 악성 네트워크 입력에 대한 실서버 인증·파일 무결성 서명까지 제공하는 것은 아니다.
- 이전 스토리 `story.evidence` 기록에 없는 신규 ID/다른 타입을 거부한다. 향후 새 증거/스키마 도입 전 본 계약을 업데이트하고 이전 저장 fixture 검증 필요.
- JSON float 및 Godot variant 숫자 처리, G의 이전 버전 이관 세부 동작은 Godot에서 **실제 실행으로 검증해야 한다**.

## 3. 검증 절차

**현재 도구 환경:** Godot 실행 파일 없음. GitHub 파일 작성/커밋 및 정적 검토만 수행했다. 다음 테스트의 PASS를 주장하지 않는다.

Codex는 기존 로컬 저장·스태시를 보호하는 별도 worktree/QA 경로에서 다음 명령을 실행한다:

```sh
git fetch origin
git status --short --branch
# 기존 로컬 변경 또는 worktree 충돌이 없음을 확인한 후
git worktree add ../vestige-p1d feature/chapter1-story-save-validation
cd ../vestige-p1d
python3 scripts/verify_rules.py

godot --headless --path desktop --script res://tests/test_chapter1_port_contract.gd
godot --headless --path desktop --script res://tests/test_chapter1_input_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_dialogue_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_board_integration.gd
godot --headless --path desktop --script res://tests/test_chapter1_reconstruct_rules.gd
godot --headless --path desktop --script res://tests/test_chapter1_reconstruct_replay.gd
godot --headless --path desktop --script res://tests/test_chapter1_save_compatibility.gd
```

- v23 원래 게임 데이터 읽기/쓰기/부재 처리·백업·손상된 파일 복원 회귀를 재실행한다.
- **synthetic fixture만 사용**하고 실제 `user://single-world.json`, `user://shared-world.json` 또는 기존 테스트 저장 파일을 변경하지 않는다.
- 백업 복구 실패 시 원본/백업 바이트가 손실되지 않는지 확인한다.
- 다른 생애 `story` 공유/계정 이관/공통 저장 권한 정책은 추후 별도 승인.
- ENet 수명 오류와 실제 게임 E/T/N 동선 회귀가 남아 있다. 이전 네트워크 FAIL은 성공으로 변경하지 않는다.

## 4. 다음 작업자 체크리스트

1. `world_store.gd`의 새로운 preload가 Godot 4.5.1에서 파싱되고 기존 `Store.valid` 동작을 건드리지 않는지 확인.
2. 새 `story/chapter1_save_contract.gd`의 GDScript 정적 타입·관계 검증·JSON 숫자 처리 검사.
3. 새 저장 테스트와 기존 게임 규칙·저장 복구 테스트 실행, FAIL 시 테스트 자체를 삭제하거나 우회하지 말고 최소 수정.
4. 실제 싱글 E01 → E05/E07 → I03 → 세라 대화 → 종료·재접속에서 기록 동일 여부 수동 QA.
5. 악성 story fixture가 primary/backup을 건드리지 않고 적절히 거부되는지 검사.
6. S v1 테스트 월드 별도 이관 필요성, v23 story schema 정식 버전 증가 정책, 데이터 손상 시 복구 UX는 **결정 필요**.

## 5. 보고 상태

- **implemented:** story 계약 검사 + G 저장 호출 연결, synthetic fixture 테스트 작성
- **unverified:** Godot 파싱/저장·복구 테스트/기존 761 규칙 검사/ENet 2인 E2E/실기 플레이
- **blocked policy:** S의 독립 v1 월드 파일 자동 병합 (사용자 설계 승인 필요)
- **Git:** 별도 기능 브랜치, 원격 코드 반영. `main` 병합/배포 없음
