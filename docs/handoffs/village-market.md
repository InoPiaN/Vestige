# 마을 장터 · 0.5.3

Codex · 2026-11-10 · `feat/village-market` · 기준 `1e44ad6`.

village_market.gd는 (14,14)의 장터, 구매 품목·가격·정량 재고, 판매 가격과 권한 검사를 담당한다. world.act의 market_buy/market_sell은 물품 ID 하나만 받으며 가격/수량은 서버가 결정한다. 원격 위치·실내·부재·사망·부족 은화/소지 한도/재고·없는 물품을 거절한다. 철검은 정확한 gear ID를 거래하며 착용 중이면 거절한다. 판매 시 counter와 해당 gear_instances/gear_condition/gear_quality를 함께 제거한다. 시작 장비/증거/유물은 판매 불가. 판매물 되사기는 없고 재고에 합산하지 않는다.

market={day,stock}는 저장 버전9에 포함. 기존1~8 저장을 이관할 때 현재 날짜 재고만 만들고 지갑·인물·장비는 보존한다. advance 및 거래/저장 시 prepare로 다음 날짜의 정량 재고를 보충한다. 부재 며칠을 지나도 재고가 누적되지 않는다. 부정 재고/미래 day는 저장 검증에서 거절한다. 상점은 세계 공개 정보로 클라이언트 snapshot에도 포함된다. craft_rng 비공개는 유지한다.

구매: cloth3/8개, bent_nail2/12개, broken_cup3/3개, herb3/8개, ore4/8개. 판매: 재료 1(ore2), bandage3, repair_kit4, mug3, herbal_tea2. 양품+1, 대성공+2. 철검 일반4/양품5/대성공6에 condition/100을 곱해 내림, 최소1. 같은 품질 내 공격력 편차는 판매가에 반영하지 않는다. 의도적으로 구매-즉시판매 차익을 없앴지만 무한 채집·새 인물12은화 등 장기 경제는 후속 조정 대상이다.

UI: market_panel.gd 구매/판매 목록, 금액·재고·소지수량·착용 표시, 장비 tooltip. main.gd의 modal 숨김/ESC/싱글 일시정지/멀티 이동 차단/새 snapshot 갱신에 연결. Claude UI 작업 시 market action/refresh/위치 및 멀티 권한 규칙을 유지할 것. pixel_world.gd에 작은 천막 장터를 추가했다. F의 Mira 조사 기능은 그대로다.

검증: 248개 검사(새 market24)와 첫 여정30/60Hz 통과. 실제 ENet 서버/클라이언트 구매→대성공 붕대판매→동일품 재판매 거절, 지갑·재고 서버 일치 확인. 시험 서버 종료. scripts/render_market.gd로 독립 SubViewport 화면 렌더링·육안 확인. 사용자 저장을 시험하거나 초기화하지 않았다.

체험: scripts/play_market.command → builds/Play-Market.command, Windows Play-Market.cmd, -- --market-demo. 별도 market-demo.json. 기존 품질 예시 인물을 장터 앞에 배치하고 30은화를 제공한다. 최신 0.5.3 앱을 사용하며 기존 체험도 같은 빌드로 실행한다.

남은 작업: 생활 제작 숙련도 및 품질 확률 성장, 장기 경제 균형·거래 UI 개선/되사기, 다중 주택/상속·가구 배치, 다른 장비 제작/강화, Windows 실기·Claude UI 통합·Steam 준비. 누적 기능 브랜치이며 main 병합은 별도.

빌드 결과: Mac0.5.3 export·finalize_macos의 ad-hoc 서명 검증·headless 메뉴 기동 통과. Windows0.5.3 export와 PE32+ x86-64 형식 확인, Windows 실기 실행은 미검증. builds/Village-Market.png에 화면 예시. 빌드 산출물과 사용자 저장은 Git에 포함하지 않는다.
