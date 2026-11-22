# AI Data Integration Proposal
2026-11-22 · 제안 상태 planned. 현재 로더/스키마 검증기/지식 그래프가 구현된 것은 아니다. 이번에 저장 형식이나 하드코딩 데이터를 바꾸지 않았다.

## 역할과 인수인계 계약
- ChatGPT: 세계관/시스템/스토리 명세, ID 사전, NPC 기억/관계/행동 설계, 설계 대 구현 차이 검토. 설계 파일의 별도 코드 구현은 하지 않는다.
- Codex: 명세의 참조/상태 검토, 구현 계획·코드·회귀/플레이 검증, 구현 증거 기록.
- 사용자: 서사 진실·게임 규칙·스코프 승인. 미확정 진실을 Codex가 채우지 않는다.
- 전달 단위: design_revision, 관련 ID, 선행 명세, 수용 조건, 미확정 사항, 허용된 변경 범위. Codex는 이를 구현 완료 기록으로 간주하지 않는다.
- 설계와 코드의 차이는 design_id→구현 파일/심볼→검사/커밋으로 보고한다. 같은 기능을 별도 브랜치에서 중복 개발하지 않는다.

## 권장 디렉터리 (신규 생성은 후속 단계)
```text
docs/design/master.md
docs/design/world/              # World & Lore
docs/design/characters/
docs/design/npc-memory/
docs/design/story-quests/
docs/design/systems/
docs/design/ids.md
docs/design/validation.md
design_data/manifest.json
design_data/world/*.json
design_data/character/*.json
design_data/story/*.json
design_data/quest/*.json
design_data/ai_behavior/*.json
design_data/system/*.json
design_data/data_schema/*.json
design_data/validation/*.json
design_data/schemas/*.schema.json
design_data/id_aliases.json
docs/implementation/traceability.json
desktop/content/               # 검증 후 내보낸 런타임 허용 데이터
desktop/content_loader.gd       # 후속 구현
scripts/validate_design.py      # 후속 구현
```
루트 data/는 현재 .gitignore에서 제외되므로 설계 원본은 design_data/를 권장한다. 사용자 저장과 설계 데이터를 섞지 않는다. 전체 진실을 담은 원본은 desktop 밖에 둔다. export all_resources로 숨겨진 설계가 클라이언트 PCK에 들어가지 않도록 명시적 허용 목록으로 내보낸다.

## 형식 비교와 결정 제안
| 형식 | 이점 | 부담 | 권장 사용 |
|---|---|---|---|
| JSON | 기존 저장/도구와 익숙함, 언어 간 교환 쉬움, 명시적 타입/스키마 | 주석 없음, 장문 불편, 참조 무결성 별도 검증 필요 | 설계 데이터 교환·초기 원본 형식 |
| YAML | 사람이 읽고 주석/장문 쓰기 편함 | 파서 의존성·암묵적 타입/별칭 규칙 관리, Godot 연결 변환 필요 | 초기에는 채택하지 않음. 필요 시 JSON 생성용 작성 형식으로만 |
| Godot Resource(.tres) | 에디터/타입/자산 참조 통합 | 엔진 의존, 외부 설계 도구와 교환 부담, UID/생성 산출물 관리 | 장면·스프라이트·오디오 등 엔진 자산에 유지 |

**Markdown 설명 + JSON 데이터/JSON Schema + 별도 그래프 검증**을 권장한다. 문법/타입 검증과 ID 존재/허용 관계/도달 가능성 검증은 서로 다른 단계이다. Graph DB는 당장 도입하지 않고 ID 레지스트리와 typed edges로 시작한다. 구현 단계에서 JSON Schema 버전/라이브러리와 엔진 버전을 고정한다.

## ID와 상태
- 신규 예: CHARACTER.NPC.KAEL, WORLD.LOCATION.ASH_VILLAGE.CHAPEL, STORY.CH01.EVIDENCE.E07, STORY.CH01.INFERENCE.I03.
- 대문자 namespace+type+stable name을 기본으로 하되 기존 bran/sera/kael, last_promise→E01 등은 aliases로 보존한다. 승인 없이 기존 저장 ID를 치환하지 않는다.
- 영구 정의 ID, 월드 인스턴스 ID, player token, life ID를 분리한다. 동일 정의라도 생애별 발견은 별도 상태다.
- refs는 target_id, relation, expected_type를 가진다. 이름 문자열/화면 문구로 연결하지 않는다.
- 삭제 대신 deprecated/replaced_by와 이관 정책. 미정 데이터는 reserved로 표시하고 실제 런타임 manifest에 넣지 않는다.
- status: planned→specified→implemented→verified. 상태 변경 주체/근거를 기록한다.
- specified는 승인된 명세/수용 조건이 필요하다. implemented는 코드 커밋/심볼이 필요하다. verified는 해당 코드와 명세 버전의 실제 검사 결과가 필요하다.
- 구현이 있어도 설계와 불일치할 수 있다. design_revision/code_commit/tested_commit을 따로 기록하고 변경 후 검증을 stale로 표시한다.
- 구현 상태 verified와 게임 내부 inference_state=verified를 혼용하지 않는다. 후자는 특정 증거 연결이 지지됨을 뜻하며 인물의 유죄 확정이 아니다.

