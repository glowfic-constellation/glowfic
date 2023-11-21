# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `aws-sdk-rails` gem.
# Please instead update this file by running `bin/tapioca gem aws-sdk-rails`.

# source://aws-sdk-rails/lib/action_dispatch/session/dynamodb_store.rb#6
module ActionDispatch
  # source://actionpack/7.0.8lib/action_dispatch.rb#99
  def test_app; end

  # source://actionpack/7.0.8lib/action_dispatch.rb#99
  def test_app=(val); end

  class << self
    # source://actionpack/7.0.8lib/action_dispatch.rb#99
    def test_app; end

    # source://actionpack/7.0.8lib/action_dispatch.rb#99
    def test_app=(val); end
  end
end

# source://aws-sdk-rails/lib/action_dispatch/session/dynamodb_store.rb#7
module ActionDispatch::Session; end

# Uses the Dynamo DB Session Store implementation to create a class that
# extends ActionDispatch::Session. Rails will create a :dynamodb_store
# configuration for session_store from this class name.
#
# This class will use the Rails secret_key_base unless otherwise provided.
#
# Configuration can also be provided in YAML files from Rails config, either
# in "config/session_store.yml" or "config/session_store/#\\{Rails.env}.yml".
# Configuration files that are environment-specific will take precedence.
#
# @see https://docs.aws.amazon.com/sdk-for-ruby/aws-sessionstore-dynamodb/api/Aws/SessionStore/DynamoDB/Configuration.html
#
# source://aws-sdk-rails/lib/action_dispatch/session/dynamodb_store.rb#19
class ActionDispatch::Session::DynamodbStore < ::Aws::SessionStore::DynamoDB::RackMiddleware
  include ::ActionDispatch::Session::StaleSessionCheck
  include ::ActionDispatch::Session::SessionObject

  # @return [DynamodbStore] a new instance of DynamodbStore
  #
  # source://aws-sdk-rails/lib/action_dispatch/session/dynamodb_store.rb#23
  def initialize(app, options = T.unsafe(nil)); end

  private

  # source://aws-sdk-rails/lib/action_dispatch/session/dynamodb_store.rb#31
  def config_file; end
end

# source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#5
module ActiveJob
  class << self
    # source://activejob/7.0.8lib/active_job/gem_version.rb#5
    def gem_version; end

    # source://activejob/7.0.8lib/active_job/version.rb#7
    def version; end
  end
end

# source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#6
module ActiveJob::QueueAdapters
  class << self
    # source://activejob/7.0.8lib/active_job/queue_adapters.rb#136
    def lookup(name); end
  end
end

# create an alias to allow `:amazon` to be used as the adapter name
# `:amazon` is the convention used for ActionMailer and ActiveStorage
#
# source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#64
ActiveJob::QueueAdapters::AmazonAdapter = ActiveJob::QueueAdapters::AmazonSqsAdapter

# source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#7
class ActiveJob::QueueAdapters::AmazonSqsAdapter
  # source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#8
  def enqueue(job); end

  # @raise [ArgumentError]
  #
  # source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#12
  def enqueue_at(job, timestamp); end

  private

  # source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#21
  def _enqueue(job, body = T.unsafe(nil), send_message_opts = T.unsafe(nil)); end

  # source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#54
  def deduplication_body(job, body); end

  # source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_adapter.rb#41
  def message_attributes(job); end
end

# == Async adapter for Amazon SQS ActiveJob
#
# This adapter queues jobs asynchronously (ie non-blocking).  Error handler can be configured
# with +Aws::Rails::SqsActiveJob.config.async_queue_error_handler+.
#
# To use this adapter, set up as:
#
# config.active_job.queue_adapter = :amazon_sqs_async
#
# source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_async_adapter.rb#16
class ActiveJob::QueueAdapters::AmazonSqsAsyncAdapter < ::ActiveJob::QueueAdapters::AmazonSqsAdapter
  private

  # source://aws-sdk-rails/lib/active_job/queue_adapters/amazon_sqs_async_adapter.rb#19
  def _enqueue(job, body = T.unsafe(nil), send_message_opts = T.unsafe(nil)); end
