# frozen_string_literal: true

require 'aws-sdk-sesv2'

module Aws
  module ActionMailer
    module SESV2
      # Provides a delivery method for ActionMailer that uses Amazon Simple Email Service V2.
      #
      # Once you have a delivery method, you can configure your Rails environment to use it:
      #
      #     config.action_mailer.delivery_method = :ses_v2
      #     config.action_mailer.ses_v2_settings = { region: 'us-west-2' }
      #
      # You may also pass a preconstructed client:
      #
      #     sesv2_client = Aws::SESV2::Client.new(region: 'us-west-2')
      #     config.action_mailer.ses_v2_settings = { sesv2_client: sesv2_client }
      #
      # == SendEmail Options
      #
      # Settings in {SEND_EMAIL_KEYS} are forwarded directly to the
      # {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SESV2/Client.html#send_email-instance_method SendEmail}
      # API call rather than to the client constructor. They can be configured at
      # any level:
      #
      #     # Global (all emails)
      #     config.action_mailer.ses_v2_settings = {
      #       region: 'us-west-2',
      #       configuration_set_name: 'Production'
      #     }
      #
      #     # Per-mailer class
      #     class MarketingMailer < ApplicationMailer
      #       default delivery_method_options: {
      #         configuration_set_name: 'Marketing',
      #         list_management_options: { contact_list_name: 'Promos', topic_name: 'Weekly' }
      #       }
      #     end
      #
      # @see https://guides.rubyonrails.org/action_mailer_basics.html
      class Mailer
        SEND_EMAIL_KEYS = %i[
          configuration_set_name
          email_tags
          list_management_options
        ].freeze

        attr_reader :settings

        # @param [Hash] settings
        #   Passes along initialization settings to [Aws::SESV2::Client.new](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SESV2/Client.html#initialize-instance_method).
        #   You may pass `:sesv2_client` with a preconstructed {Aws::SESV2::Client} to reuse
        #   an existing instance (e.g. to avoid credential resolution on every delivery).
        #   When provided, the injected client is used and all other options are ignored.
        #
        #   The following keys are extracted from settings and forwarded as parameters
        #   to the [SendEmail](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SESV2/Client.html#send_email-instance_method)
        #   API call (they are not passed to the client constructor):
        #
        #   * `:configuration_set_name` - The name of the configuration set to use for this message.
        #   * `:email_tags` - A list of message tags ({Types::MessageTag} hashes).
        #   * `:list_management_options` - A {Types::ListManagementOptions} hash for SES
        #     subscription management.
        #
        def initialize(settings = {})
          @settings = settings
          @send_email_params = {}
          client_settings = settings.dup
          SEND_EMAIL_KEYS.each do |key|
            value = client_settings.delete(key)
            @send_email_params[key] = value if value
          end
          @client = client_settings.delete(:sesv2_client) || Aws::SESV2::Client.new(client_settings)

          update_user_agent
        end

        # Delivers a Mail::Message object. Called during mail delivery.
        def deliver!(message) # rubocop:disable Metrics/MethodLength
          params = { content: { raw: { data: message.to_s } } }
          params[:from_email_address] = from_email_address(message)
          params[:destination] = {
            to_addresses: to_addresses(message),
            cc_addresses: message.cc,
            bcc_addresses: message.bcc
          }
          params.merge!(@send_email_params)

          @client.send_email(params).tap do |response|
            message.header[:ses_message_id] = response.message_id
          end
        end

        private

        def update_user_agent
          return if @client.config.user_agent_frameworks.include?('aws-actionmailer-ses')

          @client.config.user_agent_frameworks << 'aws-actionmailer-ses'
        end

        # smtp_envelope_from will default to the From address *without* sender names.
        # By omitting this param, SESv2 will correctly use sender names from the mail headers.
        # We should only use smtp_envelope_from when it was explicitly set (instance variable set)
        def from_email_address(message)
          message.instance_variable_get(:@smtp_envelope_from) ? message.smtp_envelope_from : nil
        end

        # smtp_envelope_to will default to the full destinations (To, Cc, Bcc)
        # SES v2 API prefers each component split out into a destination hash.
        # When smtp_envelope_to was set, use it explicitly for to_address only.
        def to_addresses(message)
          message.instance_variable_get(:@smtp_envelope_to) ? message.smtp_envelope_to : message.to
        end
      end
    end
  end
end
