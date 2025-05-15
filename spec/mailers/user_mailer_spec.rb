RSpec.describe UserMailer do
  let(:user) { create(:user) }

  def html_text(html_part)
    Nokogiri::HTML5.parse(html_part.body.to_s).at("body").text.gsub(/[\s\n]+/, " ").strip
  end

  describe "#post_has_new_reply" do
    it "sends email" do
      reply = create(:reply, with_icon: true)
      mail = UserMailer.post_has_new_reply(user.id, reply.id)
      subject = "New reply in the thread " + reply.post.subject

      expect(mail.subject).to eq(subject)
      expect(mail.to).to eq([user.email])
      expect(mail.content_type).to start_with('multipart/alternative')

      expect(mail.text_part.content_type).to eq('text/plain; charset=UTF-8')
      expect(mail.text_part.body.to_s).to start_with("#{subject}. See it here:")

      expect(mail.html_part.content_type).to eq('text/html; charset=UTF-8')
      expect(mail.html_part.body.to_s).to start_with("<!DOCTYPE html>\n<html>\n<head>\n<title>#{subject}</title>")
      expect(html_text(mail.html_part)).to eq("New reply in #{reply.post.subject} #{reply.user.username} #{reply.content}")

      mail.deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "does not crash on deleted reply", aggregate_failures: false do
      reply = create(:reply)

      clear_enqueued_jobs

      UserMailer.post_has_new_reply(user.id, reply.id).deliver_later
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(1)

      reply.destroy!
      perform_enqueued_jobs

      aggregate_failures do
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(0)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end
  end

  describe "#password_reset_link" do
    it "sends email" do
      mail = UserMailer.password_reset_link(create(:password_reset, user: user).id)
      subject = 'Password Reset Link'

      expect(mail.subject).to eq(subject)
      expect(mail.to).to eq([user.email])
      expect(mail.content_type).to start_with('multipart/alternative')

      expect(mail.text_part.content_type).to eq('text/plain; charset=UTF-8')
      expect(mail.text_part.body.to_s).to start_with("Your account's password has been reset. Follow this link to choose a new password:")

      expect(mail.html_part.content_type).to eq('text/html; charset=UTF-8')
      expect(mail.html_part.body.to_s).to start_with("<!DOCTYPE html>\n<html>\n<head>\n<title>#{subject}</title>")
      text = html_text(mail.html_part)
      expect(text).to start_with("Password Reset Your account's password has been reset. " \
                                 "Choose New Password » Or copy and paste this link into your browser: ")
      expect(text).to include("https://localhost:3000/password_resets/")

      mail.deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end

  describe "#new_message" do
    it "sends email" do
      message = create(:message, recipient: user)
      mail = UserMailer.new_message(message.id)
      subject = "New message from #{message.sender_name}: #{message.unempty_subject}"

      expect(mail.subject).to eq(subject)
      expect(mail.to).to eq([user.email])
      expect(mail.content_type).to start_with('multipart/alternative')

      expect(mail.text_part.content_type).to eq('text/plain; charset=UTF-8')
      expect(mail.text_part.body.to_s).to start_with("#{subject}. See it here:")

      expect(mail.html_part.content_type).to eq('text/html; charset=UTF-8')
      expect(mail.html_part.body.to_s).to start_with("<!DOCTYPE html>\n<html>\n<head>\n<title>#{subject}</title>")
      expect(html_text(mail.html_part)).to eq(
        "#{message.unempty_subject} From: #{message.sender_name} To: #{message.recipient.username} #{message.message}",
      )

      mail.deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end

  describe "#new_notification" do
    it "sends email" do
      post = create(:post)
      notification = create(:notification, post: post, user: user)
      mail = UserMailer.new_notification(notification.id)
      subject = "An author you favorited has written a new post: #{post.subject}"

      expect(mail.subject).to eq(subject)
      expect(mail.to).to eq([user.email])
      expect(mail.content_type).to start_with('multipart/alternative')

      expect(mail.text_part.content_type).to eq('text/plain; charset=UTF-8')
      expect(mail.text_part.body.to_s).to start_with("#{subject}.\nSee it here:")

      expect(mail.html_part.content_type).to eq('text/html; charset=UTF-8')
      expect(mail.html_part.body.to_s).to start_with("<!DOCTYPE html>\n<html>\n<head>\n<title>#{subject}</title>")
      expect(html_text(mail.html_part)).to eq(
        "An Author You Favorited Has Written A New Post #{post.subject}",
      )
      mail.deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "works when notification has error" do
      notification = create(:error_notification, user: user)
      mail = UserMailer.new_notification(notification.id)
      subject = "Post import failed: #{notification.error_msg}"

      expect(mail.subject).to eq(subject.tr("\n", ''))
      expect(mail.to).to eq([user.email])
      expect(mail.content_type).to start_with('multipart/alternative')

      expect(mail.text_part.content_type).to eq('text/plain; charset=UTF-8')
      expect(mail.text_part.body.to_s).to eq("#{subject}.\n")

      expect(mail.html_part.content_type).to eq('text/html; charset=UTF-8')
      expect(mail.html_part.body.to_s).to start_with("<!DOCTYPE html>\n<html>\n<head>\n<title>#{subject}</title>")
      expect(html_text(mail.html_part)).to eq("Post Import Failed #{notification.error_msg}")

      mail.deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end
end