end

# source://aws-sdk-rails/lib/aws/rails/ses_mailer.rb#5
module Aws
  class << self
    # source://aws-sdk-core/3.187.0lib/aws-sdk-core.rb#133
    def config; end

    # source://aws-sdk-core/3.187.0lib/aws-sdk-core.rb#136
    def config=(config); end

    # source://aws-sdk-core/3.187.0lib/aws-sdk-core.rb#195
    def eager_autoload!(*args); end

    # source://aws-sdk-core/3.187.0lib/aws-sdk-core.rb#188
    def empty_connection_pools!; end

    # source://aws-sdk-core/3.187.0lib/aws-sdk-core.rb#145
    def partition(partition_name); end

    # source://aws-sdk-core/3.187.0lib/aws-sdk-core.rb#150
    def partitions; end

    # source://aws-sdk-core/3.187.0lib/aws-sdk-core.rb#126
    def shared_config; end

    # source://aws-sdk-core/3.187.0lib/aws-sdk-core.rb#165
    def use_bundled_cert!; end
  end
end

# Use the Rails namespace.
#
# source://aws-sdk-rails/lib/aws/rails/ses_mailer.rb#6
module Aws::Rails
  class << self
    # This is called automatically from the SDK's Railtie, but can be manually
    # called if you want to specify options for building the Aws::SES::Client.
    #
    # @param name [Symbol] The name of the ActionMailer delivery method to
    #   register.
    # @param client_options [Hash] The options you wish to pass on to the
    #   Aws::SES[V2]::Client initialization method.
    #
    # source://aws-sdk-rails/lib/aws/rails/railtie.rb#34
    def add_action_mailer_delivery_method(name = T.unsafe(nil), client_options = T.unsafe(nil)); end

    # Register a middleware that will handle requests from the Elastic Beanstalk worker SQS Daemon.
    # This will only be added in the presence of the AWS_PROCESS_BEANSTALK_WORKER_REQUESTS environment variable.
    # The expectation is this variable should only be set on EB worker environments.
    #
    # source://aws-sdk-rails/lib/aws/rails/railtie.rb#77
    def add_sqsd_middleware(app); end

    # Adds ActiveSupport Notifications instrumentation to AWS SDK
    # client operations.  Each operation will produce an event with a name:
    # <operation>.<service>.aws.  For example, S3's put_object has an event
    # name of: put_object.S3.aws
    #
    # source://aws-sdk-rails/lib/aws/rails/railtie.rb#64
    def instrument_sdk_operations; end

    # Configures the AWS SDK for Ruby's logger to use the Rails logger.
    #
    # source://aws-sdk-rails/lib/aws/rails/railtie.rb#45
    def log_to_rails_logger; end

    # Configures the AWS SDK with credentials from Rails encrypted credentials.
    #
    # source://aws-sdk-rails/lib/aws/rails/railtie.rb#51
    def use_rails_encrypted_credentials; end
  end
end

# Middleware to handle requests from the SQS Daemon present on Elastic Beanstalk worker environments.
#
# source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#6
class Aws::Rails::EbsSqsActiveJobMiddleware
  # @return [EbsSqsActiveJobMiddleware] a new instance of EbsSqsActiveJobMiddleware
  #
  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#12
  def initialize(app); end

  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#17
  def call(env); end

  private

  # @return [Boolean]
  #
  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#87
  def app_runs_in_docker_container?; end

  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#91
  def default_gw_ips; end

  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#37
  def execute_job(request); end

  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#54
  def execute_periodic_task(request); end

  # The beanstalk worker SQS Daemon sets a specific User-Agent headers that begins with 'aws-sqsd'.
  #
  # @return [Boolean]
  #
  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#72
  def from_sqs_daemon?(request); end

  # The beanstalk worker SQS Daemon will add the custom 'X-Aws-Sqsd-Taskname' header for periodic tasks set in cron.yaml.
  #
  # @return [Boolean]
  #
  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#79
  def periodic_task?(request); end

  # @return [Boolean]
  #
  # source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#83
  def sent_from_docker_host?(request); end
