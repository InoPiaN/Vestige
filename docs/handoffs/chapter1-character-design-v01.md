# 제1장 인물 설계 v0.1 — ChatGPT → Codex 인계

## 이번 작업 성격

**스토리 및 AI 대화 지식 설계만 수행. 게임 코드·기존 저장·대사/UI·설정 파일은 변경하지 않음.** 본 문서와 함께 작성한 초안은 모두 작가 검토용이며, 현행 게임 세계의 정본을 자동 확장하지 않는다.

- 브랜치: `design/chapter1-character-bible-v01`
- 기준: `qa/chapter1-p1i-macos-input` (P1-J 렌더 실험 브랜치가 아닌 안정화된 QA 계열)
- 생성 문서:
  1. `docs/story/CHAPTER1_CHARACTER_BIBLE_DRAFT.md` — 이렌·브란·세라·카엘 인물 프로필/기존 사실/제안/결정 필요/관계·갈등
  2. `docs/story/CHAPTER1_CHARACTER_KNOWLEDGE_TREE_DRAFT.md` — 증거/소문/진술/추론/설계 제안 구분, AI 지식 범위, 정보 공개 정책, 제안 QA
  3. `docs/handoffs/chapter1-character-design-v01.md` — 본 문서

## 출처와 범위

- 현행 코드 `desktop/story/chapter1_dialogue.gd`, `chapter1_investigation.gd`, `chapter1_rules.gd` 직접 확인.
- 역사 설계 문서 `feature/chapter1-evidence-board:docs/CHAPTER1_STORY_FOUNDATION.md`, `CHAPTER1_KAEL_DIALOGUE.md`, `CHAPTER1_DEVICE_LOG.md`, `CHAPTER1_RECONSTRUCTION.md`, `CHAPTER1_EVIDENCE_BOARD.md` 확인.
- 게임 세계 원칙 `docs/GAME_DESIGN.md` 참조.
- 역사 문서의 '그 당시 미구현' 표시는 최신 구현/검증 상태가 아님. 현행 G/P1 코드 기준과 출처별 구분.
- 설계 방향에 사용자의 명시 승인이 필요한 질문은 `CHAPTER1_CHARACTER_BIBLE_DRAFT.md`의 DEC-01~08에 기록.

## 기존 정본 보호

- E01 일기 = 약속 문구만 있음. 만남 성사나 약속 상대의 신원은 미확정.
- E05/E06/E07/E13 현장 물증, E08 카엘 진술은 증거 출처를 구분.
- 카엘은 예배당 방문과 표식 소유를 인정했으나 실제 장치 조작·사고 책임·이렌 생사는 **확정되지 않음**.
- I03/I04/I07은 현재 제한적인 증거 연결, I06은 미확정/잠금.
- 브란의 장갑, 세라의 미반납 책, 카엘의 과거 도움은 각 인물 **발화로 기록된 주장**임을 인식.
- 브란/세라의 과거, 카엘의 비밀, 이렌의 의도·상태, 추가 사건 물증은 새 창작 **제안**에만 존재.

## Codex에 지금 요청하지 않는 일

- 생성한 새 프로필/대사 샘플을 게임의 NPC 대사로 **즉시 반영 금지**.
- `chapter1_rules.gd`의 상태·저장 스키마나 기존 E/I ID 변경 금지.
- 확정되지 않은 사건 진실, 이렌의 사망, 카엘의 실제 조작·고의, 숨긴 비밀의 존재를 작성하지 않음.
- 새로운 퀘스트/증거/챕터 엔딩 구현 착수 금지.
- 사용자 승인 전에 P1-J 코드 실험 브랜치를 본 서사 브랜치와 병합 금지.

## 다음 순서 (ChatGPT 설계 파트)

1. 사용자와 인물 설정집의 큰 성향·관계 제안 검토.
2. DEC-01~08에서 우선순위를 정해 승인한 항목만 `approved`로 표시.
3. 제1장 Act I–III의 감정 곡선 및 인물 관계 충돌 장면 설계.
4. 그 후에만 확정된 대사/분기 및 Knowledge Tree 계약을 Codex 구현 프롬프트로 변환.

## 사용자 승인 정본 업데이트 — DEC-02 (2026-11-22)

- 사용자 선택 C안: **이렌·브란은 신념이 달라 갈등했던 가까운 친구**.
- 신념 차이: 브란은 현재 살아 있는 사람의 보호·실천을, 이렌은 떠난 사람의 기억과 삶의 의미 보존을 특히 중요하게 여긴다.
- 갈등한 경험이 있다는 관계 배경은 승인되었지만 **구체적 갈등 사건/시점/대사/결말은 미확정**.
- 장면 후보 A(폭풍 뒤 묘비), B(이름 없는 유품), C(환자의 마지막 말)는 `docs/story/CHAPTER1_BRAN_IRENE_SCENES_DRAFT.md`에 제안으로 보관했다.
- 새 관계 정본은 게임의 **현재 공개 NPC 지식**과 다르다. 별도의 사용자 승인 이전에는 대사/증거/퀘스트에 공개하지 않는다.
- **DEC-02A 승인:** 폭풍 뒤 무너진 집과 훼손된 묘비를 둘러싼 복구 우선순위 갈등. 실제 대사·피해 규모·해결/화해는 미확정. 세부 비트·감정선은 `docs/story/CHAPTER1_BRAN_IRENE_STORM_SCENE_DRAFT.md` 참고.
- **DEC-02B 사용자 승인:** B안. 폭풍 뒤 집/묘비 문제는 해결되었으나 마음의 상처는 해소되지 않았고, 이렌과 브란은 가까운 친구 관계를 유지했다. 정확한 복구 방법·누가 무슨 말을 했는지·사과/화해 시기·실종 관련성은 미확정.
- 감정 변화와 후속 장면 초안은 `docs/story/CHAPTER1_BRAN_IRENE_STORM_SCENE_DRAFT.md`의 '4-1. DEC-02B 이후 전개' 참고. 해당 대사/구체적 행동은 구현 승인되지 않은 `proposal_scene`.
- **다음 사용자 결정 DEC-02C:** A 브란의 날 선 말 / B 이렌의 날 선 질문 / C 서로 듣지 못한 침묵.

## Codex가 나중에 읽을 시작 프롬프트

> `design/chapter1-character-bible-v01`의 `docs/story/CHAPTER1_CHARACTER_BIBLE_DRAFT.md`, `docs/story/CHAPTER1_CHARACTER_KNOWLEDGE_TREE_DRAFT.md`, `docs/handoffs/chapter1-character-design-v01.md`를 읽어. **현재는 스토리 설계 초안이고 구현 지시가 아니다.** `[정본/근거]`, `[인물의 주장]`, `[제안]`, `[결정 필요]` 상태를 유지해. 사용자가 승인한 설정과 Codex용 구현 명세가 별도로 내려오기 전에는 NPC 대사·퀘스트·증거·저장·코드 변경을 하지 말고, 기존 코드와 충돌하는 부분이 있으면 분석 결과만 보고해.

## 검증 및 Git

- 실제 Godot 게임 코드 변화 없음, 따라서 게임 실행 회귀 새로 수행하지 않음.
- 문서에서 현재 구현이 아닌 창작 제안을 **미확정**으로 표기, 주요 증거 연결·인물 대사와 모순 여부 수동 대조.
- 문서만 독립 브랜치에 원격 커밋/푸시, `main` 병합/PR/배포 없음.