예시(제안용, 런타임 데이터 아님):
```json
{
  "id": "STORY.CH01.INFERENCE.I03",
  "domain": "STORY",
  "type": "inference_definition",
  "aliases": ["I03"],
  "design_revision": "proposal-1",
  "status": "planned",
  "refs": [
    {"target_id": "STORY.CH01.EVIDENCE.E05", "relation": "requires", "expected_type": "evidence_definition"},
    {"target_id": "STORY.CH01.EVIDENCE.E07", "relation": "requires", "expected_type": "evidence_definition"}
  ],
  "scope": "life",
  "epistemic_kind": "limited_inference",
  "claim": "현장 흔적과 장치 가동 기록의 제한적 연결",
  "forbidden_conclusions": ["카엘이 장치를 조작했다", "이렌의 사망이 확인됐다"],
  "visibility": "discovered_only"
}
```
예시의 명세 상태는 신규 데이터 포맷 제안의 상태이다. 기존 S의 I03 코드 구현 여부는 Feature Inventory에서 별도로 추적한다.

## 지식·기억·진실의 분리
정의 데이터와 실행 상태를 나눈다.
- 사실 주장: claim_id, 출처 ID, 관찰/진술/추정 구분, 시간, 서사 확정 여부.
- NPC 기억(후속): observer_id, event_id, life/world scope, observed_at, source_id, belief/confidence, visibility, expires/retention. “말을 들었다”와 “실제로 봤다”를 구분한다.
- 관계: actor→target 방향성, 변화 원인 event_id, 중복 적용 키. 신뢰 수치를 진실 판정으로 사용하지 않는다.
- 미확정 진실: authorial_status=unresolved 및 결정 대기. 엔진이나 생성형 모델이 임의로 값을 채우지 않는다.
- 향후 서버 비밀은 서버 콘텐츠에만, 클라이언트는 발견/공개 투영만 받는다. 싱글 패키지의 비밀은 기술적으로 완전 은닉할 수 없으므로 UI 미노출과 보안 경계를 구분한다.

## 검증 및 Godot 연결 (2단계 구현 대상)
1. 인코딩/중복 JSON key/스키마 버전/필수 필드/enum/숫자 범위/추가 필드 검증.
2. 전역 ID 중복, alias 중복/순환, 누락/타입 불일치 참조, 예약 ID의 실행 사용 차단.
3. 퀘스트 필수 선행 그래프의 불가능 순환·도달 불가능 종결 검사. 반복 의뢰/일상 행동의 의도된 순환은 허용 선언으로 분리.
4. 조건/효과는 allowlisted DSL만 허용. 임의 GDScript·eval·파일 경로·RPC/명령 실행 문자열 금지.
5. 부정 조건/선택지/보상 중복/상충 플래그·미확정 사실 확정 효과는 semantic 검사와 시나리오 테스트로 검증. 스키마만으로 모두 증명할 수는 없다.
6. 검증된 content manifest(hash/version)만 Godot 로더가 Dictionary/typed adapter로 읽는다. 실패 시 조용한 기본값 대신 오류 위치/ID 보고, 정상 콘텐츠 유지.
7. 초기에는 기존 하드코딩과 동일 결과를 내는 비변이 shadow 비교를 거친 뒤 한 작은 데이터군부터 전환한다. 한 도메인에 원본을 둘 이상 두지 않는다.
8. 저장에는 런타임 상태+content_version만 두고 정의 전체를 복사하지 않는다. 기존 저장 버전23 변경/마이그레이션은 별도 승인·fixture 검증.
9. traceability 레코드는 requirement_id, branch, code_commit, file/symbol, test_id, tested_commit, engine, result, limits. 테스트 없이 verified 자동 승격 금지.

## 장기 생성형 AI 경계
사용자 지정6단계에서만 검토한다. 서버가 해당 NPC의 허용 기억/현재 상태를 골라 제공하고, 모델 출력은 구조화된 제안으로 받는다. 대사/퀘스트 제안에 무권한 사실·ID·행동이 있으면 거절하고 규칙 기반 대사로 대체한다. 모델이 저장·보상·진실을 직접 갱신하지 않는다. 제공자/키/비용/로그 정책은 그 단계에서 결정하며 이번에는 API 호출·키 설정·구매를 수행하지 않는다.
