# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `resque_mailer` gem.
# Please instead update this file by running `bin/tapioca gem resque_mailer`.

# source://resque_mailer/lib/resque_mailer/version.rb#1
module Resque
  extend ::Resque::Helpers

  # source://resque/2.6.0lib/resque.rb#260
  def after_fork(&block); end

  # source://resque/2.6.0lib/resque.rb#265
  def after_fork=(block); end

  # source://resque/2.6.0lib/resque.rb#282
  def after_pause(&block); end

  # source://resque/2.6.0lib/resque.rb#287
  def after_pause=(block); end

  # source://resque/2.6.0lib/resque.rb#230
  def before_first_fork(&block); end

  # source://resque/2.6.0lib/resque.rb#235
  def before_first_fork=(block); end

  # source://resque/2.6.0lib/resque.rb#245
  def before_fork(&block); end

  # source://resque/2.6.0lib/resque.rb#250
  def before_fork=(block); end

  # source://resque/2.6.0lib/resque.rb#271
  def before_pause(&block); end

  # source://resque/2.6.0lib/resque.rb#276
  def before_pause=(block); end

  # source://resque/2.6.0lib/resque.rb#60
  def classify(dashed_word); end

  # source://resque/2.6.0lib/resque.rb#81
  def constantize(camel_cased_word); end

  # source://resque/2.6.0lib/resque.rb#140
  def data_store; end

  # source://resque/2.6.0lib/resque.rb#43
  def decode(object); end

  # source://resque/2.6.0lib/resque.rb#487
  def dequeue(klass, *args); end

  # source://resque/2.6.0lib/resque.rb#34
  def encode(object); end

  # source://resque_spec/0.18.1lib/resque_spec/ext.rb#38
  def enqueue(klass, *args); end

  # source://resque/2.6.0lib/resque.rb#215
  def enqueue_front; end

  # source://resque/2.6.0lib/resque.rb#214
  def enqueue_front=(_arg0); end

  # source://resque_spec/0.18.1lib/resque_spec/ext.rb#44
  def enqueue_to(queue, klass, *args); end

  # source://resque/2.6.0lib/resque.rb#444
  def enqueue_to_without_resque_spec(queue, klass, *args); end

  # source://resque/2.6.0lib/resque.rb#431
  def enqueue_without_resque_spec(klass, *args); end

  # source://resque/2.6.0lib/resque.rb#192
  def heartbeat_interval; end

  # source://resque/2.6.0lib/resque.rb#191
  def heartbeat_interval=(_arg0); end

  # source://resque/2.6.0lib/resque.rb#563
  def info; end

  # source://resque/2.6.0lib/resque.rb#323
  def inline; end

  # source://resque/2.6.0lib/resque.rb#323
  def inline=(_arg0); end

  def inline?; end

  # source://resque/2.6.0lib/resque.rb#578
  def keys; end

  # source://resque/2.6.0lib/resque.rb#385
  def list_range(key, start = T.unsafe(nil), count = T.unsafe(nil)); end

  # source://resque/2.6.0lib/resque.rb#184
  def logger; end

  # source://resque/2.6.0lib/resque.rb#184
  def logger=(_arg0); end

  # source://resque_spec/0.18.1lib/resque_spec/ext.rb#59
  def peek(queue, start = T.unsafe(nil), count = T.unsafe(nil)); end

  # source://resque/2.6.0lib/resque.rb#374
  def peek_without_resque_spec(queue, start = T.unsafe(nil), count = T.unsafe(nil)); end

  # source://resque/2.6.0lib/resque.rb#356
  def pop(queue); end

  # source://resque/2.6.0lib/resque.rb#202
  def prune_interval; end

  # source://resque/2.6.0lib/resque.rb#201
  def prune_interval=(_arg0); end

  # source://resque/2.6.0lib/resque.rb#349
  def push(queue, item); end

  # source://resque/2.6.0lib/resque.rb#296
  def queue_empty(&block); end

  # source://resque/2.6.0lib/resque.rb#301
  def queue_empty=(block); end

  # source://resque/2.6.0lib/resque.rb#505
  def queue_from_class(klass); end

  # source://resque/2.6.0lib/resque.rb#583
  def queue_sizes; end

  # source://resque/2.6.0lib/resque.rb#395
  def queues; end

  # source://resque/2.6.0lib/resque.rb#140
  def redis; end

  # source://resque/2.6.0lib/resque.rb#114
  def redis=(server); end

  # source://resque/2.6.0lib/resque.rb#147
  def redis_id; end

  # source://resque/2.6.0lib/resque.rb#400
  def remove_queue(queue); end

  # source://resque/2.6.0lib/resque.rb#553
  def remove_worker(worker_id); end

  # source://resque_spec/0.18.1lib/resque_spec/ext.rb#66
  def reserve(queue_name); end

  # source://resque/2.6.0lib/resque.rb#515
  def reserve_without_resque_spec(queue); end

  # source://resque/2.6.0lib/resque.rb#596
  def sample_queues(sample_size = T.unsafe(nil)); end

  # source://resque_spec/0.18.1lib/resque_spec/ext.rb#72
  def size(queue_name); end

  # source://resque/2.6.0lib/resque.rb#362
  def size_without_resque_spec(queue); end

  # source://resque/2.6.0lib/resque.rb#179
  def stat_data_store; end

  # source://resque/2.6.0lib/resque.rb#174
  def stat_data_store=(stat_data_store); end

  # source://resque/2.6.0lib/resque.rb#319
  def to_s; end

  # source://resque/2.6.0lib/resque.rb#524
  def validate(klass, queue = T.unsafe(nil)); end

  # source://resque/2.6.0lib/resque.rb#406
  def watch_queue(queue); end

  # source://resque/2.6.0lib/resque.rb#310
  def worker_exit(&block); end

  # source://resque/2.6.0lib/resque.rb#315
  def worker_exit=(block); end

  # source://resque/2.6.0lib/resque.rb#542
  def workers; end

  # source://resque/2.6.0lib/resque.rb#547
  def working; end

  private

  # source://resque/2.6.0lib/resque.rb#639
  def clear_hooks(name); end

  # source://resque/2.6.0lib/resque.rb#644
  def hooks(name); end

  # source://resque/2.6.0lib/resque.rb#631
  def register_hook(name, block); end

  # source://resque_spec/0.18.1lib/resque_spec/ext.rb#80
  def run_after_enqueue(klass, *args); end

  # source://resque_spec/0.18.1lib/resque_spec/ext.rb#86
  def run_before_enqueue(klass, *args); end

  class << self
    # source://resque-heroku-signals/2.6.0lib/resque-heroku-signals.rb#6
    def heroku_will_terminate?; end
  end