end

# source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#9
Aws::Rails::EbsSqsActiveJobMiddleware::FORBIDDEN_MESSAGE = T.let(T.unsafe(nil), String)

# source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#10
Aws::Rails::EbsSqsActiveJobMiddleware::FORBIDDEN_RESPONSE = T.let(T.unsafe(nil), Array)

# source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#7
Aws::Rails::EbsSqsActiveJobMiddleware::INTERNAL_ERROR_MESSAGE = T.let(T.unsafe(nil), String)

# source://aws-sdk-rails/lib/aws/rails/middleware/ebs_sqs_active_job_middleware.rb#8
Aws::Rails::EbsSqsActiveJobMiddleware::INTERNAL_ERROR_RESPONSE = T.let(T.unsafe(nil), Array)

# This is for backwards compatibility after introducing support for SESv2.
# The old mailer is now replaced with the new SES (v1) mailer.
#
# source://aws-sdk-rails/lib/aws/rails/ses_mailer.rb#49
Aws::Rails::Mailer = Aws::Rails::SesMailer

# Instruments client operation calls for ActiveSupport::Notifications
# Each client operation will produce an event with name:
# <operation>.<service>.aws
#
# @api private
#
# source://aws-sdk-rails/lib/aws/rails/notifications.rb#12
class Aws::Rails::Notifications < ::Seahorse::Client::Plugin
  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/notifications.rb#13
  def add_handlers(handlers, _config); end
end

# @api private
#
# source://aws-sdk-rails/lib/aws/rails/notifications.rb#20
class Aws::Rails::Notifications::Handler < ::Seahorse::Client::Handler
  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/notifications.rb#21
  def call(context); end
end

# @api private
#
# source://aws-sdk-rails/lib/aws/rails/railtie.rb#7
class Aws::Rails::Railtie < ::Rails::Railtie; end

# Provides a delivery method for ActionMailer that uses Amazon Simple Email
# Service.
#
# Once you have an SES delivery method you can configure Rails to
# use this for ActionMailer in your environment configuration
# (e.g. RAILS_ROOT/config/environments/production.rb)
#
#     config.action_mailer.delivery_method = :ses
#
# Uses the AWS SDK for Ruby's credential provider chain when creating an SES
# client instance.
#
# source://aws-sdk-rails/lib/aws/rails/ses_mailer.rb#18
class Aws::Rails::SesMailer
  # @param options [Hash] Passes along initialization options to
  #   [Aws::SES::Client.new](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SES/Client.html#initialize-instance_method).
  # @return [SesMailer] a new instance of SesMailer
  #
  # source://aws-sdk-rails/lib/aws/rails/ses_mailer.rb#21
  def initialize(options = T.unsafe(nil)); end

  # Rails expects this method to exist, and to handle a Mail::Message object
  # correctly. Called during mail delivery.
  #
  # source://aws-sdk-rails/lib/aws/rails/ses_mailer.rb#28
  def deliver!(message); end

  # ActionMailer expects this method to be present and to return a hash.
  #
  # source://aws-sdk-rails/lib/aws/rails/ses_mailer.rb#40
  def settings; end
end

