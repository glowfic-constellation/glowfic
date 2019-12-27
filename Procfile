web: env RACK_TIMEOUT_TERM_ON_TIMEOUT=1 STATEMENT_TIMEOUT=10s bundle exec puma -C config/puma.rb
worker: env TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7 QUEUES=mailer,notifier,high,* bundle exec rake resque:work
