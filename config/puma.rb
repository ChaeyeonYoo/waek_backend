# Puma 설정 파일
# 
# 프로덕션 환경에서 Puma를 systemd로 실행하는 경우 이 파일을 사용합니다.
#
# systemd 서비스 파일 예제:
#   /etc/systemd/system/puma.service
#
# [Unit]
# Description=Puma HTTP Server
# After=network.target
#
# [Service]
# Type=simple
# User=your-user
# WorkingDirectory=/path/to/waek_backend
# Environment="RAILS_ENV=production"
# EnvironmentFile=/path/to/waek_backend/.env
# ExecStart=/usr/local/bin/bundle exec puma -C config/puma.rb
# Restart=always
#
# [Install]
# WantedBy=multi-user.target

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "production"

port ENV.fetch("PORT") { 3000 }

environment ENV.fetch("RAILS_ENV") { "development" }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

workers ENV.fetch("WEB_CONCURRENCY") { 2 }

preload_app!

plugin :tmp_restart
