# 캐릭터 도트 디테일과 강화 이펙트 · 0.5.9

Codex · 2026-11-12 · feat/character-detail-effects · 기준52a5156(승인된시안). 작업트리 /private/tmp/vestige-gear-provenance. 사용자 시안승인 후4방향/동작/커스터마이징/단계별이펙트확장을완료했다. 원격fetch에추가변경없음, main병합별도.

## 렌더링

character_detail.gd: 약32x52 격자의 세밀한 캐릭터를 자체직사각형/선으로 그린다. 얼굴·머리·의복·가죽·금속·벨트·칼날/손잡이. clean_look의 기존옵션전부, 장비슬롯과투구숨김,4방향, 걷기발/몸움직임,공격/회복팔·검,피격/회피색을적용한다. pixel_world.hero는원래월드위치에0.5배로이렌더러를호출하며왼쪽은미러. 맵그리기함수와지형텍스처는변경하지않았다. 주민과장비미리보기도같은hero경로다.

중요: 기존480x320뷰포트에서반픽셀로그리면디테일이사라진다. main.gd 월드뷰포트960x640 + canvas_transform2배, 컨테이너1배로변경했다. 기존맵1픽셀은화면2픽셀, 새캐릭터1픽셀은화면1픽셀. 장비초상은64x72 + canvas2배 + 컨테이너3배. 타이틀은960x640 + canvas2배 + 컨테이너0.6배로원래표시크기유지. canvas_transform설정은뷰포트를트리에붙인후실행해야Godot canvas_map오류가없다. ClaudeUI통합시이배율조합과nearest필터를보존해야한다.

효과는실제equipped_ids.weapon의gear_quality.upgrade만읽는다. +1은빛 가장자리, +2푸른빛/간헐입자, +3선명한빛/공격잔상. 블러없음, 칼날주변제한. 맨손이나사망시에효과없고레거시단계누락은0. 시각시계는로컬이며입자위상까지멀티동기화하지않는다. 전투/강화/저장스키마는기존14유지.

## 검증과 산출물

기존371개검사및첫여정30/60Hz통과. tests/visual_character.gd는실제GPU픽셀hash비교24개: 머리/색/피부/옷, 장비3종, 투구숨김,4방향,걷기/공격/회복/피격/회피,강화3단계,시간변화입자,해제시효과제거,레거시기본,사망투명. headless는GPU이미지검사에사용하지않는다.

scripts/render_character_detail.gd:24동작/외형샘플과실제Main필드/장비UI렌더링. artifacts/art/character-motion-sheet.png, character-world.png, character-equipment.png. 시안PNG는역사기록으로보존하며현재실제화면은위산출물이기준이다. 합성세계사용,사용자저장미접근. Mac실행번들내데모함수를별도/tmp검사로실행해실제+0~+3철검/착용+3/저장유효성확인.

Play-Detail.command/cmd 또는 -- --detail-demo. 별도detail-demo.json에실제제작/강화된4개철검. 기존체험과일반월드는보존. +3착용으로시작하며외형·장비에서단계별교체, WASD/SPACE동작확인. 신규인물생성에서기존외형옵션도세밀해진렌더링을사용한다.

Mac0.5.9내보내기/ad-hoc서명/메뉴기동/번들데모검사완료. Windows0.5.9내보내기/PE32+x86-64확인, 실기미검증. 빌드와공용Play실행바로가기는최신0.5.9. 사용자요청에따라이전0.5.8 Mac/Windows실행패키지는검증후삭제한다. 사용자저장·복구·소스·Git이력은보존.

후속은다른무기/방어구와체형실루엣,경제균형,주택/상속,제작노트,사망추적확장,ClaudeUI통합,Windows실기,Steam준비. 매새기능은관련게임조사→적용안→사용자승인부터진행한다.
