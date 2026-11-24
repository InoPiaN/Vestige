# 장비 거래·되사기·대장간 수리 · 0.5.13

Codex · 2026-11-13 · codex/equipment-trade-repair · 기준 f132713. 작업트리 `/private/tmp/vestige-gear-provenance`. 원본 오래된 checkout 덮어쓰기 금지. 원격fetch 추가변경없음. 사용자 승인: 제작갑옷판매/강화가치/원가되사기최근10개/기록보존, 기존집수선+대장간유료수리. 작업완료후전체기능점검표도요청: `docs/PROJECT_STATUS.md`에 구현/부분/미구현/Steam/추천순서 정리. 다음새기능은조사→제안→승인 필수.

`village_market.gd`: 판매가=(종류/품질기본가+강화*2)*내구/100 내림최소1. 철검4/5/6, 가죽8/10/12, 철제14/17/20. 갑옷은maker있는제작품만, 시작/출처불명갑옷판매불가. 착용금지유지. 소비품/재료기존가격유지.

p.buyback은Storage.empty 컨테이너, p.buyback_orders는 {id,price,token} 최근10개. 판매시원ID/내구/품질/기록을보관함으로이동, sold기록, Crypto sale-token발급. 11개째이전오래된장비+메타데이터제거. market_repurchase(token) 소유인물/생존/직접조종/장터거리/잔액/종류한도검증→원가차감→원ID회수→repurchased기록. 토큰은판매마다새로발급하여과거요청이같은장비의다음재판매에적용되지않음. 재접속목록유지, 새생애미상속, 타인목록redact. 사망자의매입권은다른생애에넘기지않음. 자동판매/공유중고시장아님.

저장18, 1~17이관시빈매입함/영수증만추가. Market.valid 목록최대10/가격범위/ID토큰중복/장비종류검증. Storage.valid에모든매입함추가해전체컨테이너ID중복/수량/내구/품질/기록검증, 매입함은장비만/착용금지. 기록종류sold/repurchased추가. 미래19보호.

`forge_repair.gd`: 철검/가죽/철제갑옷. price=ceil((100-condition)/20)*(1+upgrade), 직접조종생존마을대장간근처/소지품검사. forge_repair value=id|expectedCondition|expectedPrice로오래된요청거절. 비용차감후내구100, repaired이력+메모. 품질/강화/제작자/난수/XP/수선도구변경없음. 온전한장비불가/무비용. 기존집수선40~50회복그대로.

UI: forge장비선택을강화/수리공유, 비용/내구전후/잔액/불가사유표시. market우측판매/되사기선택, 제작자/강화/내구/금액확인, 전체이력툴팁. 최신10개제한/초과소멸안내. 기존모달정지/ESC경로유지. 타이틀버전0.4.1잔존표시도0.5.13으로수정.

검증: 기존469+신규34=503개규칙. 신규판매/복구/중복요청/토큰재발급/보관한도/타인권리/두갑옷과철검수리/강화가격/17이관/백업/신생애등. 기존첫여정30/60Hz포함. `scripts/render_trade_repair.gd` 실제버튼수리→판매→되사기, PNG3개. `network_trade_repair.gd` 실제ENet수리→장터이동→해제→판매→되사기. 경로는집벽을피해(5,15)→(14,15)→(14,14), 시험중키보드0입력중복방지로client physics만정지, snapshot/RPC작동. 서버종료. 사용자저장미사용/tmp합성월드.

빌드: Mac0.5.13 export/ad-hoc서명/메뉴기동/번들기능검증. Windows0.5.13 export/PE32+x86-64, 실기미검증. Play-Trade.command/cmd, -- --trade-demo, 독립trade-demo.json. 손상35/+1철제갑옷과80은화로시작. 최신실행기전체갱신, 검증후0.5.12실행패키지만삭제, 저장/백업/Git/소스/스크린샷보존.

전체현황은 PROJECT_STATUS.md를우선. 과거 DEVELOPMENT_ROADMAP의각버전미완료표시는역사기록이므로최신완료여부와혼동금지. 출시/구매/main병합은임의실행하지않는다. 다음권장작업은전체플레이점검→첫완결원정→두번째마을이며사용자미승인제안이다.
