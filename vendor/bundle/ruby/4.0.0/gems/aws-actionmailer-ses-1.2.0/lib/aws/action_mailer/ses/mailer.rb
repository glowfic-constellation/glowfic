# frozen_string_literal: true

require 'aws-sdk-ses'

module Aws
  module ActionMailer
    module SES
      # Provides a delivery method for ActionMailer that uses Amazon Simple Email Service.
      #
      # Delivery settings are used to construct a new `Aws::SES::Client` instance.
      # Once you have a delivery method, you can configure your Rails environment to use it:
      #
      #     config.action_mailer.delivery_method = :ses
      #     config.action_mailer.ses_settings = { region: 'us-west-2' }
      #
      # Alternatively, you could pass the client itself.
      #
      # The passed in client will be prioritized regardless of other `:ses_settings` given.
      #
      # @see https://guides.rubyonrails.org/action_mailer_basics.html
      class Mailer
        attr_reader :settings

        # @param [Hash] settings
        #   Passes along initialization options to [Aws::SES::Client.new](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SES/Client.html#initialize-instance_method).
        #   You may pass `:ses_client` with a preconstructed {Aws::SES::Client} to reuse
        #   an existing instance (e.g. to avoid credential resolution on every delivery).
        #   When provided, the injected client is used and all other options are ignored.
        def initialize(settings = {})
          @settings = settings
          client_settings = settings.dup
          @client = client_settings.delete(:ses_client) || Aws::SES::Client.new(client_settings)

          update_user_agent
        end

        # Delivers a Mail::Message object. Called during mail delivery.
        def deliver!(message)
          params = {
            raw_message: { data: message.to_s },
            source: message.smtp_envelope_from, # defaults to From header
            destinations: message.smtp_envelope_to # defaults to destinations (To,Cc,Bcc)
          }
          @client.send_raw_email(params).tap do |response|
            message.header[:ses_message_id] = response.message_id
          end
        end

        private

        def update_user_agent
          return if @client.config.user_agent_frameworks.include?('aws-actionmailer-ses')

          @client.config.user_agent_frameworks << 'aws-actionmailer-ses'
        end
      end
    end
  end
end
