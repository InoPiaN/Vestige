# 철검 제작자 기록과 장비 선택 · 0.5.7

Codex · 2026-11-11 · feat/gear-provenance · 기준 bd9b9bd. 누적 기능 브랜치이며 main 병합은 별도다. 작업 시작 및 마무리 fetch에서 다른 원격 변경은 없었다.

사용자 규칙: 새 기능은 대작 게임 조사 → Vestige 적용안 → 승인 후 구현. 이번 FFXIV 제작자 서명·Dwarf Fortress 유물의 이야기 제안은 승인받았다. 추가로 소지품을 먼저 열지 않고 외형·장비에서 제작 철검을 선택하도록 명시 요청했다. 다음 기능은 별도 조사/승인부터 시작한다.

## 구현과 저장 호환

`gear_record.gd`: 개별 gear ID에 maker {life,name,day,place,stage}, events [{kind,day,actor,name,detail}]. 새 철검만 제작자 정보를 생성한다. stage는 경험치 지급 전 단계. life는 이름과 별개의 인물 생애 ID. sparse important history: crafted/repaired/recovered. 보관함 이동·실패한 수선/회수는 추가하지 않는다. 대성공 작품 식별자는 제작자의 일기 메모에 추가한다.

모든 gear holder의 gear_records 키를 gear_instances와 맞춘다. 집 보관/회수·사망 유품·유품 회수 시 레코드를 함께 옮기며 판매는 다른 개별 장비 데이터와 함께 제거한다. 기존 상점에는 되사기가 없으며 거래 후 추적까지 확장하지 않았다. 타인의 개인 장비 기록은 snapshot에서 제거한다. 장비 발견은 제작자의 비공개 일기나 사건 정답에 접근 권한을 주지 않는다.

저장 버전13, 기존1~12 자동 이관. 이전 장비에는 비어 있는 maker/events를 부여하며 가상의 과거를 생성하지 않는다. 저장 검증은 레코드 구조·이벤트 종류·생애 ID·날짜를 검사한다. 원본 사용자 저장은 테스트에 사용하지 않았다. 부재 다중 날짜 처리에서 각 제작일을 forge_sword에 전달하여 전부 마지막 날로 기록되는 문제를 방지했다. 날짜는 해당 하루의 일기와 일치한다.

## UI / Claude 협업

main.gd의 refresh_weapon_picker가 외형·장비 무기 목록을 실제 소지 철검 ID별로 생성한다. 품질·공격·내구와 개별 이름을 표시한다. equip_weapon 액션은 none 또는 실제 소지 iron_sword ID만 허용하며 반복 선택은 멱등적이다. 기존 equip_instance 액션은 소지품의 토글 동작으로 유지했다. 장비창에서 착용 철검 기록 버튼은 show_pages를 사용한다. 목록은 데이터가 바뀔 때만 재생성한다. inventory_panel의 상세는 스크롤 가능한 RichTextLabel이며 equipped_ids와 gear_records도 갱신 서명에 포함한다. Claude UI 통합 시 이 액션/메타데이터/갱신 경로를 보존해야 한다.

## 검증과 체험

350개 검사(신규22), 첫 여정30/60Hz 통과. 제작 기록·서로 다른 검 선택·반복 선택·저장/구버전 이관·수선·집 이동·회수 중복 방지·스냅샷·잘못된 날짜/이벤트·다중 날짜 부재 제작을 확인했다. 기존 계획 저장 시험에는 명시적 고정 시각을 사용하여 JSON 타임스탬프 반올림에 의한 하루 경계의 간헐적 실패를 제거했다.

network_legacy.gd: 임시 ENet 서버에서 개별 검 선택→동일 검 재선택→제작자/회수 이력 확인. scripts/render_legacy.gd: 합성 월드와 /tmp 저장으로 실제 OptionButton 신호·기록 버튼을 실행하고 장비/기록 화면 렌더링. 테스트 서버 종료, UI 임시 저장 삭제.

Play-Legacy.command / Play-Legacy.cmd / -- --legacy-demo. 독립 legacy-demo.json. 은결이 숙련 단계에서 만든 철검3개를 후계자가 회수한 상태. 외형·장비에서 검을 고르고 착용 철검 기록을 연다. 기존 데모와 일반 월드를 덮어쓰지 않는다.

Mac 0.5.7 export·실행 파일 이름 정규화·ad-hoc 서명 검증·headless 메뉴 기동 완료. Windows 0.5.7 export와 PE32+ x86-64 형식 확인 완료, Windows 실기 검증은 남아 있다. builds/Sword-Equipment.png 및 Sword-Legacy.png에 화면을 보관한다. 빌드와 사용자 저장은 Git에 포함하지 않는다.
