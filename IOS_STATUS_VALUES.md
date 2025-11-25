# iOS 개발자를 위한 Status 및 Enum 값 정리

## 1. 인증 API Response Status

### POST /auth/social/verify
응답의 `status` 필드:
- `"EXISTS"` - 기존 유저 (로그인 성공)
- `"NEED_SIGNUP"` - 신규 유저 (회원가입 필요)

```swift
enum SocialVerifyStatus: String, Codable {
    case exists = "EXISTS"
    case needSignup = "NEED_SIGNUP"
}
```

---

## 2. Walk (산책 기록) Status

### Walk.status (DB 필드)
- `"active"` - 활성 상태 (정상적인 기록)
- `"deleted"` - 삭제됨 (soft delete)

```swift
enum WalkStatus: String, Codable {
    case active = "active"
    case deleted = "deleted"
}
```

**참고**: 
- GET /walks API는 `status: "active"`인 기록만 반환합니다
- DELETE /walks/:id는 `status: "deleted"`로 변경합니다 (실제 삭제 아님)

---

## 3. Subscription Type

### GET /me/subscription
응답의 `type` 필드:
- `"paid"` - 유료 구독 중
- `"trial"` - 무료체험 중
- `"none"` - 비구독 상태

```swift
enum SubscriptionType: String, Codable {
    case paid = "paid"
    case trial = "trial"
    case none = "none"
}
```

---

## 4. Subscription Action Status

### POST /me/subscription
응답의 `status` 필드:
- `"subscribed"` - 구독 활성화 성공

```swift
// 응답 예시
{
  "status": "subscribed",
  "subscription_expires_at": "2025-12-23T04:34:15Z"
}
```

### DELETE /me/subscription
응답의 `status` 필드:
- `"cancelled"` - 구독 해지 성공

```swift
// 응답 예시
{
  "status": "cancelled",
  "expires_at": "2025-12-23T04:34:15Z"
}
```

---

## 5. Provider (소셜 로그인 제공자)

모든 인증 API에서 사용:
- `"kakao"` - 카카오
- `"google"` - 구글
- `"apple"` - 애플

```swift
enum Provider: String, Codable {
    case kakao = "kakao"
    case google = "google"
    case apple = "apple"
}
```

---

## 6. Device Type (피드백)

### POST /feedbacks
요청의 `device_type` 필드:
- `"ios"` - iOS
- `"android"` - Android
- `"web"` - Web

```swift
enum DeviceType: String, Codable {
    case ios = "ios"
    case android = "android"
    case web = "web"
}
```

---

## 7. Profile Image Code

유저 프로필 이미지:
- `0`, `1`, `2`, `3`, `4` (총 5개)

```swift
enum ProfileImageCode: Int, Codable {
    case image0 = 0
    case image1 = 1
    case image2 = 2
    case image3 = 3
    case image4 = 4
}
```

**유효성 검사**: 0~4 범위를 벗어나면 400 에러

---

## 8. HTTP Status Codes

### 성공
- `200 OK` - 조회 성공
- `201 Created` - 생성 성공
- `204 No Content` - 삭제/업데이트 성공 (응답 body 없음)

### 클라이언트 에러
- `400 Bad Request` - 필수 파라미터 누락 또는 잘못된 값
- `401 Unauthorized` - 인증 실패 (토큰 없음/유효하지 않음/만료됨)
- `404 Not Found` - 리소스를 찾을 수 없음
- `409 Conflict` - 중복 (username, provider_id 등)
- `422 Unprocessable Entity` - 유효성 검사 실패

### 서버 에러
- `500 Internal Server Error` - 서버 오류

---

## 9. 에러 응답 형식

### 단일 에러
```json
{
  "error": "에러 메시지"
}
```

```swift
struct ErrorResponse: Codable {
    let error: String
}
```

### 복수 에러 (유효성 검사 실패)
```json
{
  "error": "회원가입에 실패했습니다",
  "errors": [
    "Nickname can't be blank",
    "Username has already been taken"
  ]
}
```

```swift
struct ValidationErrorResponse: Codable {
    let error: String
    let errors: [String]
}
```

---

## 10. Token Type

### 모든 인증 응답
```json
{
  "token": {
    "access_token": "eyJhbGc...",
    "token_type": "Bearer",
    "expires_in": 3600
  }
}
```

- `token_type`: 항상 `"Bearer"`
- `expires_in`: 항상 `3600` (초, 1시간)
  - 실제로는 영구 토큰이지만, iOS 표준을 위해 3600 반환

```swift
struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String  // 항상 "Bearer"
    let expiresIn: Int     // 항상 3600
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}
```

---

## 요약

### 주요 Status 값
```swift
// 인증
"EXISTS", "NEED_SIGNUP"

// Walk
"active", "deleted"

// Subscription Action
"subscribed", "cancelled"

// Subscription Type
"paid", "trial", "none"

// Provider
"kakao", "google", "apple"

// Device Type
"ios", "android", "web"
```

모든 status 값은 **소문자** 또는 **대문자**로 일관되게 사용됩니다.





