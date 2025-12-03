# iOS 개발자를 위한 `has_ever_subscribed` 필드 안내

## 📋 변경 사항

`GET /me/subscription` API 응답에 새로운 필드가 추가되었습니다:

```json
{
  "type": "none",
  "is_subscribed": false,
  "is_trial": false,
  "is_expired": true,
  "has_used_trial": true,
  "has_ever_subscribed": true,  // ← 새로 추가된 필드
  "subscription_expires_at": null,
  "trial_expires_at": null,
  "days_left": 0
}
```

## ✅ iOS 코드 변경 없이도 작동합니다

이 필드는 **선택적(optional)** 필드이므로:
- 기존 iOS 코드는 그대로 작동합니다
- 파싱하지 않아도 에러가 발생하지 않습니다
- 기존 `SubscriptionResponse` 모델에 필드를 추가하지 않아도 됩니다

## 🎯 필드 설명

### `has_ever_subscribed` (boolean)

**의미**: 한번이라도 구독한 경험이 있는지 여부

**특징**:
- `true`: 과거에 한번이라도 구독한 적이 있음
- `false`: 한번도 구독한 적이 없음
- 구독 해지 후에도 `true`로 유지됨
- 구독 만료 후에도 `true`로 유지됨

**사용 예시**:
```swift
// 예: 재가입 유도 메시지 표시
if !user.is_subscribed && user.has_ever_subscribed {
    // "다시 구독하시겠어요?" 메시지 표시
}
```

## 📝 나중에 사용하려면 (선택사항)

iOS 모델에 필드를 추가하려면:

```swift
struct SubscriptionResponse: Codable {
    let type: SubscriptionType
    let isSubscribed: Bool
    let isTrial: Bool
    let isExpired: Bool
    let hasUsedTrial: Bool
    let hasEverSubscribed: Bool?  // ← 추가 (optional로 선언 가능)
    let subscriptionExpiresAt: String?
    let trialExpiresAt: String?
    let daysLeft: Int
    
    enum CodingKeys: String, CodingKey {
        case type
        case isSubscribed = "is_subscribed"
        case isTrial = "is_trial"
        case isExpired = "is_expired"
        case hasUsedTrial = "has_used_trial"
        case hasEverSubscribed = "has_ever_subscribed"  // ← 추가
        case subscriptionExpiresAt = "subscription_expires_at"
        case trialExpiresAt = "trial_expires_at"
        case daysLeft = "days_left"
    }
}
```

## 🔄 동작 방식

1. **신규 유저**: `has_ever_subscribed = false`
2. **구독 활성화 시**: `has_ever_subscribed = true`로 자동 설정
3. **구독 해지 후**: `has_ever_subscribed = true` 유지 (변경 없음)
4. **구독 만료 후**: `has_ever_subscribed = true` 유지 (변경 없음)

## 💡 활용 예시

### 1. 재가입 유도
```swift
if !subscription.isSubscribed && subscription.hasEverSubscribed == true {
    showReSubscribeMessage()
}
```

### 2. 통계/분석
```swift
// 한번도 구독하지 않은 유저에게만 특별 프로모션 표시
if subscription.hasEverSubscribed == false {
    showFirstTimePromotion()
}
```

### 3. UI 분기
```swift
// 구독 경험이 있는 유저와 없는 유저에게 다른 UI 표시
let message = subscription.hasEverSubscribed == true 
    ? "다시 구독하시겠어요?" 
    : "지금 구독하고 시작하세요!"
```

## ⚠️ 주의사항

- 이 필드는 **선택적(optional)** 필드입니다
- 기존 코드는 수정 없이 그대로 작동합니다
- 필요할 때만 모델에 추가하면 됩니다
- `nil` 체크를 권장합니다 (optional로 선언 시)

