# 제1장 사건 재구성 프로토타입 — E13 + 세라 검토

## 기반
`feature/chapter1-reconstruction-prototype` is based on `feature/chapter1-device-log` (tested locally 31/31 for E07/E08).

## 이번 코드 변경
- `device_key` / E13: 예배당 근처 (24,13)에서 늑대 처치 후 E키로 조사. 원본 증거, 발견 시각·순서·출처를 인물별 저장. 장치 연결부의 도구 파편이라는 사실은 확인되지만 소유자와 사용자는 확인되지 않음.
- 세라의 기존 대화 선택지 UI를 재사용해 제한적 사건 재구성 `verify_I03`, `verify_I04`, `verify_I07` 추가. **E13 + E07**로 확인되는 건 장치에 도구가 사용됐다는 정황(I07)뿐.
- 각 추론은 서버/싱글 권한 측의 대화 세션, 세라와 거리, 실제 소유 증거를 검사한 뒤 `story.chapter1.inferences`에 저장.
- N키 수첩에는 미검증/검증 가능/검증 완료 상태를 표시. 검증은 세라와 대화해 수행하며 N키 수첩에서 직접 선택하는 UI는 아직 없다.
- `I06`(카엘이 조작자였는가)의 조건을 추가로 강화해, 현재 구현되지 않은 수정 진술 E11 없이는 검증할 수 없게 변경. 가벼운 현장 물증만으로 책임을 확정하는 일을 피한다.
- `main.gd`, `world.gd`, 기존 건물 충돌과 NPC 위치는 수정하지 않았음. 이 두 파일에 사용자의 로컬 미커밋 변경이 있으므로 원격 작업 중 건드리지 않는다.

## 의도한 제한
이렌의 사망/의도/잔향의 정체는 미확정. 사고 경위 전체, 카엘의 책임, A/B/C 결말, 제2장 이동은 아직 구현되지 않음. 작업은 사건 재구성 **최소 사용 가능 프로토타입**이며 전용 화면, 퍼즐, 애니메이션과 지하 씬 제작은 별도 단계.

## 검증 명령어

```sh
git status
git fetch origin
git switch feature/chapter1-reconstruction-prototype

godot --headless --path desktop --script res://tests/test_chapter1_reconstruction.gd
godot --headless --path desktop --script res://tests/test_chapter1_device_log.gd
godot --headless --path desktop --script res://tests/test_kael_dialogue.gd
godot --headless --path desktop --script res://tests/test_chapter1_story.gd
godot --headless --path desktop --script res://tests/test_dialogue.gd
godot --headless --path desktop --script res://tests/test_investigation.gd
godot --headless --path desktop --script res://tests/test_investigation_ui.gd
```

## 수동 체험 흐름
1. 예배당 늑대를 처치한다.
2. (28,11) E07 장치 기록과 (24,13) E13 파편 조사 후 N키를 눌러 추론 상태를 확인.
3. 마을 서재 근처 세라에게 E키 대화 → '조작 도구와 기록판 검토'.
4. N키 수첩에서 I07이 검증 완료로 표시되는지 확인.
5. 카엘의 책임과 최종 엔딩이 여전히 잠긴 상태인지 확인.

주의: Godot 실행 성공은 개발자 로컬 검증 전까지 주장하지 않는다.
