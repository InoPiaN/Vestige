# 제1장 E07·E08 조사 및 진술 대조 (구현 단계)

## 개발 기준
- 작업 브랜치: `feature/chapter1-device-log`, 부모 `feature/chapter1-kael-dialogue`.
- 게임 시작, 이동/충돌, 늑대 전투, 대화 세션, 저장 파일 버전, 기존 조사 ID를 변경하지 않는다.
- Godot 파싱/실행 및 테스트 결과는 개발자 로컬에서 검증해야 한다.

## 새 조사 단서
- `device_log` (논리 E07): 예배당 동쪽 기록판 `(28,11)`, 늑대 처치 후 E 조사 가능. 직접 기록된 사실은 수동 가동과 이상 진동뿐이며 조작자는 기록되지 않음.
- `kael_statement` (논리 E08): **이미 획득한** `kael_token`을 카엘에게 제시하는 유효한 서버 대화에서만 획득. NPC의 진술이라는 출처가 명시되며 재질문으로 중복 획득되지 않음.
- `story.evidence`의 기존 출처·발견 순서·월드 시각 및 중복 정책 사용. `story.chapter1.evidence_links`로 E07/E08 연동.
- 카엘의 `kael_compare` 대화 선택지는 E07, E08 모두 보유 시에만 서버가 허용. 다른 NPC, 원격 접속, 대화 세션 위조 시 거절.
- 조사 수첩은 두 단서 사이의 비교 가능성만 안내. **카엘이 장치를 작동했다는 결론은 만들지 않음.**
- I03(장치 가동과 봉인 손상 연결)은 E05+E07 이후 규칙 함수로 검증할 수 있으나, 현재 수첩에 추론 선택 UI나 네트워크 명령은 추가하지 않았음. I06(카엘 책임)은 E13 등의 독립 검증이 생기기 전까지 잠김.

## 수동 확인
1. 예배당의 늑대를 처치하고 `(28,11)`에서 E → N으로 장치 기록 확인.
2. `(26,14)` 금속 표식 수집 후 야영지의 카엘 `(17,14)`에게 표식 제시.
3. 카엘과 다시 대화해 `장치 기록과 앞선 진술을 대조한다` 선택지가 표시되는지 확인.
4. N 수첩에서 E07/E08의 발견 순서와 진술 출처 확인. 재접속 후 동일한 기록 유지.
5. 브란·세라 대화와 대장간/이렌의 집 주변 이동이 그대로 동작하는지 확인.

## 자동 테스트

```sh
git fetch origin
git switch feature/chapter1-device-log
godot --headless --path desktop --script res://tests/test_chapter1_device_log.gd
godot --headless --path desktop --script res://tests/test_kael_dialogue.gd
godot --headless --path desktop --script res://tests/test_chapter1_story.gd
godot --headless --path desktop --script res://tests/test_dialogue.gd
godot --headless --path desktop --script res://tests/test_investigation.gd
godot --headless --path desktop --script res://tests/test_investigation_ui.gd
```

## 다음 구현 범위
E13 실제 물증 정의 및 출처 검증 → 사건 재구성 UI → 필요 시 Kael 수정 진술 E11 및 후일담. 객관 물증이 없는 고백만으로 사건을 자동 확정하지 않는다.
