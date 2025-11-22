# 왹왹이(waek) API 명세서

**Base URL**: http://3.37.73.46:3000 (Elastic IP + 3000 포트)
**API 버전**: v1  
**인증 방식**: JWT Bearer Token

---

## 목차

1. [인증](#인증)
2. [산책 기록](#산책-기록)
3. [일일 요약](#일일-요약)
4. [카드](#카드)
5. [피드백](#피드백)
6. [에러 처리](#에러-처리)

---

## 인증

### 소셜 로그인

소셜 로그인을 통해 JWT 토큰을 발급받습니다.

**엔드포인트**: `POST /auth/social_login`  
**인증 필요**: ❌ 없음

#### Request Body

```json
{
  "provider": 1,
  "provider_user_id": "apple_user_12345",
  "nickname": "홍길동",
  "social_email": "user@example.com",
  "profile_image_key": 1
}
```

#### 파라미터 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `provider` | integer | ✅ | 소셜 로그인 제공자: 1 (Apple), 2 (Kakao), 3 (Google) |
| `provider_user_id` | string | ✅ | 소셜 로그인 제공자에서 받은 유저 고유 ID |
| `nickname` | string | ✅ | 사용자 닉네임 |
| `social_email` | string | ❌ | 소셜 로그인 이메일 |
| `profile_image_key` | integer | ❌ | 프로필 이미지 키 (미리 제공된 사진 번호) |

#### Response (200 OK)

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3MzQzMjE2MDB9.xxx",
  "user": {
    "id": 1,
    "nickname": "홍길동",
    "profile_image_key": 1,
    "provider": 1,
    "is_premium": false
  }
}
```

#### Response (400 Bad Request)

```json
{
  "error": "필수 파라미터가 없습니다 (provider, provider_user_id, nickname)"
}
```

#### Response (422 Unprocessable Entity)

```json
{
  "errors": ["Provider user id has already been taken"]
}
```

#### 사용 예시

```bash
curl -X POST http://localhost:3000/auth/social_login \
  -H "Content-Type: application/json" \
  -d '{
    "provider": 1,
    "provider_user_id": "apple_user_12345",
    "nickname": "홍길동",
    "social_email": "user@example.com",
    "profile_image_key": 1
  }'
```

---

## 산책 기록

### 산책 기록 저장

새로운 산책 세션을 저장합니다.

**엔드포인트**: `POST /workouts`  
**인증 필요**: ✅ (Authorization 헤더 필요)

#### Request Headers

```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

#### Request Body

```json
{
  "workout": {
    "workout_date": "2024-11-15",
    "started_at": "2024-11-15T10:00:00Z",
    "ended_at": "2024-11-15T10:30:00Z",
    "distance": 2500.5,
    "steps": 3500,
    "duration": 1800,
    "calories": 120.5
  }
}
```

#### 파라미터 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `workout_date` | date | ✅ | 산책 날짜 (YYYY-MM-DD) |
| `started_at` | datetime | ✅ | 시작 시간 (ISO 8601) |
| `ended_at` | datetime | ✅ | 종료 시간 (ISO 8601) |
| `distance` | decimal | ❌ | 거리 (미터 단위) |
| `steps` | integer | ❌ | 걸음수 |
| `duration` | integer | ✅ | 지속 시간 (초 단위) |
| `calories` | decimal | ❌ | 소모 칼로리 |

#### Response (201 Created)

```json
{
  "id": 1,
  "user_id": 1,
  "workout_date": "2024-11-15",
  "started_at": "2024-11-15T10:00:00.000Z",
  "ended_at": "2024-11-15T10:30:00.000Z",
  "distance": "2500.5",
  "steps": 3500,
  "duration": 1800,
  "calories": "120.5",
  "created_at": "2024-11-15T10:30:00.000Z",
  "updated_at": "2024-11-15T10:30:00.000Z"
}
```

#### Response (401 Unauthorized)

```json
{
  "error": "인증이 필요합니다"
}
```

#### Response (422 Unprocessable Entity)

```json
{
  "errors": [
    "Workout date can't be blank",
    "Ended at 종료 시간은 시작 시간보다 이후여야 합니다"
  ]
}
```

#### 사용 예시

```bash
curl -X POST http://localhost:3000/workouts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "workout": {
      "workout_date": "2024-11-15",
      "started_at": "2024-11-15T10:00:00Z",
      "ended_at": "2024-11-15T10:30:00Z",
      "distance": 2500.5,
      "steps": 3500,
      "duration": 1800,
      "calories": 120.5
    }
  }'
```

---

### 산책 기록 조회

저장된 산책 기록을 조회합니다.

**엔드포인트**: `GET /workouts`  
**인증 필요**: ✅

#### Request Headers

```
Authorization: Bearer <JWT_TOKEN>
```

#### Query Parameters

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `date` | date | ❌ | 특정 날짜의 기록만 조회 (YYYY-MM-DD). 없으면 모든 기록 조회 |

#### Response (200 OK)

```json
[
  {
    "id": 1,
    "user_id": 1,
    "workout_date": "2024-11-15",
    "started_at": "2024-11-15T10:00:00.000Z",
    "ended_at": "2024-11-15T10:30:00.000Z",
    "distance": "2500.5",
    "steps": 3500,
    "duration": 1800,
    "calories": "120.5",
    "created_at": "2024-11-15T10:30:00.000Z",
    "updated_at": "2024-11-15T10:30:00.000Z"
  },
  {
    "id": 2,
    "user_id": 1,
    "workout_date": "2024-11-14",
    "started_at": "2024-11-14T14:00:00.000Z",
    "ended_at": "2024-11-14T14:25:00.000Z",
    "distance": "1800.0",
    "steps": 2500,
    "duration": 1500,
    "calories": null,
    "created_at": "2024-11-14T14:25:00.000Z",
    "updated_at": "2024-11-14T14:25:00.000Z"
  }
]
```

#### 사용 예시

```bash
# 모든 기록 조회
curl -X GET http://localhost:3000/workouts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 특정 날짜 기록 조회
curl -X GET "http://localhost:3000/workouts?date=2024-11-15" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 일일 요약

### 특정 날짜의 일일 요약 조회

특정 날짜의 일일 요약 정보를 조회합니다.

**엔드포인트**: `GET /daily_workouts/:date`  
**인증 필요**: ✅

#### Request Headers

```
Authorization: Bearer <JWT_TOKEN>
```

#### Path Parameters

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `date` | date | ✅ | 조회할 날짜 (YYYY-MM-DD) |

#### Response (200 OK)

```json
{
  "id": 1,
  "user_id": 1,
  "date": "2024-11-15",
  "is_workout_goal_achieved": true,
  "has_walk_10min": true,
  "created_at": "2024-11-15T00:00:00.000Z",
  "updated_at": "2024-11-15T23:59:59.000Z"
}
```

**참고**: 해당 날짜의 데이터가 없으면 기본값(`is_workout_goal_achieved: false`, `has_walk_10min: false`)으로 새 객체를 생성해서 반환합니다. (저장하지 않음)

#### Response (400 Bad Request)

```json
{
  "error": "날짜가 필요합니다"
}
```

#### 사용 예시

```bash
curl -X GET http://localhost:3000/daily_workouts/2024-11-15 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 일일 요약 목록 조회

날짜 범위의 일일 요약 목록을 조회합니다.

**엔드포인트**: `GET /daily_workouts`  
**인증 필요**: ✅

#### Request Headers

```
Authorization: Bearer <JWT_TOKEN>
```

#### Query Parameters

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `start_date` | date | ❌ | 시작 날짜 (YYYY-MM-DD) |
| `end_date` | date | ❌ | 종료 날짜 (YYYY-MM-DD) |

**참고**: `start_date`와 `end_date`를 모두 제공하면 해당 범위의 데이터만 조회합니다. 둘 다 없으면 모든 데이터를 조회합니다.

#### Response (200 OK)

```json
[
  {
    "id": 1,
    "user_id": 1,
    "date": "2024-11-15",
    "is_workout_goal_achieved": true,
    "has_walk_10min": true,
    "created_at": "2024-11-15T00:00:00.000Z",
    "updated_at": "2024-11-15T23:59:59.000Z"
  },
  {
    "id": 2,
    "user_id": 1,
    "date": "2024-11-14",
    "is_workout_goal_achieved": false,
    "has_walk_10min": true,
    "created_at": "2024-11-14T00:00:00.000Z",
    "updated_at": "2024-11-14T23:59:59.000Z"
  }
]
```

#### 사용 예시

```bash
# 모든 일일 요약 조회
curl -X GET http://localhost:3000/daily_workouts \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 날짜 범위로 조회
curl -X GET "http://localhost:3000/daily_workouts?start_date=2024-11-01&end_date=2024-11-30" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 카드

### 카드 저장

산책 결과를 공유할 수 있는 카드를 저장합니다.

**엔드포인트**: `POST /share_cards`  
**인증 필요**: ✅

#### Request Headers

```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

#### Request Body

```json
{
  "share_card": {
    "workout_id": 1,
    "card_date": "2024-11-15",
    "frame_theme_key": "theme_1",
    "image_url": "https://example.com/cards/card_123.jpg",
    "distance": 2500.5,
    "steps": 3500,
    "duration": 1800
  }
}
```

#### 파라미터 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `workout_id` | integer | ✅ | 연결된 Workout ID |
| `card_date` | date | ✅ | 카드에 표시되는 날짜 (YYYY-MM-DD) |
| `frame_theme_key` | string | ❌ | 프레임/테마 키 |
| `image_url` | string | ❌ | 완성된 카드 이미지 URL |
| `distance` | decimal | ❌ | 거리 (미터, Workout에서 복사한 스냅샷) |
| `steps` | integer | ❌ | 걸음수 (Workout에서 복사한 스냅샷) |
| `duration` | integer | ❌ | 지속 시간 (초, Workout에서 복사한 스냅샷) |

#### Response (201 Created)

```json
{
  "id": 1,
  "user_id": 1,
  "workout_id": 1,
  "card_date": "2024-11-15",
  "frame_theme_key": "theme_1",
  "image_url": "https://example.com/cards/card_123.jpg",
  "distance": "2500.5",
  "steps": 3500,
  "duration": 1800,
  "created_at": "2024-11-15T10:35:00.000Z",
  "updated_at": "2024-11-15T10:35:00.000Z"
}
```

#### 사용 예시

```bash
curl -X POST http://localhost:3000/share_cards \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "share_card": {
      "workout_id": 1,
      "card_date": "2024-11-15",
      "frame_theme_key": "theme_1",
      "image_url": "https://example.com/cards/card_123.jpg",
      "distance": 2500.5,
      "steps": 3500,
      "duration": 1800
    }
  }'
```

---

### 카드 조회

저장된 카드를 조회합니다.

**엔드포인트**: `GET /share_cards`  
**인증 필요**: ✅

#### Request Headers

```
Authorization: Bearer <JWT_TOKEN>
```

#### Query Parameters

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `date` | date | ❌ | 특정 날짜의 카드만 조회 (YYYY-MM-DD). 없으면 모든 카드 조회 |

#### Response (200 OK)

```json
[
  {
    "id": 1,
    "user_id": 1,
    "workout_id": 1,
    "card_date": "2024-11-15",
    "frame_theme_key": "theme_1",
    "image_url": "https://example.com/cards/card_123.jpg",
    "distance": "2500.5",
    "steps": 3500,
    "duration": 1800,
    "created_at": "2024-11-15T10:35:00.000Z",
    "updated_at": "2024-11-15T10:35:00.000Z"
  }
]
```

#### 사용 예시

```bash
# 모든 카드 조회
curl -X GET http://localhost:3000/share_cards \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 특정 날짜 카드 조회
curl -X GET "http://localhost:3000/share_cards?date=2024-11-15" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 피드백

### 피드백 저장

사용자 피드백을 저장합니다.

**엔드포인트**: `POST /feedbacks`  
**인증 필요**: ✅

#### Request Headers

```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

#### Request Body

```json
{
  "feedback": {
    "content": "앱이 정말 좋아요! 계속 사용하고 싶습니다.",
    "app_version": "1.0.0",
    "platform": "ios"
  }
}
```

#### 파라미터 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `content` | string | ✅ | 피드백 내용 |
| `app_version` | string | ❌ | 앱 버전 |
| `platform` | string | ✅ | 플랫폼 (예: "ios") |

#### Response (201 Created)

```json
{
  "id": 1,
  "user_id": 1,
  "content": "앱이 정말 좋아요! 계속 사용하고 싶습니다.",
  "app_version": "1.0.0",
  "platform": "ios",
  "created_at": "2024-11-15T11:00:00.000Z",
  "updated_at": "2024-11-15T11:00:00.000Z"
}
```

#### Response (422 Unprocessable Entity)

```json
{
  "errors": [
    "Content can't be blank",
    "Platform can't be blank"
  ]
}
```

#### 사용 예시

```bash
curl -X POST http://localhost:3000/feedbacks \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "feedback": {
      "content": "앱이 정말 좋아요! 계속 사용하고 싶습니다.",
      "app_version": "1.0.0",
      "platform": "ios"
    }
  }'
```

---

## 에러 처리

### 에러 응답 형식

모든 에러는 JSON 형식으로 반환됩니다.

#### 400 Bad Request

잘못된 요청 파라미터

```json
{
  "error": "필수 파라미터가 없습니다 (provider, provider_user_id, nickname)"
}
```

#### 401 Unauthorized

인증 실패

```json
{
  "error": "인증이 필요합니다"
}
```

#### 422 Unprocessable Entity

유효성 검사 실패

```json
{
  "errors": [
    "Workout date can't be blank",
    "Duration must be greater than 0"
  ]
}
```

#### 500 Internal Server Error

서버 오류

```json
{
  "error": "서버 오류가 발생했습니다",
  "message": "상세 에러 메시지"
}
```

---

## 인증 토큰 사용 방법

1. `POST /auth/social_login`으로 로그인하여 JWT 토큰 받기
2. 이후 모든 API 요청에 `Authorization` 헤더 포함:
   ```
   Authorization: Bearer <JWT_TOKEN>
   ```
3. 토큰 만료 시간: 30일
4. 토큰이 만료되면 다시 로그인 필요

---

## 데이터 타입 및 형식

- **날짜**: `YYYY-MM-DD` (예: "2024-11-15")
- **시간**: ISO 8601 형식 (예: "2024-11-15T10:00:00Z")
- **거리**: 미터 단위 (decimal)
- **시간**: 초 단위 (integer)
- **Provider**: 1 (Apple), 2 (Kakao), 3 (Google)

---

## Health Check

서버 상태 확인용 엔드포인트

**엔드포인트**: `GET /up`  
**인증 필요**: ❌ 없음

#### Response (200 OK)

서버가 정상 작동 중

#### Response (500 Internal Server Error)

서버 오류

---

**마지막 업데이트**: 2024-11-15

