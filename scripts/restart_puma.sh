#!/bin/bash
# Puma 재시작 스크립트
#
# 사용법:
#   ./scripts/restart_puma.sh
#
# 여러 방법으로 Puma를 재시작하려고 시도합니다.

set -e

echo "🔄 Puma 재시작 시도..."

# 방법 1: systemd 사용 (권장)
if systemctl is-active --quiet puma 2>/dev/null; then
  echo "✅ systemd를 통해 Puma 재시작..."
  sudo systemctl restart puma
  sleep 2
  if systemctl is-active --quiet puma; then
    echo "✅ Puma가 성공적으로 재시작되었습니다."
    exit 0
  else
    echo "❌ Puma 재시작 실패"
    exit 1
  fi
fi

# 방법 2: PID 파일을 통한 재시작
if [ -f tmp/pids/server.pid ]; then
  PID=$(cat tmp/pids/server.pid)
  if kill -0 "$PID" 2>/dev/null; then
    echo "✅ PID 파일을 통해 Puma 재시작..."
    kill -USR2 "$PID"
    sleep 2
    echo "✅ Puma 재시작 신호 전송 완료"
    exit 0
  fi
fi

# 방법 3: pumactl 사용
if command -v pumactl &> /dev/null; then
  echo "✅ pumactl을 통해 Puma 재시작 시도..."
  cd "$(dirname "$0")/.." || exit 1
  RAILS_ENV=production bundle exec pumactl restart
  exit 0
fi

echo "❌ Puma 프로세스를 찾을 수 없습니다."
echo ""
echo "수동 재시작 방법:"
echo "  1. systemd: sudo systemctl restart puma"
echo "  2. 직접 실행: cd /path/to/app && RAILS_ENV=production bundle exec puma -C config/puma.rb"
echo ""
exit 1

