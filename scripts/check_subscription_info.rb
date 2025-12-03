#!/usr/bin/env ruby
# 구독 정보 조회 스크립트
# 사용법: rails runner scripts/check_subscription_info.rb [username 또는 user_id]

require_relative '../config/environment'

def print_user_subscription_info(user)
  puts "\n" + "="*60
  puts "유저 정보: #{user.username} (#{user.nickname})"
  puts "="*60
  puts "ID: #{user.id}"
  puts "Provider: #{user.provider}"
  puts ""
  puts "--- 구독 정보 ---"
  puts "현재 구독 중: #{user.is_subscribed ? '✅ 예' : '❌ 아니오'}"
  puts "한번 구독한 경험: #{user.has_ever_subscribed ? '✅ 예' : '❌ 아니오'}"
  puts "무료체험 사용: #{user.has_used_trial ? '✅ 예' : '❌ 아니오'}"
  puts "무료체험 중: #{user.is_trial ? '✅ 예' : '❌ 아니오'}"
  puts "구독 타입: #{user.subscription_type}"
  puts "만료 여부: #{user.is_expired? ? '⚠️ 만료됨' : '✅ 활성'}"
  puts ""
  puts "--- 날짜 정보 ---"
  puts "구독 시작일: #{user.subscribed_at ? user.subscribed_at.strftime('%Y-%m-%d %H:%M:%S %Z') : '없음'}"
  puts "구독 만료일: #{user.subscription_expires_at ? user.subscription_expires_at.strftime('%Y-%m-%d %H:%M:%S %Z') : '없음'}"
  puts "무료체험 시작일: #{user.trial_started_at ? user.trial_started_at.strftime('%Y-%m-%d %H:%M:%S %Z') : '없음'}"
  puts "무료체험 만료일: #{user.trial_expires_at ? user.trial_expires_at.strftime('%Y-%m-%d %H:%M:%S %Z') : '없음'}"
  puts "남은 일수: #{user.days_left}일"
  puts ""
  puts "--- 통계 ---"
  puts "생성일: #{user.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
  puts "최종 로그인: #{user.last_login_at ? user.last_login_at.strftime('%Y-%m-%d %H:%M:%S %Z') : '없음'}"
  puts "="*60
end

# 명령줄 인자로 username 또는 user_id 받기
identifier = ARGV[0]

if identifier.nil?
  # 인자가 없으면 전체 통계 출력
  puts "\n" + "="*60
  puts "전체 구독 통계"
  puts "="*60
  
  total_users = User.active.count
  subscribed_count = User.where(is_subscribed: true).count
  ever_subscribed_count = User.where(has_ever_subscribed: true).count
  active_subscriptions = User.where("is_subscribed = true AND subscription_expires_at > ?", Time.current).count
  expired_subscriptions = User.where("is_subscribed = true AND subscription_expires_at < ?", Time.current).count
  trial_count = User.where(is_trial: true).count
  used_trial_count = User.where(has_used_trial: true).count
  
  puts "전체 활성 유저: #{total_users}명"
  puts "현재 구독 중: #{subscribed_count}명"
  puts "한번 구독한 경험: #{ever_subscribed_count}명"
  puts "활성 구독자: #{active_subscriptions}명"
  puts "만료된 구독자: #{expired_subscriptions}명"
  puts "무료체험 중: #{trial_count}명"
  puts "무료체험 사용 경험: #{used_trial_count}명"
  puts ""
  puts "--- 최근 구독 활성화된 유저 (최대 10명) ---"
  User.where(is_subscribed: true)
      .order(subscribed_at: :desc)
      .limit(10)
      .each do |user|
    puts "  #{user.username} (#{user.nickname}) - #{user.subscribed_at.strftime('%Y-%m-%d %H:%M:%S')} - 남은 일수: #{user.days_left}일"
  end
  puts ""
  puts "--- 한번 구독했지만 현재 해지된 유저 (최대 10명) ---"
  User.where("has_ever_subscribed = true AND is_subscribed = false")
      .order(subscribed_at: :desc)
      .limit(10)
      .each do |user|
    puts "  #{user.username} (#{user.nickname}) - 마지막 구독: #{user.subscribed_at ? user.subscribed_at.strftime('%Y-%m-%d %H:%M:%S') : '없음'}"
  end
  puts "="*60
else
  # username 또는 user_id로 유저 찾기
  user = if identifier.match?(/^\d+$/)
    # 숫자면 user_id로 검색
    User.find_by(id: identifier.to_i)
  else
    # 문자열이면 username으로 검색
    User.active.find_by(username: identifier)
  end
  
  if user.nil?
    puts "❌ 유저를 찾을 수 없습니다: #{identifier}"
    puts ""
    puts "사용법:"
    puts "  rails runner scripts/check_subscription_info.rb [username 또는 user_id]"
    puts ""
    puts "예시:"
    puts "  rails runner scripts/check_subscription_info.rb waek_chae"
    puts "  rails runner scripts/check_subscription_info.rb 1"
    exit 1
  end
  
  print_user_subscription_info(user)
end

