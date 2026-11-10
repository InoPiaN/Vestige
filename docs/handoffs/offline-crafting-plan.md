# 부재 중 제작 계획 · 0.5.5

Codex · 2026-11-11 · feat/offline-crafting-plan · 기준7f7831a.

사용자 규칙: 새 기능은 관련 대작 게임 조사→Vestige 적용안 제안→사용자 승인 후 구현. 이번 계획1개/지정횟수·목표수량/하루1개/회복우선/집소유·도구·재료/일기 범위는 승인받았다. CRAFTING_REFERENCES.md에 출처와 범위를 추가했다. 다음 기능을 임의로 착수하지 말 것.

craft_plan.gd: p.craft_plan={} 또는 {recipe,mode,amount,remaining,status}. recipe=iron_sword,repair_kit,mug,bandage,herbal_tea; mode=count,target. 수량1..아이템소지한도, remaining0..amount. 새저장11에서 종류/형식/정수/범위 검증. 기존1~10은 빈 계획만 추가하고 기존work 등 정책 유지. policy=plan일 때만 실행. plan_save/plan_start 값은 recipe|mode|amount이며 실제생산량/재료/확률/XP는 서버 계산. plan_start는offline=true, save는현재조종상태유지. 같은내용저장은remaining초기화하지 않음. 취소 후 재등록하면 새횟수. 다른정책선택시 계획보존·실행중단, plan_cancel은계획삭제+rest.

world.advance의 기존날짜처리에 Plan.day를 연결했다. hp<40인날은회복만. count완료나target충족시쉬고, target은가족품질수량합산으로판단. 실패사유도기록하고hp25회복. 성공은소지재료만소비,완성품도소지. 실제home production은Crafting.reason/craft의내부automated인자(외부RPC에는노출안함)를통해같은재료·도구·불·확률·XP를사용. Plan이집소유를검사하고홈작업대위치로하루작업을정산. 철검은world.forge_sword Callable로공유하여순환preload회피. 완성횟수만감소. 새삶은빈계획,사망자일기는기존books로남음. craft_plan은타인snapshot에서제외.

온라인부재인물은소유집으로이동해입장/작업대접근,철검은대장간으로이동한다. 일일정산은기존부재시뮬레이션처럼추상화된작업이며완성시작업장좌표를적용한다. 정교한작업시간/이동경로/장소별위험도는별도후속범위. 싱글종료후경과시간정산,멀티서버중단시간은기존대로정지.

UI: 오른쪽policy목록마지막 제작계획설정에서planner. allow_reselect=true로이미선택된계획도다시열수있다. 저장/저장·맡기기/취소. draft선택은매snapshot에덮어쓰지않고현재재료·저장계획상태만갱신. J에도계획요약. 다른modal/ESC/싱글일시정지/멀티이동차단연동. Claude UI통합시action과refresh연결유지.

검증: 신규27포함304개검사와첫여정30/60Hz,실제ENet 날짜경계생산·완료계획재전송·일기확인. 실제설정버튼→1일진행→남은2/3표시렌더링확인. 재접속동일시각중복없음/구버전/손상계획/사망/직접대비품질XP/찻잔불/소유집/목표재개/저체력/부족재료검사. 시험서버종료. UI시험저장은/tmp로격리후삭제,사용자저장은건드리지않았다.

체험: Play-Plan.command/cmd 또는 -- --plan-demo, 별도plan-demo.json. 본인집·천5·약초3·hp100으로붕대3개계획체험. 기존실행기도0.5.5로연결. README진입경로참조.

미구현: 자동구매/판매·집보관함자동인출·복수계획/우선순위·중간재료자동제작·장기경제균형. 다음은관련작품조사와승인부터. 누적기능브랜치이며main병합은별도.

빌드 결과: Mac0.5.5 export·ad-hoc 서명검증·headless 메뉴기동 통과. Windows0.5.5 export 및 PE32+ x86-64 형식 확인, Windows 실기 실행은 미검증. builds/Offline-Crafting-Plan.png에 설정·진행 화면. 빌드와 사용자 저장은 Git에 넣지 않는다.