end

# source://resque_mailer/lib/resque_mailer/version.rb#2
module Resque::Mailer
  mixes_in_class_methods ::Resque::Mailer::ClassMethods

  class << self
    # Returns the value of attribute argument_serializer.
    #
    # source://resque_mailer/lib/resque_mailer.rb#10
    def argument_serializer; end

    # Sets the attribute argument_serializer
    #
    # @param value the value to set the attribute argument_serializer to.
    #
    # source://resque_mailer/lib/resque_mailer.rb#10
    def argument_serializer=(_arg0); end

    # Returns the value of attribute current_env.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def current_env; end

    # Sets the attribute current_env
    #
    # @param value the value to set the attribute current_env to.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def current_env=(_arg0); end

    # Returns the value of attribute default_queue_name.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def default_queue_name; end

    # Sets the attribute default_queue_name
    #
    # @param value the value to set the attribute default_queue_name to.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def default_queue_name=(_arg0); end

    # Returns the value of attribute default_queue_target.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def default_queue_target; end

    # Sets the attribute default_queue_target
    #
    # @param value the value to set the attribute default_queue_target to.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def default_queue_target=(_arg0); end

    # Returns the value of attribute error_handler.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def error_handler; end

    # Sets the attribute error_handler
    #
    # @param value the value to set the attribute error_handler to.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def error_handler=(_arg0); end

    # Returns the value of attribute excluded_environments.
    #
    # source://resque_mailer/lib/resque_mailer.rb#11
    def excluded_environments; end

    # source://resque_mailer/lib/resque_mailer.rb#13
    def excluded_environments=(envs); end

    # @private
    #
    # source://resque_mailer/lib/resque_mailer.rb#23
    def included(base); end

    # Returns the value of attribute logger.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def logger; end

    # Sets the attribute logger
    #
    # @param value the value to set the attribute logger to.
    #
    # source://resque_mailer/lib/resque_mailer.rb#9
    def logger=(_arg0); end

    # source://resque_mailer/lib/resque_mailer.rb#17
    def prepare_message(klass, action, *args); end
  end
