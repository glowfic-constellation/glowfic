# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `connection_pool` gem.
# Please instead update this file by running `bin/tapioca gem connection_pool`.

# Generic connection pool class for sharing a limited number of objects or network connections
# among many threads.  Note: pool elements are lazily created.
#
# Example usage with block (faster):
#
#    @pool = ConnectionPool.new { Redis.new }
#    @pool.with do |redis|
#      redis.lpop('my-list') if redis.llen('my-list') > 0
#    end
#
# Using optional timeout override (for that single invocation)
#
#    @pool.with(timeout: 2.0) do |redis|
#      redis.lpop('my-list') if redis.llen('my-list') > 0
#    end
#
# Example usage replacing an existing connection (slower):
#
#    $redis = ConnectionPool.wrap { Redis.new }
#
#    def do_work
#      $redis.lpop('my-list') if $redis.llen('my-list') > 0
#    end
#
# Accepts the following options:
# - :size - number of connections to pool, defaults to 5
# - :timeout - amount of time to wait for a connection if none currently available, defaults to 5 seconds
# - :auto_reload_after_fork - automatically drop all connections after fork, defaults to true
#
# source://connection_pool/lib/connection_pool/version.rb#1
class ConnectionPool
  # @raise [ArgumentError]
  # @return [ConnectionPool] a new instance of ConnectionPool
  #
  # source://connection_pool/lib/connection_pool.rb#90
  def initialize(options = T.unsafe(nil), &block); end

  # Automatically drop all connections after fork
  #
  # source://connection_pool/lib/connection_pool.rb#166
  def auto_reload_after_fork; end

  # Number of pool entries available for checkout at this instant.
  #
  # source://connection_pool/lib/connection_pool.rb#169
  def available; end

  # source://connection_pool/lib/connection_pool.rb#129
  def checkin(force: T.unsafe(nil)); end

  # source://connection_pool/lib/connection_pool.rb#119
  def checkout(options = T.unsafe(nil)); end

  # Reloads the ConnectionPool by passing each connection to +block+ and then
  # removing it the pool. Subsequent checkouts will create new connections as
  # needed.
  #
  # source://connection_pool/lib/connection_pool.rb#159
  def reload(&block); end

  # Shuts down the ConnectionPool by passing each connection to +block+ and
  # then removing it from the pool. Attempting to checkout a connection after
  # shutdown will raise +ConnectionPool::PoolShuttingDownError+.
  #
  # source://connection_pool/lib/connection_pool.rb#150
  def shutdown(&block); end

  # Size of this connection pool
  #
  # source://connection_pool/lib/connection_pool.rb#164
  def size; end

  # source://connection_pool/lib/connection_pool.rb#105
  def then(options = T.unsafe(nil)); end

  # source://connection_pool/lib/connection_pool.rb#105
  def with(options = T.unsafe(nil)); end

  class << self
    # source://connection_pool/lib/connection_pool.rb#52
    def after_fork; end

    # source://connection_pool/lib/connection_pool.rb#44
    def wrap(options, &block); end
  end
end

# source://connection_pool/lib/connection_pool.rb#42
ConnectionPool::DEFAULTS = T.let(T.unsafe(nil), Hash)

# source://connection_pool/lib/connection_pool.rb#5
class ConnectionPool::Error < ::RuntimeError; end

# source://connection_pool/lib/connection_pool.rb#70
module ConnectionPool::ForkTracker
  # source://connection_pool/lib/connection_pool.rb#71
  def _fork; end
end

# source://connection_pool/lib/connection_pool.rb#49
ConnectionPool::INSTANCES = T.let(T.unsafe(nil), ObjectSpace::WeakMap)

# source://connection_pool/lib/connection_pool.rb#7
class ConnectionPool::PoolShuttingDownError < ::ConnectionPool::Error; end

