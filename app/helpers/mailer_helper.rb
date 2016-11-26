module MailerHelper
  def current_user
    @user
  end

  def current_host
    ENV['DOMAIN_NAME'] || 'localhost:3000'
  end
end
