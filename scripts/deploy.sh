#!/bin/bash
# Rails 프로덕션 서버 배포 스크립트
#
# 사용법:
#   ./scripts/deploy.sh
#
# 이 스크립트는 다음을 수행합니다:
# 1. Git에서 최신 코드 가져오기
# 2. 의존성 설치
# 3. 데이터베이스 마이그레이션
# 4. 애셋 컴파일 (필요시)
# 5. Puma 재시작

set -e  # 에러 발생 시 스크립트 중단

echo "🚀 배포 시작..."

# 프로젝트 디렉토리로 이동
cd "$(dirname "$0")/.." || exit 1

# Git에서 최신 코드 가져오기
echo "📥 Git에서 최신 코드 가져오기..."
git pull origin main

# 의존성 설치
echo "📦 의존성 설치..."
bundle install --deployment --without development test

# 데이터베이스 마이그레이션
echo "🗄️  데이터베이스 마이그레이션..."
RAILS_ENV=production bundle exec rails db:migrate

# 애셋 컴파일 (필요시)
# echo "🎨 애셋 컴파일..."
# RAILS_ENV=production bundle exec rails assets:precompile

# Puma 재시작
echo "🔄 Puma 재시작..."
if systemctl is-active --quiet puma; then
  echo "   systemd를 통해 Puma 재시작..."
  sudo systemctl restart puma
elif [ -f tmp/pids/server.pid ]; then
  echo "   PID 파일을 통해 Puma 재시작..."
  kill -USR2 "$(cat tmp/pids/server.pid)"
else
  echo "   ⚠️  Puma 프로세스를 찾을 수 없습니다. 수동으로 재시작하세요."
  echo "   systemd 사용: sudo systemctl restart puma"
  echo "   또는: bundle exec pumactl restart"
fi

echo "✅ 배포 완료!"
echo ""
echo "서버 상태 확인:"
echo "  - Health check: curl http://localhost:3000/up"
echo "  - Puma 상태: sudo systemctl status puma"