# Provides a delivery method for ActionMailer that uses Amazon Simple Email
# Service V2.
#
# Once you have an SESv2 delivery method you can configure Rails to
# use this for ActionMailer in your environment configuration
# (e.g. RAILS_ROOT/config/environments/production.rb)
#
#     config.action_mailer.delivery_method = :sesv2
#
# Uses the AWS SDK for Ruby's credential provider chain when creating an SESV2
# client instance.
#
# source://aws-sdk-rails/lib/aws/rails/sesv2_mailer.rb#18
class Aws::Rails::Sesv2Mailer
  # @param options [Hash] Passes along initialization options to
  #   [Aws::SESV2::Client.new](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SESV2/Client.html#initialize-instance_method).
  # @return [Sesv2Mailer] a new instance of Sesv2Mailer
  #
  # source://aws-sdk-rails/lib/aws/rails/sesv2_mailer.rb#21
  def initialize(options = T.unsafe(nil)); end

  # Rails expects this method to exist, and to handle a Mail::Message object
  # correctly. Called during mail delivery.
  #
  # source://aws-sdk-rails/lib/aws/rails/sesv2_mailer.rb#28
  def deliver!(message); end

  # ActionMailer expects this method to be present and to return a hash.
  #
  # source://aws-sdk-rails/lib/aws/rails/sesv2_mailer.rb#46
  def settings; end

  private

  # smtp_envelope_to will default to the full destinations (To, Cc, Bcc)
  # SES v2 API prefers each component split out into a destination hash.
  # When smtp_envelope_to was set, use it explicitly for to_address only.
  #
  # source://aws-sdk-rails/lib/aws/rails/sesv2_mailer.rb#55
  def to_addresses(message); end
end

# SQS ActiveJob modules
#
# source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#5
module Aws::Rails::SqsActiveJob
  extend ::ActiveSupport::Concern
  include GeneratedInstanceMethods

  mixes_in_class_methods GeneratedClassMethods
  mixes_in_class_methods ::Aws::Rails::SqsActiveJob::ClassMethods

  class << self
    # @return [Configuration] the (singleton) Configuration
    #
    # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#7
    def config; end

    # @yield Configuration
    #
    # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#12
    def configure; end

    # @return [Boolean]
    #
    # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#16
    def fifo?(queue_url); end

    # A lambda event handler to run jobs from an SQS queue trigger
    # Trigger the lambda from your SQS queue
    # Configure the entrypoint to: +config/environment.Aws::Rails::SqsActiveJob.lambda_job_handler+
    # This will load your Rails environment, and then use this method as the handler.
    #
    # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/lambda_handler.rb#12
    def lambda_job_handler(event:, context:); end

    # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/lambda_handler.rb#41
    def to_message_attributes(record); end

    # @raise [ArgumentError]
    #
    # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/lambda_handler.rb#53
    def to_queue_url(record); end

    # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/lambda_handler.rb#25
    def to_sqs_msg(record); end
  end

  module GeneratedClassMethods
    def excluded_deduplication_keys; end
    def excluded_deduplication_keys=(value); end
    def excluded_deduplication_keys?; end
  end

  module GeneratedInstanceMethods
    def excluded_deduplication_keys; end
    def excluded_deduplication_keys=(value); end
    def excluded_deduplication_keys?; end
  end
end

# class methods for SQS ActiveJob.
#
# source://aws-sdk-rails/lib/aws/rails/sqs_active_job/deduplication.rb#14
module Aws::Rails::SqsActiveJob::ClassMethods
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/deduplication.rb#15
  def deduplicate_without(*keys); end
end

