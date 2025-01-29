web: env STATEMENT_TIMEOUT=10s bundle exec puma -C config/puma.rb
worker: env RAILS_LOG_LEVEL=debug TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7 QUEUES=mailer,notifier,high,* bundle exec rake resque:work
