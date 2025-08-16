# Swift Package 의존성 설정 가이드

Google Calendar 연동을 위해 필요한 Swift Package들을 Xcode 프로젝트에 추가하는 방법을 설명합니다.

## 🚨 현재 상황

현재 `GoogleCalendarService.swift`에서 다음과 같은 에러가 발생하고 있습니다:

```
No such module 'GoogleAPIClientForREST_Calendar'
No such module 'GoogleSignIn'
No such module 'GTMSessionFetcher'
```

이는 필요한 Swift Package 의존성이 아직 추가되지 않았기 때문입니다.

## 📦 필요한 Swift Package들

### 1. GoogleSignIn-iOS
- **URL**: `https://github.com/google/GoogleSignIn-iOS`
- **용도**: Google 계정 인증 및 OAuth 2.0 처리
- **버전**: 최신 안정 버전

### 2. google-api-objectivec-client-for-rest
- **URL**: `https://github.com/google/google-api-objectivec-client-for-rest`
- **용도**: Google Calendar API 클라이언트
- **버전**: 최신 안정 버전

### 3. gtm-session-fetcher
- **URL**: `https://github.com/google/gtm-session-fetcher`
- **용도**: HTTP 요청 처리 및 세션 관리
- **버전**: 최신 안정 버전

## 🔧 Xcode에서 Swift Package 추가하기

### 1단계: Xcode 프로젝트 열기
1. Xcode에서 `damda.xcodeproj` 파일 열기
2. Project Navigator에서 프로젝트 루트 선택

### 2단계: Package Dependencies 추가
1. **File → Add Package Dependencies...** 메뉴 선택
2. **Search or Enter Package URL** 필드에 패키지 URL 입력
3. **Add Package** 버튼 클릭

### 3단계: 각 패키지별 설정

#### GoogleSignIn-iOS 추가
```
1. URL 입력: https://github.com/google/GoogleSignIn-iOS
2. Dependency Rule: Up to Next Major Version
3. Target: damda 선택
4. Add Package 클릭
```

#### google-api-objectivec-client-for-rest 추가
```
1. URL 입력: https://github.com/google/google-api-objectivec-client-for-rest
2. Dependency Rule: Up to Next Major Version
3. Target: damda 선택
4. Add Package 클릭
```

#### gtm-session-fetcher 추가
```
1. URL 입력: https://github.com/google/gtm-session-fetcher
2. Dependency Rule: Up to Next Major Version
3. Target: damda 선택
4. Add Package 클릭
```

### 4단계: 패키지 설정 확인
1. Project Navigator에서 **Package Dependencies** 섹션 확인
2. 추가된 패키지들이 목록에 표시되는지 확인
3. 각 패키지의 상태가 정상인지 확인

## 📱 Target 설정

### 1단계: Target 선택
1. Project Navigator에서 **damda** 프로젝트 선택
2. **TARGETS** 섹션에서 **damda** 선택

### 2단계: General 탭 확인
1. **General** 탭 선택
2. **Bundle Identifier**가 `com.yourcompany.damda`로 설정되어 있는지 확인
3. **Deployment Target**이 적절한지 확인

### 3단계: Build Phases 확인
1. **Build Phases** 탭 선택
2. **Link Binary With Libraries** 섹션에 추가된 프레임워크들이 있는지 확인

## 🔍 문제 해결

### 일반적인 문제들

#### 1. 패키지 다운로드 실패
```
문제: "Failed to resolve package dependencies" 오류
해결:
- 인터넷 연결 상태 확인
- Xcode 재시작
- Derived Data 삭제 (Xcode → Preferences → Locations → Derived Data → Delete)
```

#### 2. 빌드 에러
```
문제: "Undefined symbol" 또는 "Linker error"
해결:
- Clean Build Folder (Product → Clean Build Folder)
- 프로젝트 재빌드
- Target의 Framework Search Paths 확인
```

#### 3. 버전 충돌
```
문제: "Version conflict" 오류
해결:
- Dependency Rule을 "Exact Version"으로 변경
- 충돌하는 패키지 버전 확인 및 조정
```

### 디버깅 팁

1. **Xcode 콘솔 확인**: 패키지 추가 과정에서 발생하는 오류 메시지 확인
2. **Package Dependencies 로그**: Xcode → Window → Organizer → Crashes에서 로그 확인
3. **네트워크 상태**: 방화벽이나 프록시 설정 확인

## ✅ 완료 후 확인사항

### 1. 컴파일 에러 해결
- `GoogleCalendarService.swift`의 import 에러가 해결되었는지 확인
- 프로젝트가 정상적으로 빌드되는지 확인

### 2. 패키지 상태 확인
- Package Dependencies에서 모든 패키지가 정상 상태인지 확인
- 각 패키지의 버전이 적절한지 확인

### 3. 테스트 실행
- `GoogleCalendarIntegrationTests`가 정상적으로 실행되는지 확인
- 기본 테스트가 통과하는지 확인

## 🚀 다음 단계

Swift Package 의존성 추가가 완료되면:

1. **GoogleCalendarService.swift**의 주석 처리된 코드 활성화
2. **GoogleService-Info.plist** 설정 파일 업데이트
3. **실제 Google Calendar 연동 테스트** 실행
4. **사용자 테스트** 및 피드백 수집

## 📚 참고 자료

- [Google Sign-In iOS 가이드](https://developers.google.com/identity/sign-in/ios)
- [Google Calendar API 가이드](https://developers.google.com/calendar/api/guides/overview)
- [Swift Package Manager 가이드](https://developer.apple.com/documentation/swift_packages)

---

**주의**: Swift Package 의존성 추가 후에는 반드시 프로젝트를 Clean Build하고 테스트를 실행하여 모든 것이 정상적으로 작동하는지 확인해주세요.
