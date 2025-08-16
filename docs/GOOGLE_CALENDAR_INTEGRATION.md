# Google Calendar 연동 가이드

damda 앱에서 Google Calendar와 연동하여 할 일과 공부 기록을 동기화할 수 있습니다.

## 🚀 주요 기능

- **Google Calendar 인증**: Google 계정으로 로그인하여 연동
- **할 일 동기화**: damda에서 생성한 할 일을 Google Calendar 이벤트로 변환
- **타이머 기록 동기화**: 공부 시간 기록을 Google Calendar 이벤트로 저장
- **양방향 동기화**: Google Calendar의 이벤트를 damda에서 확인 가능
- **실시간 업데이트**: 변경사항이 즉시 반영

## 📋 사전 준비사항

### 1. Google Cloud Console 설정

1. [Google Cloud Console](https://console.cloud.google.com/)에 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. Google Calendar API 활성화
4. OAuth 2.0 클라이언트 ID 생성
5. `GoogleService-Info.plist` 파일 다운로드

### 2. OAuth 2.0 클라이언트 설정

```
1. Google Cloud Console > APIs & Services > Credentials
2. "Create Credentials" > "OAuth 2.0 Client IDs"
3. Application type: "macOS"
4. Bundle ID: com.yourcompany.damda
5. 클라이언트 ID와 클라이언트 시크릿 생성
```

### 3. Google Calendar API 스코프 설정

필요한 스코프:
- `https://www.googleapis.com/auth/calendar`
- `https://www.googleapis.com/auth/calendar.events`

## ⚙️ 설정 방법

### 1. 설정 파일 업데이트

#### GoogleService-Info.plist
```xml
<key>CLIENT_ID</key>
<string>YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com</string>
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.YOUR_ACTUAL_REVERSED_CLIENT_ID</string>
```

#### Info.plist
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.YOUR_ACTUAL_REVERSED_CLIENT_ID</string>
</array>
```

### 2. Xcode 프로젝트 설정

#### Swift Package Manager 의존성 추가
```
1. Xcode > File > Add Package Dependencies
2. 다음 패키지들 추가:
   - GoogleSignIn: https://github.com/google/GoogleSignIn-iOS
   - GoogleAPIClientForREST: https://github.com/google/google-api-objectivec-client-for-rest
   - GTMSessionFetcher: https://github.com/google/gtm-session-fetcher
```

#### Bundle ID 확인
```
1. Project Navigator에서 프로젝트 선택
2. Target > damda > General
3. Bundle Identifier가 Google Cloud Console에 등록한 것과 일치하는지 확인
```

## 🔧 사용 방법

### 1. Google Calendar 연동 설정

1. damda 앱 실행
2. 사이드바에서 "설정" 선택
3. "Google Calendar" 섹션에서 "설정" 버튼 클릭
4. "Google 계정으로 로그인" 버튼 클릭
5. Google 계정 선택 및 권한 승인

### 2. 동기화 설정

연동 완료 후 다음 옵션들을 설정할 수 있습니다:

- ✅ **Google Calendar 동기화 활성화**: 전체 동기화 기능 켜기/끄기
- ✅ **할 일 동기화**: damda 할 일을 Google Calendar 이벤트로 변환
- ✅ **타이머 기록 동기화**: 공부 시간 기록을 Google Calendar에 저장
- ✅ **공부 세션 동기화**: 공부 세션 정보를 Google Calendar에 기록

### 3. 동기화 테스트

"동기화 테스트" 버튼을 클릭하여 Google Calendar에서 이벤트를 가져올 수 있습니다.

## 📱 UI 변경사항

### CalendarView
- Google Calendar 연동 상태 표시
- Google Calendar 이벤트를 녹색 점으로 표시
- 월 변경 시 자동으로 Google Calendar 이벤트 로드

### SettingsView
- Google Calendar 설정 메뉴 추가
- 연동 상태 및 설정 관리

## 🔍 문제 해결

### 일반적인 문제들

#### 1. 인증 실패
```
문제: "Google Calendar 인증에 실패했습니다" 오류
해결: 
- GoogleService-Info.plist 파일이 올바른 위치에 있는지 확인
- Bundle ID가 Google Cloud Console과 일치하는지 확인
- 인터넷 연결 상태 확인
```

#### 2. 권한 오류
```
문제: "권한이 없습니다" 오류
해결:
- Google Cloud Console에서 Google Calendar API가 활성화되어 있는지 확인
- OAuth 동의 화면에서 필요한 스코프가 추가되어 있는지 확인
```

#### 3. 이벤트 동기화 실패
```
문제: "이벤트 동기화에 실패했습니다" 오류
해결:
- Google Calendar API 할당량 확인
- 네트워크 연결 상태 확인
- 앱 재시작 후 재시도
```

### 디버깅 팁

1. **콘솔 로그 확인**: Xcode 콘솔에서 Google Calendar 관련 오류 메시지 확인
2. **네트워크 요청 확인**: Network Inspector에서 API 호출 상태 확인
3. **권한 확인**: macOS 시스템 환경설정 > 보안 및 개인정보 보호에서 앱 권한 확인

## 📊 성능 최적화

### 1. 이벤트 로딩 최적화
- 월별로 이벤트를 나누어 로드
- 캐싱을 통한 중복 요청 방지
- 백그라운드에서 이벤트 동기화

### 2. 메모리 사용량 최적화
- 불필요한 이벤트 객체 제거
- 이미지 및 리소스 캐시 관리
- 메모리 누수 방지

## 🔒 보안 고려사항

### 1. OAuth 2.0 보안
- 클라이언트 시크릿은 클라이언트에 저장하지 않음
- HTTPS를 통한 모든 통신
- 토큰 만료 시 자동 갱신

### 2. 사용자 데이터 보호
- Google Calendar 데이터는 로컬에 저장하지 않음
- 사용자 동의 없이 데이터 공유하지 않음
- 개인정보 보호 정책 준수

## 📈 향후 계획

### 1. 추가 기능
- [ ] Google Calendar 이벤트 편집 기능
- [ ] 반복 이벤트 지원
- [ ] 여러 캘린더 지원
- [ ] 오프라인 동기화

### 2. 성능 개선
- [ ] 배치 동기화 최적화
- [ ] 실시간 푸시 알림
- [ ] 스마트 캐싱 시스템

## 📞 지원

Google Calendar 연동 관련 문제가 발생하면:

1. 이 문서의 문제 해결 섹션 확인
2. GitHub Issues에 문제 보고
3. 개발팀에 직접 문의

---

**참고**: 이 기능은 Google Calendar API를 사용하며, Google의 서비스 약관을 준수해야 합니다.
