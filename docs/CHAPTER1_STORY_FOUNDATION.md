# 제1장 「마지막 약속」 — 코드 연결 작업 1단계

## 기준
- 기준 브랜치: `feature/ash-village-investigation` (commit `9ae4f8d`).
- 작업 브랜치: `feature/chapter1-story-foundation`.
- 변경 대상: `desktop/story/chapter1_rules.gd`, `desktop/investigation.gd`, `desktop/tests/test_chapter1_story.gd`.
- 기존 `main.gd`, `world.gd`, NPC 배치와 건물 충돌은 **변경하지 않는다**.

## 현재 실제로 연결한 기능
- 기존 `Investigation.ensure(p)` 호출에서 `story.chapter1` 기본 구조 초기화 및 마이그레이션.
- 기존 조사 기록 `story.evidence`는 단일 원본으로 유지하고, `story.chapter1.evidence_links`는 비파괴적인 참조만 유지.
- 기존 `last_promise` → 논리 ID `E01`; `chapel_traces` → `E05`(초기 예배당 흔적). **E05가 장치 조작이나 범죄를 증명한다는 뜻은 아니다.**
- 원본의 월드 경과 시각, 발견 순서, 출처와 사실·추정 전문을 보존. 중복 조사 시 최초 기록 유지.
- 관계 이벤트 중복 적용 방지, 추론 조건 검증, 엔딩 선택의 중복 방지와 후일담 상태 규칙을 독립적인 모듈로 추가.
- 인물마다 새로운 `story.chapter1`을 사용하므로 후계자에게 조사 기록이 자동 승계되지 않음.

## 아직 연결되지 않은 기능
- `E02`~`E13`의 실제 조사 위치 및 물증 생성, 카엘 NPC, 지하 장치실, 수첩 추론 UI, 대화 선택지 UI, 결말 및 제2장 씬은 미구현.
- 신규 추론·결말 함수는 규칙 API만 구현했으며 실제 플레이에서는 아직 호출할 수 없다.
- 추가 증거를 서버 측에서 인증하고 기록하는 경로가 완성되기 전에는 추론 완료 및 결말 선택이 잠긴 상태가 정상이다.
- 현재 프로토타입의 카엘 행위, 이렌 사망, 잔향의 정체를 확정 사실로 생성하지 않는다.

## 검증
실행 환경에 Godot 4.5.1이 있는 경우 프로젝트 루트에서:

```sh
godot --headless --path desktop --script res://tests/test_chapter1_story.gd
godot --headless --path desktop --script res://tests/test_investigation.gd
godot --headless --path desktop --script res://tests/test_dialogue.gd
```

테스트 파일 및 실행 명령은 프로젝트 구성에 맞춰 조정한다. 모든 테스트가 정상 통과한 후 UI/네트워크 연결 작업을 진행할 것.

## 후속 구현 순서
1. 실제 NPC·시설과 충돌하지 않는 조사 좌표 검증 및 새 증거 인증 경로.
2. 카엘과 대사 조건 기반 분기 — 서버가 세션/거리/증거 모두 검증.
3. 수첩의 추론 UI 및 사건 재구성 단계.
4. 사망 신원 확인, 공개/보존/증언 선택과 관계 후일담.
5. ENet 2인 및 저장 파일 호환 회귀 검사.

## 저장 주의사항
기존 `people[id].story.evidence`의 키를 `E01`/ `E05`로 일괄 치환하지 않는다. JSON 저장의 `version=1`을 불필요하게 변경하지 않는다. 데이터 신규 필드는 기본값으로 보충한다. 다른 플레이어의 `story`가 스냅샷에 전송되지 않는 기존 정책을 유지한다.
