# 0.5.16 안개나루 여행 — 2026-11-19

## 승인과 범위
사용자가 두 번째 마을, 연결 숲길, 발견 지도, 발견 후 마차, 서신 의뢰 제안을 승인했다. 참고한 것은 GW2의 지역 탐험/이동점과 ESO의 발견 후 여행 방식이며 고유 아트/명칭은 복제하지 않았다.
- https://www.guildwars2.com/en/news/explore-the-world-of-guild-wars-2/
- https://www.elderscrollsonline.com/en-us/newplayerguide/questing

브랜치 `codex/mist-harbor-travel`. 작업 트리 `/Users/junheejang/Documents/Vestige/worktrees/professions-and-skills`. 부모 체크아웃은 과거 버전이므로 덮어쓰지 않는다. Claude UI 변경과 합칠 때 main/pixel_world 충돌을 검토한다.

## 구현
- `travel.gd`: village↔road↔harbor 이동, 개인 발견 기록, 서신 단계, 공유 상점, 마차 판정. 기존 person.room을 village/home/road/harbor로 확장. home의 지역은 village다.
- M 지도는 지역 단위, 첫 도착으로 발견. 마차는 두 마을 발견 및 현지 정류장 근접, 직접 조종/생존, 은화5를 서버에서 검증한다. 순간 이동이며 월드 시간을 추가 진행하지 않는다.
- 서신은 논리적 의뢰 상태(new/outbound/reply/done), 실물 아이템/도난 대상이 아니다. 생애별 1회 은화12. 새 생애는 발견과 의뢰가 초기화된다.
- 나루 상점은 목재/천/약초의 독립 공유 일일 재고, 여관은 무료 회복. 도윤·소하·유나 고정 상호작용. 지역 이동·발견·서신·구매는 일기에 기록.
- 새 지역에 늑대/기존 적, 제작대, 집 등 첫 마을 상호작용이 새지 않도록 지역 판정. 부재 여행자는 휴식만 하고 정책은 보존한다.
- 현장/유품/실물 증거에 지역 유지, 집 소유자의 묘비는 첫 마을에 안치. 후계자가 집→외지 현장→묘비 조사하고 유품 회수 가능.
- 저장21 및 구버전1~20 이관. 새 지역을 허용하지 않던 house_interior 저장 검증을 UI 재접속 검사에서 발견하여 수정했다.

## 검증
- `python3 scripts/verify_rules.py`: 653 PASS, 실패0. 여행45개 포함.
- `scripts/render_travel.gd`: 실제 Mac 렌더러 UI12 PASS, 숲길/나루 저장·재로드 포함. 최종 번들에서도 동일12 PASS.
- `python3 scripts/verify_travel_network.py`: 실제 ENet 서버+클라이언트 도보 이동, 서신, 지도 발견, 마차 운임, 귀환 보상 PASS. 임시 저장/서버는 종료/정리.
- 화면 `artifacts/art/travel-{unknown,road,harbor,shop,map}.png` 확인. 지역 지도/버튼 글자 겹침 없음.
- Mac0.5.16 정규화·ad-hoc 서명 검증. Windows x86_64 PE 생성, 실기 미검증.
- 최신 실행본/20개 체험 바로가기는 메인 `builds`에 보관. 기존0.5.15 실행 패키지만 삭제. 사용자 저장/소스/기록은 보존.

## 제한과 다음 작업
현재 두 마을과 안전한 연결 숲길이며 절차적 지도, 타일 안개, 나루 전용 전투/자원/직업, 시간제 마차, 여러 집/상속은 없다. 기존 마을에서 출구까지는 적이 있는 근교를 통과한다. 새 지역 부재 작업/자율 NPC 일정은 후속이다. 멀티는 로컬 ENet 검증까지이며 Steam/인터넷 운영 품질이 아니다.

전체 현황은 PROJECT_STATUS.md. 먼저 새 인물로 통합 플레이/밸런스를 확인하고 지역별 콘텐츠, 생활 직업/NPC 일정, 다중 주택/상속을 순차 확장하도록 제안한다. 새로운 기능은 대작 사례 조사와 사용자 확인 후 진행한다. 출시/구매/메인 병합은 하지 않았다.
