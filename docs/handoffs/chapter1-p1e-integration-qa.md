# VESTIGE P1-E — 전체 통합 QA 실행 계획 및 결과 인계

기준 브랜치: `feature/chapter1-story-save-validation`
작업 브랜치: `feature/chapter1-p1e-qa-harness`
작성일: 2026-11-22

## 현재 결론

- **QA 실행기를 구현하고 기존 브란 E/T 입력 우선순위 테스트의 잘못된 좌표를 수정했다.**
- 이 환경에는 Godot 4.5.1 실행 파일이 없으며 네트워크 다운로드도 안 된다. **실제 Godot·ENet 테스트는 전부 미실행이다.**
- 따라서 검증 상태는 `blocked_by_environment`이다. `implemented`인 기능을 `verified`라고 올리지 않는다.
- `main`, 게임 저장 원본, `desktop/world.gd`, `desktop/world_store.gd`는 이번 P1-E 브랜치에서 변경하지 않았다.
- 문서 전용 공통 규칙은 `docs/ai-collaboration-governance` 브랜치의 `AGENTS.md` 참조.

## 1. 실행 자동화

```sh
# 1) 현재 브랜치 및 실제 로컬 파일을 확인한 다음 분리된 worktree에서 실행
git fetch origin
git status --short --branch
git worktree add ../vestige-p1e feature/chapter1-p1e-qa-harness
cd ../vestige-p1e

# 2) 설치한 Godot 4.5.1 경로 확인 (예: macOS)
python3 scripts/run_p1e_qa.py \
  --godot .tools/godot/Godot.app/Contents/MacOS/Godot \
  --logs /tmp/vestige-p1e-qa

# 다른 경로라면 --godot /실제/경로
# 결과: /tmp/vestige-p1e-qa/p1e-report.json + 테스트별 원문 로그
```

실행기는 추적된 테스트 파일과 Godot 바이너리를 먼저 확인한다. 없으면 `BLOCKED` 및 exit code 2.
존재하면 `python3 scripts/verify_rules.py`와 제1장 테스트 7개를 차례로 실행하고 종료 코드/소요시간/로그를 기록한다.
실패가 하나라도 있으면 `FAIL`/exit code 1. 전부 실제 실행하여 통과하면 `PASS`/exit code 0.

런타임은 임시 `HOME`, `XDG_DATA_HOME`, `APPDATA`, `LOCALAPPDATA`를 사용한다. 각 Chapter I 테스트도 고유 `/tmp` 월드 fixture를 사용한다.
원본 `user://single-world.json`, `user://shared-world.json`의 안전성은 **실제 실행 경로 확인**을 병행해야 한다. QA 이전에 개인 백업 권장.

## 2. 자동 테스트 매트릭스

| 번호 | 테스트 | 목적 | 현재 상태 |
|---|---|---|---|
| QA-00 | `scripts/verify_rules.py` | 기존 G 게임 생활·제작·전투·저장 규칙 회귀 | 미실행 |
| QA-01 | `test_chapter1_port_contract.gd` | G+S 조사 이식, E01 기록, 중복 방지, v23 보존 | 미실행 |
| QA-02 | `test_chapter1_input_integration.gd` | E 조사, N 수첩 UI, 타 지역 차단, 저장 | 미실행 |
| QA-03 | `test_chapter1_dialogue_integration.gd` | 세라/카엘/브란 대화, 브란 대장간 E와 NPC T 분리 | 미실행 |
| QA-04 | `test_chapter1_board_integration.gd` | N 증거 보드, E05+E07 I03, 중복 조합 | 미실행 |
| QA-05 | `test_chapter1_reconstruct_rules.gd` | I03/I04/I07, 타인 증거 차단, 미확정 진실 보존 | 미실행 |
| QA-06 | `test_chapter1_reconstruct_replay.gd` | peer 소유권/요청 재전송/과속 제한/저장 | 미실행 |
| QA-07 | `test_chapter1_save_compatibility.gd` | v22/v23, 손상·백업·미래 버전 및 추론 위변조 거부 | 미실행 |

