# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features that will be added in the next release

### Changed
- Changes in existing functionality

### Deprecated
- Features that will be removed in upcoming releases

### Removed
- Features that have been removed

### Fixed
- Bug fixes

### Security
- Security vulnerability fixes

## [1.2.0] - 2025-08-18

### Added
- **Daily Phrases 기능**: 원격 제공자 + 캐시 시스템으로 일일 문구 제공
- **Today UI**: 2개의 일일 문구를 Today 위젯에 표시
- **목표 설정 기능**: 목표 편집 팝오버로 즉시 반영 가능
- **일일 롤오버 버튼**: 복원 및 개선된 기능
- **Anki Alarm 기능**: macOS 알림을 통한 암기 카드 알림
- **포괄적인 알림 관리**: 알림 목록 관리 및 삭제 기능
- **시스템 환경설정 연동**: 알림 권한 설정을 위한 시스템 환경설정 열기
- **사용자 정의 알림 스케줄링**: 개인화된 알림 시간 설정
- **전용 설정 섹션**: 개선된 UI/UX로 설정 관리
- **다국어 지원**: 한국어, 영어 완전 지원 (설정 및 알림 뷰 포함)
- **DMG 패키징**: 자동화된 DMG 생성 스크립트
- **개발/프로덕션 환경 분리**: 안전한 환경별 설정 관리

### Changed
- **알림 시스템 UI**: 인라인 알림 목록으로 간소화
- **알림 권한 처리**: 개선된 사용자 경험 및 피드백
- **Core Data 로딩**: 안전한 데이터 로딩 시스템
- **아키텍처**: damda-dev 스키마 분리로 개발 환경 안정화

### Fixed
- **진행률 계산 오류**: 오늘 목표 할 일 진행률이 어제 완료 항목을 포함하는 문제 해결
- **할 일 목록**: 어제 완료 항목이 오늘 리스트에 표시되는 문제 수정
- **롤오버 시스템**: 완료 상태 유지 및 데이터 일관성 개선
- **알림 권한**: 시스템 알림 권한 처리 안정성 향상
- **사용자 정의 알림**: 스케줄링 및 디버깅 기능 개선

### Technical
- **NotificationManager**: 디버그 출력 제거 및 코드 정리
- **CI/CD**: 조건부 표현식 개선 및 보안 강화
- **의존성 관리**: 프로젝트 설정 및 빌드 시스템 최적화

## [1.1.0] - 2025-01-XX

### Added
- 기본 UI 및 메인 기능 구현
- 카드 덱 관리 시스템
- SM-2 알고리즘 기반 카드 복습 기능
- 타이머 기능 (실시간 초 표시)
- 할 일 관리 시스템
- 암기 카드 시스템
- 통계 차트
- 목표 설정 및 추적

### Changed
- UI/UX 개선 (할 일/암기 카드 인라인 수정)
- 우선순위 및 구분선 기능
- 카드 스타일 및 폰트 (Pretendard)
- 다크모드 지원
- 반응형 디자인 및 스크롤 기능

## [1.0.0] - 2024-XX-XX

### Added
- damda 앱 초기 릴리즈
- 기본 기능 구현
- macOS 네이티브 앱
