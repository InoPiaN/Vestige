# 집 보관함 제작 연동 · 0.5.6

Codex · 2026-11-11 · feat/home-crafting-storage · 기준98cf412.

사용자 규칙: 새작업은대작게임조사→Vestige적용안제안→승인후구현. 이번 집보관함 연동범위는 승인받았고 CRAFTING_REFERENCES.md에출처추가. 다음기능은별도조사·승인부터.

craft_supply.gd: person.craft_supply={source:bag|home,destination:bag|home}. 직접제작설정. plan에는독립source/destination. sourcehome이면집우선분배후부족량만소지품차감, destinationhome이면완성품집추가. source또는destination이home이면살아있는본인소유집검사. 창고총40개한도는 Storage.total(box)-집재료소비량+1로계산, 배낭목적지는기존품목가족소지한도. 검증후한번에소비/난수/결과/XP적용. 찻잔은활성범위최고품질,미소비. 수선은이번범위밖이므로소지도구만사용한다.

Crafting.reason/craft에settings Dictionary선택인자추가. 직접기본은p.craft_supply, 계획은plan자체를명시하여직접설정이부재계획에침범하지않음. Plan.configure는기존3부분문자열을bag/bag로호환하고 새5부분(recipe|mode|amount|source|destination)을수용. 철검의집옵션은거절. 배분설정만변경시remaining유지. 계획target은연동옵션하나라도home이면소지+본인집가족수량합산. 기존횟수상한은품목소지한도유지. 소유권상실시집은합산/소비하지않고생활제작은기존소유검사에서중단한다.

저장12: craft_supply와비어있지않은plan의배분설정검증. 기존1~11은bag/bag추가, remaining유지. 직접설정은craft_supply 액션으로서버검증. snapshot에서살아있는집소유자에게집재고를제공해작업대/계획UI가계산가능하게함. storage_access(보관함옮기기권한)는기존근접검사를유지하므로재고열람이원격인출권한을주지않는다. 타인craft_supply제외, 다른집내부정보비공개유지.

UI: 작업대목록아래2개옵션,위치별재료수량·보관용량, 찻잔실제품질/확률. 계획오른쪽2개옵션,철검선택시bag고정,집합계목표표시. Claude통합시data/action/refresh경로유지. 원격다른변경은작업시작시없었다.

검증: 신규24포함328개검사+첫여정30/60Hz. 실제ENet 집재료직접제작→집연동계획1개→날짜경계부재제작→재요청횟수보존. script/render_supply.gd가실제버튼으로직접/계획생산과집저장을확인하고두화면렌더링. 시험서버종료,임시UI저장/tmp후삭제. 사용자저장미사용. 분할재료·집우선·용량순감소·포화실패원자성·최고품질도구·소유권·원격거절·합산목표·이동·구버전검사.

체험: Play-Supply.command/cmd, -- --supply-demo, 독립supply-demo.json. 재료는집에천6약초6,소지재료0,직접제작home/home. E제작후보관함에서B확인. 부재계획은별도옵션설정필요.

후속: 경제/숙련균형,복수계획,주택확장/상속,제작노트전승,다른장비,Steam준비. 다음에도조사/승인먼저. 누적기능브랜치이며main병합별도.

빌드 결과: Mac0.5.6 export·ad-hoc 서명 검증·headless 메뉴 기동 통과. Windows0.5.6 export 및 PE32+ x86-64 형식 확인, Windows 실기 미검증. builds/Home-Crafting-Storage.png 화면 보관. 빌드 산출물과 사용자 저장은 Git에 포함하지 않는다.
