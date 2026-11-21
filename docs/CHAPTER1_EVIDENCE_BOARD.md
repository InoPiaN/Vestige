# 제1장 — 증거 조합 전용 UI (Evidence Board)

Branch: `feature/chapter1-evidence-board`. Parent: `feature/chapter1-reconstruction-prototype` (locally reported 7 test suites passing).

## 새 흐름
1. N키로 기존 조사 수첩을 연다.
2. **사건 재구성 · 증거 조합** 버튼을 누른다.
3. 발견한 증거 목록에서 서로 다른 2개를 선택한다.
4. **선택한 증거 조합**을 누른다.
5. 성공 시 검증 ID만 확인하고, 별도 화면을 닫으면 수첩에서 검증 완료 상태를 볼 수 있다.
6. 틀린 조합과 미발견 증거에는 추측을 확정하거나 정답을 누설하지 않는다.

현재 연결:
- E05 + E07 → I03 (손상과 장치 가동 기록 사이의 정황 연결)
- E06 + E08 → I04 (카엘의 방문 및 본인 진술 대조)
- E07 + E13 → I07 (기록판과 도구 파편의 연결)

**I06은 잠금 유지**: 어떤 조합도 카엘의 실제 장치 조작, 고의 또는 사고 책임, 이렌의 사망을 확정하지 않는다.

## 권한 설계
- UI는 선택 ID 2개만 전송한다. 선택지의 사실성·진위는 서버가 직접 `story.evidence`에서 재확인한다.
- 멀티는 기존 `command("reconstruct", "E05|E07")` RPC를 활용한다. 서버에서 NPC 대화 중인 요청 및 빈/동일/미보유/미지원 증거 조합을 거절한다.
- 싱글 역시 동일한 `evidence_board_rules.gd` 검사 함수를 사용한다.
- 성공한 연결은 기존 플레이어별 `story.chapter1.inferences`에 저장한다. 최초 검증은 1회만 인정하고 반복해서 일지에 기록하지 않는다.
- 저장 버전, 기존 E 조사와 늑대/건물 충돌은 그대로 유지한다.

## 변경 파일
- 신규: `desktop/story/evidence_board_rules.gd`, `desktop/story/evidence_board_panel.gd`, `desktop/tests/test_evidence_board.gd`
- 최소 연결: `desktop/main.gd`
- 변경 없음: `desktop/world.gd`, `desktop/investigation.gd`, `desktop/dialogue.gd`

## 중요: 로컬 변경 보호
이전 실행 로그에서 **로컬 `desktop/main.gd`와 `desktop/world.gd`가 수정됨**을 확인했다. 이 브랜치는 **원격의 `desktop/main.gd`를 수정하므로** 브랜치를 변경하기 전에 로컬 수정사항을 반드시 커밋하거나 스태시해야 한다. `world.gd`는 브랜치에서 수정하지 않았다. 스태시 재적용 시 충돌이 발생할 수 있으므로 파일을 비교하여 병합할 것.

예시:
```sh
git status
git stash push -m "local-main-world-before-evidence-board" -- desktop/main.gd desktop/world.gd
git fetch origin
git switch feature/chapter1-evidence-board
```

**스태시는 자동 재적용하지 않는다.** 원본 로컬 파일을 먼저 안전하게 보존하는 예시 명령이다.

## 테스트
```sh
godot --headless --path desktop --script res://tests/test_evidence_board.gd
godot --headless --path desktop --script res://tests/test_chapter1_reconstruction.gd
godot --headless --path desktop --script res://tests/test_investigation_ui.gd
godot --headless --path desktop --script res://tests/test_chapter1_device_log.gd
```

Godot 실행은 로컬에서 해야 한다. 이번 환경에서는 Godot 바이너리가 없으므로 **통과 미확인**.

## 앞으로
정식 퍼즐형 증거 카드, 연결선, 잘못된 추론의 이유 안내, 카엘 수정 진술 E11과 물증 체인은 별도 개발 단계. 현 단계는 플레이 가능한 두 증거 조합 UI 프로토타입이다.
