# 집 내부 상호작용 · 0.5.0

Codex · 2026-11-10 · `feat/house-interior` · 기준 `aa1ae9b`.

`house_interior.gd`는 room=home의 가구 위치·충돌·출입·상호작용을 정의한다. village가 기본 공간이며 x/y는 해당 공간 좌표다. main의 집 문 E는 enter_home을 사용한다. 기존 world.act(interact)의 실외 책장 경로와 문 앞 B/F는 기존 체험 호환을 위해 유지한다. 집 내부에서는 책장과 물품 보관함의 위치를 따로 검사한다.

서랍/찬장 내용은 estate.interior.drawers에 최초 한 번 생성하고 잔량을 저장한다. 천·못·찻잔은 Items.CATALOG에 추가해 기존 수량/보관/유품 경로로 이어진다. 아이템 표시용 무작위 문자열이나 재접속 재추첨은 없다. 원격 snapshot에서 실외에는 interior를 보내지 않고 실내에도 drawers 원본 수량은 보내지 않는다. 조작은 server world.act에서 거리/생존/직접 조종 검사를 통과해야 한다.

책장은 기존 일지/사건 수첩, 보관함은 기존 storage_panel과 연결. 침대는 hp+25/stamina100 및 world.time 기준 60초 간격이며 시간 점프 없음. fireplace/curtain은 시각 상태만 바꾸며 연료·은신·온도 기능을 암시하지 않는다. 실내 렌더링은 pixel_world의 기존 code pixel 스타일로 직접 작성했다. 가구 이동은 미지원.

공간 분리: 늑대 표적/공격/NPC strike, 실내 이동, 야외 생활 이동, 사건 현장·증거물·유품에 room 처리를 추가했다. 실내 휴식 정책의 부재 주민은 방에 머물고 다른 정책은 문 밖으로 나와 생활한다. 실내 사망은 사건과 유품에 room=home이 남는다. 외부의 같은 좌표로는 조사/회수가 불가능하다.

저장 형식 6. 1~5 이관 때 내부를 최초 생성한 뒤 플레이 전에 checkpoint한다. 기존 사용자의 저장을 초기화하거나 테스트에 사용하지 않았다. `-- --home-demo`는 독립 home-demo.json을 사용하고 재실행 시 이어진다. 시작은 집을 소유한 여행자가 실내에 있는 상태. 실행기 builds/Play-Home.command 또는 Windows Play-Home.cmd.

검증: 신규 25개 포함 177개 검사와 첫 여정 30/60Hz. 실제 ENet 문 접근→입장→가구를 피해 서랍으로 이동→유한 수량 수집→빈 서랍 반복 요청 통과. 원격에 숨겨진 서랍 내용이 노출되지 않는 것도 확인. scripts/render_interior.gd로 화면 렌더링/육안 확인. 테스트는 /tmp 독립 월드를 사용하고 서버를 종료했다. Mac·Windows 0.5.0 빌드 완료. Mac ad-hoc 서명 및 headless 메뉴 기동과 Windows PE 형식을 확인했으며 Windows 실기는 별도다.

Claude 통합: 이번 시작 시 신규 원격 Claude 변경 없음. main E 출입/보관함 메시지/실내 안내, pixel_world 실내 렌더 분기, world room 규칙을 유지해야 한다. docs/INTERIOR_REFERENCES.md에 공식 자료와 실제 적용 범위를 기록했다. 기능 브랜치는 누적 상태이며 main 병합 전이다.

다음: 잡템의 제작·수선·판매 용도, 가구 이동과 집 확장, 여러 주택/상속. 잠금·절도·침입, 연료·요리·온도는 미구현. 도트 디테일과 UI 스타일은 Claude 쪽 통합 시 다듬을 수 있다. 이전 다중 저장 작성자/Steam Cloud 충돌 문제도 남아 있다.
