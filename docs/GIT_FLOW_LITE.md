# Light Git-Flow (for small projects)

목표: 히스토리는 단순하게, 배포 이력은 명확하게.

## 브랜치 구조
- main: 항상 안정 상태. 배포/사용 기준 브랜치. 태그(vX.Y.Z)만 기록
- feature/*: 기능/버그 단위 작업 브랜치 (from main → into main)
- hotfix/*: 긴급 수정 브랜치 (from main → into main)
- release/*: 필요 시(선택) QA용 임시 릴리스 브랜치

기본은 main + feature/* (+ hotfix/*) 조합만 사용합니다.

## 작업 흐름
### 기능 개발
```bash
# 1) 기능 브랜치 생성
git checkout -b feature/<slug> main

# 2) 작업 및 커밋
# ...

# 3) main으로 스쿼시 병합(히스토리 단순화)
git checkout main
git merge --squash feature/<slug>
git commit -m "feat: <요약>"

# 4) 태그 생성(선택) — 배포 이력만 남길 때 사용
git tag -a vX.Y.Z -m "Release vX.Y.Z"

# 5) 정리
git branch -d feature/<slug>
```

### 핫픽스
```bash
git checkout -b hotfix/<slug> main
# 수정 후 커밋

git checkout main
git merge --squash hotfix/<slug>
git commit -m "fix: <요약>"
# (선택) 태그
# git tag -a vX.Y.Z+1 -m "Hotfix vX.Y.Z+1"

git branch -d hotfix/<slug>
```

### 선택적 릴리스 브랜치(필요할 때만)
```bash
git checkout -b release/X.Y.Z main
# QA/버그 수정 후

git checkout main && git merge --squash release/X.Y.Z && git commit -m "chore(release): vX.Y.Z"
git branch -d release/X.Y.Z
```

## PR 규칙(권장)
- 대상 브랜치: main
- 머지 전략: Squash merge
- 체크리스트(간단)
  - [ ] 빌드/실행 확인(Prod/Dev 스킴)
  - [ ] 핵심 경로 수동 테스트(타이머 시작/일시정지/리셋, 투두 CRUD, 카드 CRUD/복습)
  - [ ] Core Data 마이그레이션 영향 없음 또는 마이그레이션 검증 완료
  - [ ] 릴리스 노트 한 줄 요약(PR 본문에)

## 태그/릴리스
- Apple Developer/서명 토큰이 없어 DMG/노타라이즈 자동화는 제외합니다
- 태그는 선택적으로 main 병합 직후 수동으로 만듭니다
  - 예: `git tag -a v1.0.1 -m "Release 1.0.1" && git push --tags`

## 커밋/브랜치 네이밍 예시
- 브랜치: `feature/i18n-live-switch`, `feature/timer-pause-fix`, `hotfix/crash-dict-dup`
- 커밋 타입: `feat, fix, chore, docs, refactor` 등
  - 예) `fix(timer): pause persists elapsed seconds`

## 버전/설정 변경(수동)
- Info.plist Marketing/Build Version 수동 업데이트(배포 전)
- 스킴/번들 식별자 점검(Prod/Dev)

## 브랜치 보호(작게 시작)
- main: 직접 푸시 금지(가능하면 PR만), squash merge만 허용
- CI가 없다면 최소 자기검토(Self-review) + 체크리스트로 대체