# Examples:
#
#    ts = TimedStack.new(1) { MyConnection.new }
#
#    # fetch a connection
#    conn = ts.pop
#
#    # return a connection
#    ts.push conn
#
#    conn = ts.pop
#    ts.pop timeout: 5
#    #=> raises ConnectionPool::TimeoutError after 5 seconds
#
# source://connection_pool/lib/connection_pool/timed_stack.rb#20
class ConnectionPool::TimedStack
  # Creates a new pool with +size+ connections that are created from the given
  # +block+.
  #
  # @return [TimedStack] a new instance of TimedStack
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#27
  def initialize(size = T.unsafe(nil), &block); end

  # Returns +obj+ to the stack.  +options+ is ignored in TimedStack but may be
  # used by subclasses that extend TimedStack.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#41
  def <<(obj, options = T.unsafe(nil)); end

  # Returns +true+ if there are no available connections.
  #
  # @return [Boolean]
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#104
  def empty?; end

  # The number of connections available on the stack.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#111
  def length; end

  # Returns the value of attribute max.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#21
  def max; end

  # Retrieves a connection from the stack.  If a connection is available it is
  # immediately returned.  If no connection is available within the given
  # timeout a ConnectionPool::TimeoutError is raised.
  #
  # +:timeout+ is the only checked entry in +options+ and is preferred over
  # the +timeout+ argument (which will be removed in a future release).  Other
  # options may be used by subclasses that extend TimedStack.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#63
  def pop(timeout = T.unsafe(nil), options = T.unsafe(nil)); end

  # Returns +obj+ to the stack.  +options+ is ignored in TimedStack but may be
  # used by subclasses that extend TimedStack.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#41
  def push(obj, options = T.unsafe(nil)); end

  # Shuts down the TimedStack by passing each connection to +block+ and then
  # removing it from the pool. Attempting to checkout a connection after
  # shutdown will raise +ConnectionPool::PoolShuttingDownError+ unless
  # +:reload+ is +true+.
  #
  # @raise [ArgumentError]
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#89
  def shutdown(reload: T.unsafe(nil), &block); end

  private

  # This is an extension point for TimedStack and is called with a mutex.
  #
  # This method must returns true if a connection is available on the stack.
  #
  # @return [Boolean]
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#126
  def connection_stored?(options = T.unsafe(nil)); end

  # source://connection_pool/lib/connection_pool/timed_stack.rb#117
  def current_time; end

  # This is an extension point for TimedStack and is called with a mutex.
  #
  # This method must return a connection from the stack.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#135
  def fetch_connection(options = T.unsafe(nil)); end

  # This is an extension point for TimedStack and is called with a mutex.
  #
  # This method must shut down all connections on the stack.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#144
  def shutdown_connections(options = T.unsafe(nil)); end

  # This is an extension point for TimedStack and is called with a mutex.
  #
  # This method must return +obj+ to the stack.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#157
  def store_connection(obj, options = T.unsafe(nil)); end

  # This is an extension point for TimedStack and is called with a mutex.
  #
  # This method must create a connection if and only if the total number of
  # connections allowed has not been met.
  #
  # source://connection_pool/lib/connection_pool/timed_stack.rb#167
  def try_create(options = T.unsafe(nil)); end
end

# source://connection_pool/lib/connection_pool.rb#9
class ConnectionPool::TimeoutError < ::Timeout::Error; end

# source://connection_pool/lib/connection_pool/version.rb#2
ConnectionPool::VERSION = T.let(T.unsafe(nil), String)

# source://connection_pool/lib/connection_pool/wrapper.rb#2
class ConnectionPool::Wrapper < ::BasicObject
  # @return [Wrapper] a new instance of Wrapper
  #
  # source://connection_pool/lib/connection_pool/wrapper.rb#5
  def initialize(options = T.unsafe(nil), &block); end

  # source://connection_pool/lib/connection_pool/wrapper.rb#35
  def method_missing(name, *args, **kwargs, &block); end

  # source://connection_pool/lib/connection_pool/wrapper.rb#25
  def pool_available; end

  # source://connection_pool/lib/connection_pool/wrapper.rb#17
  def pool_shutdown(&block); end

  # source://connection_pool/lib/connection_pool/wrapper.rb#21
  def pool_size; end

  # @return [Boolean]
  #
  # source://connection_pool/lib/connection_pool/wrapper.rb#29
  def respond_to?(id, *args); end

  # source://connection_pool/lib/connection_pool/wrapper.rb#13
  def with(&block); end

  # source://connection_pool/lib/connection_pool/wrapper.rb#9
  def wrapped_pool; end
end

# source://connection_pool/lib/connection_pool/wrapper.rb#3
ConnectionPool::Wrapper::METHODS = T.let(T.unsafe(nil), Array)

module Process
  extend ::RedisClient::PIDCache::CoreExt
  extend ::ConnectionPool::ForkTracker
  extend ::ActiveSupport::ForkTracker::ModernCoreExt
end