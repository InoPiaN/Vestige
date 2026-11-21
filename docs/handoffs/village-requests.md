# 마을 게시판·반복 납품 의뢰 — 0.5.19

2026-11-21, 브랜치 codex/village-requests. 작업 트리는 /Users/junheejang/Documents/Vestige/worktrees/professions-and-skills. 부모 체크아웃은 별도 작업 상태이므로 덮어쓰지 않는다.

## 승인한 범위와 참고
사용자가 승인한 게시판 수락→물품 준비→실제 주민에게 납품 흐름이다. [Stardew Valley Help Wanted](https://stardewvalleywiki.com/Quests)의 생활 재료 요청, [The Witcher 3 게시판](https://witcher.fandom.com/wiki/Notice_board)의 지역 의뢰 발견 방식을 참고했다. 텍스트·아트는 직접 작성했다.

두 게시판: 잿불(12,8), 나루(15,14). E로 해당 지역 의뢰를 수락하고 L로 어디서든 추적한다. 소하에게 버섯1+갈대1/은화8, 도윤에게 회복 연고1/은화10, 라온에게 엄니1/은화6. 수락한 의뢰는 만료되지 않으며 완료한 다음 월드 날부터 다시 수락한다. 월드 하루는2880초이고 기존 일자 경계(08:00)를 사용한다. 늦게 완료하면 완료일 기준으로 재수락을 제한한다.

실제 깨어 있는 NPC 근처에서만 납품한다. 소지품만 소비하며 일반→양품→대성공 순서와 실제 소비 예정 물품을 미리 표시한다. 높은 품질 추가 보상은 없다. 모든 보상은 서버 판정이며 재전송으로 중복 지급되지 않는다. 생애별 독립 진행이고 타인 스냅샷에서는 requests를 제거한다. 새 인물은 처음부터 시작한다. 기존 서신/원정/약초꾼 입문은 별개로 유지한다.

## 구현
- desktop/village_requests.gd: 게시판·세 의뢰·조건·납품·품질 선택·날짜 검증·픽셀 게시판.
- desktop/request_panel.gd: 목록·수량/품질/보상·수락/납품·불가 사유.
- world/main/pixel_world: 상호작용, L, 모달/싱글 일시정지, 데모, 지도 렌더.
- 저장23: 구버전1~22에 기본 상태를 보완한다. 상태/수락일/완료일 위변조·미래 일자를 거부한다.
- --requests-demo는 별도 requests-demo.json. 첫 실행에 준비된 재료로 즉시 체험할 수 있다. 일반 세계에서는 채집·제작·전투로 준비한다.

## 검증과 실행본
- python3 scripts/verify_rules.py: 전체761개 통과(의뢰39개).
- scripts/render_requests.gd: 실제 UI17개 통과. 최종 Mac 번들의 리소스로도17개 통과.
- python3 scripts/verify_requests_network.py: 실제 ENet 서버+두 클라이언트, 독립 진행/실제 이동/정확한 소비와 보상/중복 방지/비공개/대성공 연고 보존 통과.
- Mac 0.5.19 앱 정규화 및 codesign --verify --deep --strict 통과.
- Windows 0.5.19 export 및 PE32+ x86-64 확인. Windows 실기 실행은 미검증.
- 테스트는 임시 합성 월드만 사용했다. 사용자 저장을 수정하지 않았다.
- /Users/junheejang/Documents/Vestige/builds/Play-Requests.command
- /Users/junheejang/Documents/Vestige/builds/windows-0.5.19/Play-Requests.cmd
- 공용 체험 바로가기23종을 최신 버전으로 갱신했다.
- artifacts/art/requests-*.png: 게시판/수락/납품/완료/다음 날 화면.

새 빌드 검증 후 구형0.5.18 Mac 앱과 Windows 실행 패키지만 제거한다. 저장·백업·소스·Git·스크린샷은 보존한다. 게시/구매/main 병합은 수행하지 않는다.

## 남은 범위
현재는 고정 의뢰3종이다. 동적 의뢰 생성, 평판·지역 경제, 더 많은 주민/직업/아이템/스킬, 실제 신규 지역과 던전, 부활/경지, Steam 연동과 출시 검증은 후속 작업이다. 전체 상태는 PROJECT_STATUS.md를 기준으로 확인한다. 다음 신규 기능은 사용자 요청대로 대작 게임 참고를 조사해 먼저 승인받는다.
