# DAMDA

할 일, 타이머, 목표 달성 여부, 암기카드(Anki 스타일)까지 한 번에 관리하는 macOS 생산성 앱입니다. 사이드바에서 한국어/영어를 즉시 전환할 수 있는 다국어(i18n) 지원을 제공하며, vibe coding으로 개발되었습니다.

![screenshot](docs/main.png)


## 설치 방법

### DMG 패키지 다운로드
최신 릴리즈에서 `damda.dmg` 파일을 다운로드하여 설치하세요.

### 소스 빌드
```bash
git clone https://github.com/ShinBeomsoo/damda.git
cd damda
open damda.xcodeproj
# Xcode에서 스킴 'damda' (Prod) 또는 'damda-dev' (Dev) 실행(⌘R)
```

### 커맨드라인 빌드
```bash
xcodebuild -project damda.xcodeproj -scheme damda -configuration Release build
```


## 빠른 시작
1. 사이드바에서 언어(한국어/English) 선택 — 즉시 UI 반영
2. 할 일 추가 및 우선순위 설정
3. 타이머에서 세션(아침/오후/저녁) 시작/일시정지/리셋
4. 목표 진행률 확인(공부 시간/할 일)
5. Deck 생성 → 카드 추가 → 오늘 복습 시작(SM-2 기반 미리보기/툴팁)
6. Anki Alarm 설정으로 복습 알림 받기


## 환경 분리(Prod/Dev)

- 스킴: `damda`(Prod), `damda-dev`(Dev) — 데이터/모델/설정 분리
- Core Data 모델은 경량 마이그레이션 옵션 활성화
- 실행 방법: Xcode 우측 상단 Scheme에서 선택 후 실행


## 데이터 관리
- 저장소: Core Data (엔티티: Todo, TimerRecord, StreakRecord, Card, Deck)
- SRS 알고리즘: SM-2 기반 간격 반복 복습, 버튼 미리보기/툴팁(간격, EF, 반복수)
- 상태 저장: UserDefaults로 일부 앱 설정·타이머/카드 상태 보존
- 모델 경로: `damda/Model/damda.xcdatamodeld` (경량 마이그레이션 사용)


## 완성도 및 로드맵

### ✅ 완성된 기능
- **Todo 관리**: 할 일 추가/수정/삭제, 완료 상태 추적, 우선순위 설정
- **타이머 시스템**: 세션별 타이머(아침/오후/저녁), 일시정지/리셋, 학습 시간 통계
- **목표 추적**: 일일 학습 시간 목표, 할 일 완료 목표, 진행률 시각화
- **암기카드 시스템**: SM-2 알고리즘 기반 간격 반복, 덱별 카드 관리
- **덱 관리**: 덱 생성/수정/삭제, 카드 할당/해제, 실시간 필터링
- **다국어 지원**: 한국어/영어 즉시 전환, 모든 UI 텍스트 현지화
- **테마 지원**: 라이트/다크 모드 자동 전환
- **통계 및 차트**: 학습 시간, 할 일 완료율, 연속 달성 기록
- **자동 하루 마감**: 설정 가능한 자동 마감 시간
- **Anki Alarm**: 기본 알림(12시, 18시) + 사용자 정의 알림, 시스템 알림 권한 관리
- **덱 내보내기/가져오기**: JSON 형식으로 덱과 카드 데이터 백업 및 복원
- **설정 관리**: 전용 설정 섹션, 목표 설정, 알림 설정 통합 관리

### 🚧 개발 중인 기능
- **Google Calendar 연동**: 외부 API 의존성으로 인해 지연
- **로그인 시 자동 실행**: macOS 보안 정책으로 인해 지연

### 🔮 향후 계획
- **덱 일괄 작업**: 여러 카드 동시 이동, 정렬/검색 고도화
- **고급 덱 옵션**: 덱 삭제 시 다른 덱으로 이동/해제/취소 선택
- **카드/덱 통계 심화**: 하루 복습 한도, 학습 패턴 분석
- **마이크로 인터랙션**: 전환/호버/스켈레톤 로딩 강화
- **단축키 지원**: 키보드 단축키로 빠른 작업 수행
- **위젯 지원**: macOS 위젯으로 빠른 상태 확인


## 시스템 요구사항
- **운영체제**: macOS 15.5 (Sequoia) 이상
- **프로세서**: Apple Silicon (M1, M2, M3, M4 시리즈) Mac
- **메모리**: 최소 8GB RAM (16GB 권장)
- **저장공간**: 앱 크기 약 10MB + 데이터 저장용 여유 공간
- **아키텍처**: ARM64 (Apple Silicon 전용)


## 기술 스택
- **언어**: Swift 5, SwiftUI
- **데이터**: Core Data, UserDefaults
- **테스트**: XCTest (Unit Tests)
- **차트**: SwiftUI Charts
- **알림**: UserNotifications Framework
- **로컬라이제이션**: NSLocalizedString, Localizable.strings
- **빌드**: Xcode 15+, macOS 15.5 SDK