end

# source://resque_mailer/lib/resque_mailer.rb#34
module Resque::Mailer::ClassMethods
  # source://resque_mailer/lib/resque_mailer.rb#36
  def current_env; end

  # @return [Boolean]
  #
  # source://resque_mailer/lib/resque_mailer.rb#97
  def deliver?; end

  # @return [Boolean]
  #
  # source://resque_mailer/lib/resque_mailer.rb#93
  def excluded_environment?(name); end

  # source://resque_mailer/lib/resque_mailer.rb#44
  def method_missing(method_name, *args); end

  # source://resque_mailer/lib/resque_mailer.rb#52
  def perform(action, serialized_args); end

  # source://resque_mailer/lib/resque_mailer.rb#81
  def queue; end

  # source://resque_mailer/lib/resque_mailer.rb#85
  def queue=(name); end

  # source://resque_mailer/lib/resque_mailer.rb#89
  def resque; end
end

# source://resque_mailer/lib/resque_mailer.rb#102
class Resque::Mailer::MessageDecoy
  # @return [MessageDecoy] a new instance of MessageDecoy
  #
  # source://resque_mailer/lib/resque_mailer.rb#105
  def initialize(mailer_class, method_name, *args); end

  # source://resque_mailer/lib/resque_mailer.rb#133
  def actual_message; end

  # source://resque_mailer/lib/resque_mailer.rb#117
  def current_env; end

  # source://resque_mailer/lib/resque_mailer.rb#137
  def deliver; end

  # source://resque_mailer/lib/resque_mailer.rb#183
  def deliver!; end

  # source://resque_mailer/lib/resque_mailer.rb#151
  def deliver_at(time); end

  # source://resque_mailer/lib/resque_mailer.rb#163
  def deliver_in(time); end

  # source://resque_mailer/lib/resque_mailer.rb#137
  def deliver_now; end

  # source://resque_mailer/lib/resque_mailer.rb#183
  def deliver_now!; end

  # @return [Boolean]
  #
  # source://resque_mailer/lib/resque_mailer.rb#125
  def environment_excluded?; end

  # @return [Boolean]
  #
  # source://resque_mailer/lib/resque_mailer.rb#129
  def excluded_environment?(name); end

  # source://resque_mailer/lib/resque_mailer.rb#200
  def logger; end

  # source://resque_mailer/lib/resque_mailer.rb#192
  def method_missing(method_name, *args); end

  # @return [Boolean]
  #
  # source://resque_mailer/lib/resque_mailer.rb#196
  def respond_to?(method_name, *args); end

  # source://resque_mailer/lib/resque_mailer.rb#113
  def resque; end

  # source://resque_mailer/lib/resque_mailer.rb#103
  def to_s(*_arg0, **_arg1, &_arg2); end

  # source://resque_mailer/lib/resque_mailer.rb#175
  def unschedule_delivery; end
end

# source://resque_mailer/lib/resque_mailer/serializers/pass_thru_serializer.rb#3
module Resque::Mailer::Serializers; end

# source://resque_mailer/lib/resque_mailer/serializers/active_record_serializer.rb#4
module Resque::Mailer::Serializers::ActiveRecordSerializer
  extend ::Resque::Mailer::Serializers::ActiveRecordSerializer

  # source://resque_mailer/lib/resque_mailer/serializers/active_record_serializer.rb#17
  def deserialize(data); end

  # source://resque_mailer/lib/resque_mailer/serializers/active_record_serializer.rb#7
  def serialize(*args); end
end

# Simple serializer for Resque arguments
# New serializers need only implement the self.serialize(*args) and self.deserialize(data)
# * self.serialize(*args) should return the arguments serialized as an object
# * self.deserialize(data) should take the serialized object as its only argument and return the array of arguments
#
# source://resque_mailer/lib/resque_mailer/serializers/pass_thru_serializer.rb#10
module Resque::Mailer::Serializers::PassThruSerializer
  extend ::Resque::Mailer::Serializers::PassThruSerializer

  # source://resque_mailer/lib/resque_mailer/serializers/pass_thru_serializer.rb#17
  def deserialize(data); end

  # source://resque_mailer/lib/resque_mailer/serializers/pass_thru_serializer.rb#13
  def serialize(*args); end
end

# source://resque_mailer/lib/resque_mailer/version.rb#3
Resque::Mailer::VERSION = T.let(T.unsafe(nil), String)