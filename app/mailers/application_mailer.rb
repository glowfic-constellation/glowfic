# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: "Glowfic Constellation <#{ENV.fetch('GMAIL_USERNAME', nil)}>"
  helper :application
  helper :mailer
  layout 'mailer'
end
