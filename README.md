# DAMDA

할 일, 타이머, 목표 달성 여부, 암기카드(Anki 스타일)까지 한 번에 관리하는 macOS 생산성 앱입니다. 사이드바에서 한국어/영어를 즉시 전환할 수 있는 다국어(i18n) 지원을 제공하며, vibe coding으로 개발되었습니다.

![screenshot](docs/main.png)

---

## 설치 방법

현재 DMG 배포는 제공하지 않습니다(Apple Developer 서명/노타라이즈 미적용). 소스 빌드로 사용하세요.

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

---

## 빠른 시작
1. 사이드바에서 언어(한국어/English) 선택 — 즉시 UI 반영
2. 할 일 추가 및 우선순위 설정
3. 타이머에서 세션(아침/오후/저녁) 시작/일시정지/리셋
4. 목표 진행률 확인(공부 시간/할 일)
5. Deck 생성 → 카드 추가 → 오늘 복습 시작(SM-2 기반 미리보기/툴팁)

---

## 환경 분리(Prod/Dev)

- 스킴: `damda`(Prod), `damda-dev`(Dev) — 데이터/모델/설정 분리
- Core Data 모델은 경량 마이그레이션 옵션 활성화
- 실행 방법: Xcode 우측 상단 Scheme에서 선택 후 실행

---

## 데이터 관리
- 저장소: Core Data (엔티티: Todo, TimerRecord, StreakRecord, Card, Deck)
- SRS 알고리즘: SM-2 기반 간격 반복 복습, 버튼 미리보기/툴팁(간격, EF, 반복수)
- Card 필드: `dueDate(Date?)`, `deckId(Int64?)` — 오늘 복습 필터/덱 필터 반영
- 상태 저장: UserDefaults로 일부 앱 설정·타이머/카드 상태 보존
- 모델 경로: `damda/Model/damda.xcdatamodeld` (경량 마이그레이션 사용)

---

## 완성도 및 로드맵
- 현재
  - Todo/타이머/목표 추적/통계/암기카드/덱 관리 기본 기능 안정화
  - 자연어 복습 표기(오늘/내일/N일 뒤) 및 다크모드 대응
  - 다국어(한국어/영어) 즉시 전환 지원
- 다음 단계(예시)
  - 덱 일괄 작업(여러 카드 이동), 정렬/검색 고도화
  - 덱 삭제 고급 옵션(다른 덱으로 이동/해제/취소 선택)
  - 카드/덱 통계 심화, 하루 복습 한도 등 옵션
  - 마이크로 인터랙션·전환/호버/스켈레톤 강화

---

## 기술 스택
- Swift 5, SwiftUI
- Core Data
- XCTest(Unit Tests)
- Charts(SwiftUI Charts)
