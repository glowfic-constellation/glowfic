# frozen_string_literal: true
# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.
#
# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
# See "workers" below.
#
# You can control the number of workers using ENV["WEB_CONCURRENCY"]. You
# should only set this value when you want to run 2 or more workers. The
# default is already 1.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000), ENV.fetch("BIND_HOST", nil)

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV", "development")

# Specifies the number of `workers` to boot in clustered mode.
# We default to 2 to guarantee our fork hooks run.
workers ENV.fetch("WEB_CONCURRENCY", 2)

# Boot the Rails app once in the master process so worker forks share its
# memory pages via copy-on-write. The Linux kernel keeps unmodified pages
# shared between parent and child, so the full Rails framework footprint
# (gem code, parsed class trees, etc.) is paid for once per dyno instead
# of once per worker. Without this, each Puma worker independently loads
# Rails and runs ~270 MB resident, which is what pushes Standard-1X dynos
# into R14 at WEB_CONCURRENCY=2.
preload_app!

# Drop any connections the master may have opened (Redis namespace,
# ActiveRecord pool) before workers fork. Sharing a live socket between
# forked processes corrupts both ends; closing here forces each worker to
# reconnect lazily on first use.
before_fork do
  ActiveRecord::Base.connection_handler.clear_active_connections! if defined?(ActiveRecord::Base)
  $redis&.close
end

# Per-worker setup. Barnes reports GC / process stats from a background
# thread, which doesn't survive `fork`, so it has to start in each worker
# rather than in the master. Active Record reconnects automatically on
# first query in Rails 7+, so no explicit `establish_connection` is needed.
require 'barnes'
on_worker_boot do
  Barnes.start
end

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# https://www.heroku.com/blog/pumas-routers-keepalives-ohmy/#the-solution
enable_keep_alives false
