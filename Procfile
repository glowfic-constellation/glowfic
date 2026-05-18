web: env MALLOC_ARENA_MAX=2 JEMALLOC_ENABLED=true STATEMENT_TIMEOUT=10s bundle exec puma -C config/puma.rb
worker: env MALLOC_ARENA_MAX=2 JEMALLOC_ENABLED=true TERM_CHILD=1 RESQUE_PRE_SHUTDOWN_TIMEOUT=20 RESQUE_TERM_TIMEOUT=7 QUEUES=mailer,notifier,high,* bundle exec rake resque:work
