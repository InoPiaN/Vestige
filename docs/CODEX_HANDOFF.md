> 최신 작업 (2026-11-12): **0.5.12 방어구 강화와 도트 효과**. 실제 작업트리 `/private/tmp/vestige-gear-provenance`, 브랜치 `codex/armor-upgrades`. [최신 인수인계](handoffs/armor-upgrades.md)를 먼저 읽으세요.

> 최신 작업 (2026-11-12): **0.5.11 복수 부재 제작 계획**. 실제 작업트리 `/private/tmp/vestige-gear-provenance`, 브랜치 `codex/offline-crafting-queue`. [최신 인수인계](handoffs/offline-crafting-queue.md)를 먼저 읽으세요. 아래는 초기 단계의 기록입니다.

# Vestige 인계 — 2026-11-05 최신

## 사용자 의도
Steam 출시용 픽셀 다크판타지 지속 세계 RPG. 싱글/멀티 완전 분리, 부재 생활, 현실 1년 이상 수명, 경지/부활, 남겨진 일기. 작은 픽셀로 개성 있는 인물. 마을 아트는 현재 수준 유지. 사용자는 작업 목록 후 순차 실행을 선호한다.

새 핵심: 집/부동산/건축, 사망 후 집·현장·묘비에 기록이 남고 새 인물로 죽음의 진실을 추적하는 플레이. 전체 개발 목록과 구체 설계는 `docs/DEVELOPMENT_ROADMAP.md`가 최신 기준이다. 주택/수사는 아직 미구현.

## 이번 완료
- `desktop/world.gd`: 외형 검증, 장비 상태, 기존 저장 보완, 장착 철검에 따른 공격력.
- `desktop/main.gd`: 신규 싱글 생성 화면, 외형 선택, 새 삶 생성, 장비 창, 투구 숨김, 멀티 외형 등록.
- `desktop/pixel_world.gd`, `portrait.gd`: 머리 3종/색 4종, 피부 3종/의복 4종, 갑옷/후드/망토/철검 레이어와 미리보기.
- 갑옷/후드/망토는 시작 외형 장비이며 방어력은 아직 없음. 철검 소유와 착용은 분리. 제작 시 자동 장착, 부재 제작은 보관.
- 규칙 9개 검사, 외형/장비/생성 UI/저장 검사 12개 통과. 두 ENet 클라이언트의 외형/장비/이동 동기화 통과. 임시 서버 종료 완료.
- 실제 Godot 렌더러로 생성/장비 UI 확인. `artifacts/art/character-creation.png`, `character-equipment.png`. `scripts/render_customization.gd`로 재생성.
- Mac `builds/Vestige-0.3.0.app`, Windows `builds/windows-0.3.0/Vestige.exe`. Mac 정규화/서명 검증 통과. Windows 실기 실행 미검증.
- 기존 사용자 저장은 직접 편집하거나 초기화하지 않음. 테스트 저장은 /tmp의 별도 파일 사용.

## 다음 작업
1. 4방향 걷기/공격/피격과 장비 애니메이션. 현재 공통 자세/발 움직임/검격 효과만 있다.
2. 저장 버전/복구 및 전투-유적-귀환 완결 검증. 장비 실제 마우스 조작의 장시간 수동 QA와 Windows 실기 검증도 필요.
3. 주택 한 채와 인물 생애 ID, 사건 ID, 집/현장/묘지 단서 보존 및 조사 수첩으로 한 사건 완결.
4. 두 번째 마을·건축/부동산 확장, NPC 관계, 성장·경지·제작·부활, Steam 순서. 상세 체크리스트는 개발 목록 참고.

## 실행/검증
Godot: `.tools/godot/Godot.app/Contents/MacOS/Godot`
프로젝트: `desktop/project.godot`
검사: `--headless --path desktop --script tests/test_world.gd --log-file /tmp/vestige-tests.log` 및 `tests/test_customization.gd`.
네트워크: 별도 `-- --server --world-file=/tmp/고유파일.json` 서버와 `tests/network_client.gd` 두 프로세스. 로컬 UDP 접근은 sandbox 밖 실행이 필요할 수 있다.
Mac 후처리: `python3 scripts/finalize_macos.py builds/Vestige-0.3.0.app`
일반 실행은 기존 single-world.json, `-- --qa`는 qa-world.json 사용. QA에서도 저장 삭제하지 않는다.

`vestige` 크레딧 회복 예약은 이전에 삭제 완료. 자동 예약 없음. 사용자 요청 없는 에이전트 위임/출시/구매 하지 않는다.

## 최신 0.3.1: 인벤토리

`desktop/items.gd` 카탈로그와 `inventory_panel.gd` 추가. 기존 자원 수량을 단일 원본으로 읽고 시작 장비 소유는 belongings에 저장. 아이콘/필터/정렬/설명/수량/착용·해제/약초 사용/I 단축키. 단일은 모달 정지, 멀티는 시간 계속. 가득 찬 체력에 약초 사용 차단. 인벤토리 테스트 9개 통과, 기존 규칙9/외형12 검사 통과. `artifacts/art/inventory.png` 렌더러 결과 확인. 최신 빌드는 `builds/Vestige-0.3.1.app`, `builds/windows-0.3.1/Vestige.exe`.

후속: 개별 장비 옵션/내구도, 드래그·묶음 분할, 무게, 보관함·유품·증거 아이템. 이번 버전은 종류별 묶음 관리. Windows 실기 미검증.
