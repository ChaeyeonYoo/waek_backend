# DBeaver 실시간 데이터 반영 가이드

## 문제
DBeaver에서 구독자 정보 등 데이터 변경이 실시간으로 반영되지 않는 경우

## 해결 방법

### 1. DBeaver Auto-commit 설정 확인

1. **DBeaver 연결 설정 확인**
   - DBeaver에서 PostgreSQL 연결을 우클릭 → **Edit Connection**
   - **Connection settings** 탭에서 확인
   - **Auto-commit** 옵션이 **체크되어 있는지** 확인

2. **트랜잭션 모드 확인**
   - DBeaver 하단 상태바에서 **Auto-commit** 모드인지 확인
   - 수동 커밋 모드라면 **Auto-commit** 버튼 클릭

### 2. 수동 새로고침

- **F5** 키를 눌러 테이블 데이터 새로고침
- 또는 테이블을 우클릭 → **Refresh** → **Refresh**

### 3. Rails 콘솔에서 직접 확인 (권장)

터미널에서 Rails 콘솔을 열어 실시간으로 확인:

```bash
rails console
```

콘솔에서:

```ruby
# 특정 유저의 구독 정보 확인
user = User.find(1)  # 또는 User.find_by(username: "waek_chae")
user.is_subscribed
user.subscription_expires_at
user.days_left

# 구독 상태 조회
user.subscription_type
user.is_expired

# 모든 구독자 목록
User.where(is_subscribed: true)

# 최근 구독 활성화된 유저
User.where(is_subscribed: true).order(subscribed_at: :desc).limit(10)
```

### 4. DBeaver 트랜잭션 격리 수준 확인

1. **SQL Editor** 열기
2. 다음 쿼리 실행:

```sql
-- 현재 트랜잭션 격리 수준 확인
SHOW transaction_isolation;

-- Auto-commit 상태 확인
SHOW autocommit;
```

3. 필요시 Auto-commit 활성화:

```sql
SET autocommit = ON;
```

### 5. DBeaver 새로고침 자동화 설정

1. **Window** → **Preferences** (또는 **DBeaver** → **Preferences** on Mac)
2. **Database** → **Data Editor** → **Refresh**
3. **Auto-refresh interval** 설정 (예: 5초)

### 6. API를 통한 실시간 확인

Rails 서버가 실행 중이라면 API로 직접 확인:

```bash
# 구독 상태 조회 API 호출
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/me/subscription
```

## 빠른 확인 스크립트

Rails 콘솔에서 사용할 수 있는 헬퍼 메서드:

```ruby
# app/models/user.rb에 추가할 수 있는 메서드
def self.subscription_stats
  {
    total_subscribed: where(is_subscribed: true).count,
    total_trial: where(is_trial: true).count,
    expired_count: where("subscription_expires_at < ?", Time.current).count,
    active_subscriptions: where("is_subscribed = true AND subscription_expires_at > ?", Time.current).count
  }
end

# 사용법
User.subscription_stats
```

## 주의사항

- DBeaver는 기본적으로 **읽기 전용** 연결을 사용할 수 있습니다
- 트랜잭션이 롤백되면 변경사항이 보이지 않습니다
- Rails는 각 쿼리마다 auto-commit하므로, DBeaver에서도 실시간으로 보여야 합니다
- 만약 계속 문제가 있다면, DBeaver 연결을 재시작하거나 Rails 서버를 재시작해보세요