# Configuration for AWS SQS ActiveJob.
# Use +Aws::Rails::SqsActiveJob.config+ to access the singleton config instance.
#
# source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#22
class Aws::Rails::SqsActiveJob::Configuration
  # Don't use this method directly: Configuration is a singleton class, use
  # +Aws::Rails::SqsActiveJob.config+ to access the singleton config.
  #
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @param options [Hash]
  # @return [Configuration] a new instance of Configuration
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#92
  def initialize(options = T.unsafe(nil)); end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def async_queue_error_handler; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def async_queue_error_handler=(_arg0); end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#104
  def client; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def client=(_arg0); end

  # Returns the value of attribute excluded_deduplication_keys.
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#39
  def excluded_deduplication_keys; end

  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#100
  def excluded_deduplication_keys=(keys); end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def logger; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def logger=(_arg0); end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def max_messages; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def max_messages=(_arg0); end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def message_group_id; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def message_group_id=(_arg0); end

  # Return the queue_url for a given job_queue name
  #
  # @raise [ArgumentError]
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#113
  def queue_url_for(job_queue); end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def queues; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def queues=(_arg0); end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def shutdown_timeout; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def shutdown_timeout=(_arg0); end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#126
  def to_h; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#121
  def to_s; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def visibility_timeout; end

  # @api private
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#35
  def visibility_timeout=(_arg0); end

  private

  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#155
  def config_file; end

  # @return [String] Configuration path found in environment or YAML file.
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#168
  def config_file_path(options); end

  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#146
  def file_options(options = T.unsafe(nil)); end

  # Load options from YAML file
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#162
  def load_from_file(file_path); end

  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#172
  def load_yaml(file_path); end

  # Set accessible attributes after merged options.
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#139
  def set_attributes(options); end
end

# Default configuration options
#
# @api private
#
# source://aws-sdk-rails/lib/aws/rails/sqs_active_job/configuration.rb#25
Aws::Rails::SqsActiveJob::Configuration::DEFAULTS = T.let(T.unsafe(nil), Hash)

# CLI runner for polling for SQS ActiveJobs
#
# source://aws-sdk-rails/lib/aws/rails/sqs_active_job/executor.rb#9
class Aws::Rails::SqsActiveJob::Executor
  # @return [Executor] a new instance of Executor
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/executor.rb#18
  def initialize(options = T.unsafe(nil)); end

  # TODO: Consider catching the exception and sleeping instead of using :caller_runs
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/executor.rb#24
  def execute(message); end

  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/executor.rb#42
  def shutdown(timeout = T.unsafe(nil)); end
end

# source://aws-sdk-rails/lib/aws/rails/sqs_active_job/executor.rb#10
Aws::Rails::SqsActiveJob::Executor::DEFAULTS = T.let(T.unsafe(nil), Hash)

# source://aws-sdk-rails/lib/aws/rails/sqs_active_job/job_runner.rb#6
class Aws::Rails::SqsActiveJob::JobRunner
  # @return [JobRunner] a new instance of JobRunner
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/job_runner.rb#9
  def initialize(message); end

  # Returns the value of attribute class_name.
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/job_runner.rb#7
  def class_name; end

  # Returns the value of attribute id.
  #
  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/job_runner.rb#7
  def id; end

  # source://aws-sdk-rails/lib/aws/rails/sqs_active_job/job_runner.rb#15
  def run; end
end

# source://aws-sdk-rails/lib/aws-sdk-rails.rb#22
Aws::Rails::VERSION = T.let(T.unsafe(nil), String)

# source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#3
module AwsRecord; end

# source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#4
module AwsRecord::Generators; end

