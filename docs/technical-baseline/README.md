# VESTIGE 기술 기준점 · 2026-11-22

이번 작업은 분석·문서화다. 게임 코드, 저장 형식, 기본 브랜치, 스태시는 변경하지 않았다.

1. [Current Architecture Report](CURRENT_ARCHITECTURE_REPORT.md)
2. [Feature Inventory](FEATURE_INVENTORY.md)
3. [Branch Integration Report](BRANCH_INTEGRATION_REPORT.md)
4. [AI Data Integration Proposal](AI_DATA_INTEGRATION_PROPOSAL.md)
5. [Development Roadmap](DEVELOPMENT_ROADMAP.md)
6. [실제 검증 결과·한계](VALIDATION_RESULTS.md)
7. [변경 파일 및 커밋 기록](CHANGE_RECORD.md)

게임 기준 codex/village-requests@4ba2c21와 조사 기준 feature/chapter1-evidence-board@f9c4a35는 main@8b1f152에서 갈라졌다. G를 기반으로 조사 모듈을 별도 이식하는 방향을 권장하며, 실제 통합은 아직 하지 않았다.

G 규칙761개와 S 헤드리스 검사279개는 통과했다. S 실제 ENet 회귀는 재접속 후 서버 송신 오류로 실패했다. 두 계열의 테스트 통과 여부를 통합 게임 완료로 해석하지 않는다.

앞으로의 순서는 사용자 지정: 01통합·안정화 → 02데이터 관리 → 03플레이 경험 → 04이벤트/퀘스트 상태 머신 → 05NPC 행동/기억 → 06생성형 AI. ChatGPT는 설계·명세·ID/지식 구조, Codex는 구현·통합·검증을 맡는다. 설계 문서의 존재는 코드 구현의 증거가 아니다.
