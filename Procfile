web: bundle exec puma -C config/puma.rb
worker: env TERM_CHILD=1 RESQUE_TERM_TIMEOUT=7 QUEUES=mailer,high,* bundle exec rake resque:work
