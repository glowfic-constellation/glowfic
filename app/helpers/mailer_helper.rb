# frozen_string_literal: true
module MailerHelper
  def current_host
    ENV.fetch('DOMAIN_NAME', 'localhost:3000')
  end
end