# source://aws-sdk-rails/lib/generators/aws_record/base.rb#9
class AwsRecord::Generators::Base < ::Rails::Generators::NamedBase
  # @return [Base] a new instance of Base
  #
  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#33
  def initialize(args, *options); end

  # source://thor/1.2.2lib/thor/base.rb#147
  def attributes; end

  # source://thor/1.2.2lib/thor/base.rb#147
  def attributes=(_arg0); end

  # source://railties/7.0.8lib/rails/generators/named_base.rb#215
  def check_class_collision; end

  # Returns the value of attribute gsi_rw_units.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def gsi_rw_units; end

  # Sets the attribute gsi_rw_units
  #
  # @param value the value to set the attribute gsi_rw_units to.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def gsi_rw_units=(_arg0); end

  # Returns the value of attribute gsis.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def gsis; end

  # Sets the attribute gsis
  #
  # @param value the value to set the attribute gsis to.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def gsis=(_arg0); end

  # Returns the value of attribute length_validations.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def length_validations; end

  # Sets the attribute length_validations
  #
  # @param value the value to set the attribute length_validations to.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def length_validations=(_arg0); end

  # Returns the value of attribute primary_read_units.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def primary_read_units; end

  # Sets the attribute primary_read_units
  #
  # @param value the value to set the attribute primary_read_units to.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def primary_read_units=(_arg0); end

  # Returns the value of attribute primary_write_units.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def primary_write_units; end

  # Sets the attribute primary_write_units
  #
  # @param value the value to set the attribute primary_write_units to.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def primary_write_units=(_arg0); end

  # Returns the value of attribute required_attrs.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def required_attrs; end

  # Sets the attribute required_attrs
  #
  # @param value the value to set the attribute required_attrs to.
  #
  # source://thor/1.2.2lib/thor/base.rb#147
  def required_attrs=(_arg0); end

  private

  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#99
  def ensure_hkey; end

  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#75
  def ensure_unique_fields; end

  # @return [Boolean]
  #
  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#137
  def has_validations?; end

  # @return [Boolean]
  #
  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#133
  def mutation_tracking_disabled?; end

  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#54
  def parse_attributes!; end

  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#168
  def parse_gsis!; end

  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#159
  def parse_rw_units(name); end

  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#141
  def parse_table_config!; end

  # source://aws-sdk-rails/lib/generators/aws_record/base.rb#197
  def parse_validations!; end
end

# source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#5
class AwsRecord::Generators::GeneratedAttribute
  # @return [GeneratedAttribute] a new instance of GeneratedAttribute
  #
  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#109
  def initialize(name, type = T.unsafe(nil), options = T.unsafe(nil)); end

  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#125
  def column_name; end

  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#11
  def field_type; end

  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#133
  def human_name; end

  # Returns the value of attribute name.
  #
  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#8
  def name; end

  # Returns the value of attribute options.
  #
  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#9
  def options; end

  # Sets the attribute options
  #
  # @param value the value to set the attribute options to.
  #
  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#9
  def options=(_arg0); end

  # Methods used by rails scaffolding
  #
  # @return [Boolean]
  #
  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#117
  def password_digest?; end

  # @return [Boolean]
  #
  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#121
  def polymorphic?; end

  # Returns the value of attribute type.
  #
  # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#8
  def type; end

  class << self
    # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#22
    def parse(field_definition); end

    private

    # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#60
    def parse_option(name, opt); end

    # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#80
    def parse_type(name, type); end

    # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#55
    def parse_type_and_options(name, type, opts); end

    # @raise [ArgumentError]
    #
    # source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#39
    def validate_opt_combs(name, type, opts); end
  end
end

# source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#7
AwsRecord::Generators::GeneratedAttribute::INVALID_HKEY_TYPES = T.let(T.unsafe(nil), Array)

# source://aws-sdk-rails/lib/generators/aws_record/generated_attribute.rb#6
AwsRecord::Generators::GeneratedAttribute::OPTS = T.let(T.unsafe(nil), Array)

# source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#5
class AwsRecord::Generators::SecondaryIndex
  # @raise [ArgumentError]
  # @return [SecondaryIndex] a new instance of SecondaryIndex
  #
  # source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#40
  def initialize(name, opts); end

  # Returns the value of attribute hash_key.
  #
  # source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#7
  def hash_key; end

  # Returns the value of attribute name.
  #
  # source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#7
  def name; end

  # Returns the value of attribute projection_type.
  #
  # source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#7
  def projection_type; end

  # Returns the value of attribute range_key.
  #
  # source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#7
  def range_key; end

  class << self
    # source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#10
    def parse(key_definition); end

    private

    # source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#25
    def get_option_value(raw_option); end

    # source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#20
    def parse_raw_options(raw_opts); end
  end
end

# source://aws-sdk-rails/lib/generators/aws_record/secondary_index.rb#6
AwsRecord::Generators::SecondaryIndex::PROJ_TYPES = T.let(T.unsafe(nil), Array)