# 방향별 캐릭터 동작 인계

2026-11-06 · Codex · `feat/directional-character-animation` · 기준 커밋 `8b1f152`

`desktop/world.gd`가 방향과 실제 이동량, 공격·채집 구분, 피격 시간을 기록한다. `desktop/animation.gd`와 `desktop/pixel_world.gd`는 이 상태로 방향별 발걸음과 무기 자세를 그린다. `artifacts/art/directional-animation.png`에서 방향별 장비 동작을 비교할 수 있다.

검증은 `desktop/tests/test_animation.gd`와 기존 규칙·외형·인벤토리 검사를 사용한다. 다음 전투 플레이 검증은 늑대전 승리, 유적 보상, 마을 귀환을 한 흐름에서 확인한다. Claude가 같은 파일을 수정했다면 병합 전에 양쪽 브랜치의 변경을 비교한다.