**QA-03 테스트 위치 수정:** 브란 정확한 좌표 (7,7.5)와 대장간 (5,7)은 거리 2.06으로 시설 상호작용 반경 2.0 밖이다. E/T 우선권을 확인하려면 두 범위가 모두 겹치는 좌표 (6,7.5)를 써야 한다. 테스트를 이 조건으로 보정했으며 실제 Godot에서 PASS 여부는 아직 확인되지 않았다.

## 3. 수동·ENet 필수 검증

자동 테스트가 전부 성공해도 아래 검증이 끝나지 않으면 전체 P1-E는 완료되지 않는다.

| 번호 | 절차 | 통과 기준 |
|---|---|---|
| NET-01 | 서버+2클라이언트, 각자 증거/대화/조합 | 개인 증거·스토리 비공개, 조합 권한 격리 |
| NET-02 | NPC 대화 중 이동, 다른 NPC 선택지·토큰 위조 | 서버 세션/거리/생애/허용 선택지만 인정 |
| NET-03 | 요청 ID 재전송/지연/유효하지 않은 증거 | 상태 중복 변화 없고 클라이언트 pending 해제 |
| NET-04 | 서버 재시작, 접속 해제와 snapshot/RPC 동시 발생 | 기록 보존·세션 폐기·ENet 송신 오류 없음 |
| SAVE-01 | 싱글 저장→종료→복구→N 수첩 | E01/E05/E07와 추론·발견 순서 유지 |
| SAVE-02 | 원본 손상/.bak 정상, 양쪽 손상, 미래 버전 | 잘못된 원본 덮어쓰기/조용한 초기화 없음 |
| GAME-01 | E 대장간/서재, T 대화, E 증거, F 사망 조사 | 상호작용 충돌 없음 |
| GAME-02 | 집·벽·이렌 집 앞·예배당·이동·전투·여관 | 타일 접근 가능, 충돌·UI 봉쇄 없음 |
| GAME-03 | 새 생애, 다른 지역, 모달 중 공격/회피 | 생애 범위 격리·입력 모드 일관 |
| LORE-01 | E01, E08, I03/I04/I07 | 약속=만남 아님, 진술=독립 물증 아님, 카엘 책임/이렌 생사 미확정 |

### 알려진 미해결 사항

- 기술 감사의 S 계열 네트워크 스크립트는 `Unable to send packet on channel 0, max channels: 0` 로그 때문에 실패했다. 현재 P1-C의 peer 보호 패치가 이 오류를 실제 해결했는지는 미확인.
- `StorySaveContract`는 존재하는 Chapter I `story` 필드의 구조를 엄격히 검사하므로, 일부 과거 스토리 계열 단독 데이터는 별도 이관 정책이 필요할 수 있다.
- 저장 v23과 스토리 schema_version 1의 설계 변경은 승인 없이 진행하지 않는다.

## 4. 변경 내역·검증 증거

| 구분 | 결과 |
|---|---|
| 이번 직접 변경 | `desktop/tests/test_chapter1_dialogue_integration.gd`의 잘못된 거리 fixture 수정 |
| 신규 파일 | `scripts/run_p1e_qa.py`, 본 인계 문서 |
| 정적 검토 | 테스트 구성과 기존 실사용 경로 읽기·검토 |
| 실제 Python/Godot 실행 | 게임 저장소/엔진이 이 세션 파일 시스템에 없어 미실행 |
| 원격 푸시 | 문서 및 QA 코드 전용 기능 브랜치에만 반영 |
| 기본 브랜치 병합/배포 | 없음 |

## 5. 다음 작업자 의무

1. Godot 4.5.1 환경을 확보하고 실행기를 실제로 돌린다.
2. `p1e-report.json`의 각 `FAIL` 로그를 분석해 좁은 코드/테스트 수정 후 재실행한다. 테스트 삭제/완화로 통과 처리 금지.
3. 수동 2클라이언트/동선 검증을 같은 커밋에서 진행하고 ENet 오류 로그를 첨부한다.
4. 실기 기능이 검증되기 전 `main` 병합 금지. 결과를 `PROJECT_STATUS.md`와 handoff에 기록한다.
