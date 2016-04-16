class UserMailer < ActionMailer::Base
  default from: "Glowfic Constellation <#{ENV['GMAIL_USERNAME']}>"
  helper :application
  helper :mailer
  layout 'mailer'

  def post_has_new_reply(user, reply)
    @subject = "New reply in the thread " + reply.post.subject
    @reply = reply
    @user = user
    mail(to: user.email, subject: @subject)
  end

  def password_reset_link(password_reset)
    @subject = "Password Reset Link"
    @password_reset = password_reset
    mail(to: password_reset.user.email, subject: @subject)
  end
end
