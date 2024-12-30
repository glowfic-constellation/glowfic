# frozen_string_literal: true
class DeviseMailer < Devise::Mailer
  # override Devise::Mailer to use Resque and pass the class and ID (instead of the model, which
  # isn't supported via Resque::Mailer - this fixes the serialization)
  # combines with send_devise_notification in models/user.rb.
  def self.perform(action, args)
    args[0] = args[0]["resource_class"].constantize.find(args[0]["resource_id"])
    super # from resque-mailer
  end

  # overriding https://github.com/zapnap/resque_mailer/blob/v2.4.3/lib/resque_mailer.rb#L44
  # to ensure devise mails are safely sent via resque
  def self.method_missing(method_name, *args)
    if action_methods.include?(method_name.to_s)
      # i.e. when calling DeviseMailer.reset_password ("action method"),
      # corresponding to the `def reset_password` instance method

      # transform the first param to a serializable hash, but only if we're actually delivering mail
      # (otherwise we're just testing the mailer)
      record = args[0]
      args[0] = { resource_class: record.class.name, resource_id: record.id }
      message = MessageDecoy.new(self, method_name, *args)
      if message.environment_excluded?
        args[0] = record
        message = MessageDecoy.new(self, method_name, *args)
      end
      message
    else
      super
    end
  end

  def self.respond_to_missing?(name, include_private)
    action_methods.include?(name.to_s) || super
  end
end
