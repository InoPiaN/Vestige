# 복수 부재 제작 계획 · 0.5.11

Codex · 2026-11-12 · codex/offline-crafting-queue · 기반 fd80e1e. 실제 작업트리 `/private/tmp/vestige-gear-provenance`. 원본 `/Users/junheejang/Documents/Vestige` checkout은 오래된 상태이므로 덮어쓰지 않는다. 원격 fetch 후 추가 변경 없음. Claude UI 작업과 병행하며 다음 기능은 사용자 지시에 따라 참고 게임 조사→제안→승인부터 시작한다. 이번 범위는 사용자 승인 완료.

## 구현

`craft_plan.gd`: 기존 `craft_plan`은 첫 번째 계획, `craft_queue` 배열은 후속 최대2개. `plans()`는 순서대로 참조를 반환, `store()`는 순서를 저장. 기존 3/5필드 설정 명령은 첫 번째 계획에 호환, 새 6필드는 `index|recipe|mode|amount|source|destination`. `plan_up/down/pause/delete`는 index 문자열. `plan_cancel`은 전체 삭제+휴식. 순서/정지/같은 설정 재저장은 remaining 보존. 목표/물품/횟수를 변경하면 새 계획으로 설정. 빈 마지막 삭제는 휴식. 새 생애에는 계획을 상속하지 않는다.

가죽/철제 갑옷 포함 7개 제작법. 우선순위 위에서부터 완료/목표충족/일시정지/재료/보관/주택 조건 불충족을 건너뛴 뒤 최초 가능 계획 하나만 실행한다. 게임 속 하루 전체 합계1회, 체력40미만 회복 우선. 모두 막히면 휴식. 부재 NPC 동선도 실제 실행 가능한 계획에 맞춘다. 계획별 불가/대기 상태와 결과를 일기에 기록한다. 상위 목표재고가 계속 부족하면 하위는 대기하는 정책이다.

`armor_crafting.gd` planned 인자는 내부 일일 처리에서만 사용. 일반 act는 기존 직접조작/대장간 거리 검사 유지. 소지품 재료/결과만 지원하며 품질 난수·XP·개별ID·제작자 규칙 공유. catch-up day_number로 날짜 기록. 자동구매/판매/집갑옷재료/강화는 추가하지 않음.

저장16, 기존1~15 허용. 기존 단일계획/진행 보존, 빈 queue와 paused=false만 추가. 현재 버전은 모든 계획의 공급설정/정지형식 검증. 미래17이상 보호. 타인 snapshot에서 craft_plan/craft_queue 모두 숨김. 사용자 실제 저장은 시험에 사용하지 않았다.

`craft_plan_panel.gd`: 최대3개 선택/추가, 위아래/정지재개/선택삭제, 전체삭제 분리. 드롭다운은 내용 변경시에만 다시 구성해 열린 선택 목록을 방해하지 않는다. 서버 응답 후 순서 변경한 항목의 편집폼을 갱신한다. 긴 상태는 스크롤 영역 안에 둔다. 기존 single 창 정지/multi 월드 지속 규칙 유지.

## 검증과 실행

전체 test_*.gd 규칙424개(기존401+신규23), 첫여정30/60Hz. 새 시험은 건너뛰기/횟수/정지재정렬/건강/단일생산/저장/중복catch-up/15이관/비정상queue/비공개/갑옷 품질경험치/날짜. scripts/render_queue.gd 실제 버튼 추가→정지→재정렬→생활맡김과 스크린샷. ENet network_queue.gd 실제 서버에서 재정렬/정지/삭제/클라이언트 폼 동기화. 서버100ms 명령제한 때문에 시험명령은150ms 간격. 시험 서버는 종료한다.

Mac 앱 export/ad-hoc서명/메뉴기동/번들 demo.queue 4일 생산검사. Windows export와PE32+x86-64형식검사, 실제 Windows 플레이는 미검증. 최신 `builds/Vestige-0.5.11.app`, `builds/windows-0.5.11/Vestige.exe`. Play-Queue.command/cmd와 `-- --queue-demo`, 독립 queue-demo.json. 초기 붕대2개유지→철제1개→가죽1개, 충분한 재료. 기존 Play-*도 최신 앱으로 갱신. 새 실행본 검증 후 이전0.5.10 실행패키지만 제거하며 저장/백업/Git/소스/스크린샷은 보존.

## 후속 후보 (새 승인 필요)

방어구 강화·거래 / 다른 무기와 전투 역할 / 장기경제·숙련 균형 / 다중주택·상속 / 제작노트 / 사망추적 확장 / Claude UI 통합 / Windows 실기 / Steam 준비. 자동 출시·구매·main 병합은 하지 않는다.
