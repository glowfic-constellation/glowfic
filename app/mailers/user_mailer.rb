class UserMailer < ActionMailer::Base
  default from: ENV['GMAIL_USERNAME']
  helper :application
  helper :mailer
  layout 'mailer'

  def post_has_new_reply(user, reply)
    @subject = reply.user.username + " posted a new reply in the thread " + reply.post.subject
    @reply = reply
    @user = user
    mail(to: 'xxstealthestarsxx@gmail.com', subject: @subject, content_type: "text/html")
    # mail(to: 'peahenironybath@gmail.com', subject: @subject, content_type: "text/html")
  end
end
