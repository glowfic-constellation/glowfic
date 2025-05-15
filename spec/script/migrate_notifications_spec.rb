require Rails.root.join('script', 'migrate_notifications.rb')

RSpec.describe "migrate_notifications" do # rubocop:disable RSpec/DescribeClass
  include ActiveJob::TestHelper

  let(:import_url) { 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat' }

  def relation_for(messages)
    Message.where(id: messages.map(&:id))
  end

  it "works" do
    new_messages = Array.new(10) do
      post = create(:post, unjoined_authors: [create(:user)])
      subject = "New post by #{post.user.username}"
      content = "#{post.user.username} has just posted a new post entitled #{post.subject} in the #{post.board.name} continuity"
      content += " with #{post.unjoined_authors.first.username}. #{ScrapePostJob.view_post(post.id)}"
      create(:message, sender_id: 0, subject: subject, message: content)
    end
    new_messages = relation_for(new_messages)

    join_messages = Array.new(10) do
      joiner = create(:user)
      post = create(:post, unjoined_authors: [joiner])
      subject = "#{joiner.username} has joined a new thread"
      content = "#{joiner.username} has just joined the post entitled #{post.subject} with "
      content += "#{post.user.username}. #{ScrapePostJob.view_post(post.id)}"
      create(:message, sender_id: 0, subject: subject, message: content)
    end
    join_messages = relation_for(join_messages)

    import_messages = Array.new(10) do
      post = create(:post)
      content = "Your post was successfully imported! #{ScrapePostJob.view_post(post.id)}"
      create(:message, sender_id: 0, subject: 'Post import succeeded', message: content)
    end
    import_messages = relation_for(import_messages)

    import_error_messages = Array.new(10) do |i|
      content = "The url <a href='#{import_url}'>#{import_url}</a> could not be successfully scraped. "
      content += "Unrecognized username: test_user_#{i}"
      create(:message, sender_id: 0, subject: 'Post import failed', message: content)
    end
    import_error_messages = relation_for(import_error_messages)

    import_previous_messages = Array.new(10) do
      post = create(:post)
      content = "The url <a href='#{import_url}'>#{import_url}</a> could not be successfully scraped. "
      content += "Your post was already imported! #{ScrapePostJob.view_post(post.id)}"
      create(:message, sender_id: 0, subject: 'Post import failed', message: content)
    end
    import_previous_messages = relation_for(import_previous_messages)

    aggregate_failures do
      expect(Message.count).to eq(50)
      expect(Post.count).to eq(40)
    end

    create_list(:message, 20) # non-site messages

    other = create_list(:message, 10, sender_id: 0, subject: 'Unread at failure') # other site messages

    migrated = create_list(:notification, 10, notification_type: :import_success) # already migrated
    migrated.each { |n| create(:message, sender_id: 0, recipient_id: n.user_id, subject: 'Post import succeeded', notification_id: n.id) }

    aggregate_failures do
      expect(Message.count).to eq(90)
      expect(Post.count).to eq(50)
      expect(Notification.count).to eq(10)
    end

    migrated_messages = Message.where.not(id: other.map(&:id)).where(sender_id: 0)

    migrate_notifications

    aggregate_failures do
      expect(Notification.count).to eq(60)
      expect(Notification.pluck(:user_id)).to match_array(migrated_messages.pluck(:recipient_id))
      expect(Notification.pluck(:id)).to match_array(migrated_messages.pluck(:notification_id))

      [:new_favorite_post, :joined_favorite_post, :import_success].each do |type|
        type_notifications = Notification.where(notification_type: type).where.not(id: migrated.map(&:id))
        expect(type_notifications.count).to eq(10)
        case type
          when :new_favorite_post
            expect(type_notifications.ids).to match_array(new_messages.reload.pluck(:notification_id))
          when :joined_favorite_post
            expect(type_notifications.ids).to match_array(join_messages.reload.pluck(:notification_id))
          else
            expect(type_notifications.ids).to match_array(import_messages.reload.pluck(:notification_id))
        end
      end

      failure_notifications = Notification.where(notification_type: :import_fail)
      expect(failure_notifications.count).to eq(20)

      previous_notifications = failure_notifications.where.not(post_id: nil)
      expect(previous_notifications.count).to eq(10)
      expect(previous_notifications.ids).to match_array(import_previous_messages.reload.pluck(:notification_id))

      error_notifications = failure_notifications.where.not(error_msg: nil)
      expect(error_notifications.count).to eq(10)
      expect(error_notifications.ids).to match_array(import_error_messages.reload.pluck(:notification_id))

      expect(Notification.pluck(:post_id).compact).to match_array(Post.pluck(:id))
    end
  end

  describe "#create_notifications" do
    let(:author) { create(:user) }
    let(:coauthor) { create(:user) }
    let(:post) { create(:post, user: author, unjoined_authors: [coauthor]) }

    it "works for new post notification", :aggregate_failures do
      subject = "New post by #{author.username}"
      content = "#{author.username} has just posted a new post entitled #{post.subject} in the #{post.board.name} continuity"
      content += " with #{coauthor.username}. #{ScrapePostJob.view_post(post.id)}"
      message = create(:message, sender_id: 0, subject: subject, message: content)
      create_notifications(Message.where(id: message.id), :new_favorite_post)
      notification = Notification.last
      expect(notification.post_id).to eq(post.id)
      expect(message.reload.notification_id).to eq(notification.id)
    end

    it "works for joined post notification", :aggregate_failures do
      subject = "#{coauthor.username} has joined a new thread"
      content = "#{coauthor.username} has just joined the post entitled #{post.subject} with "
      content += "#{author.username}. #{ScrapePostJob.view_post(post.id)}"
      message = create(:message, sender_id: 0, subject: subject, message: content)
      create_notifications(Message.where(id: message.id), :joined_favorite_post)
      notification = Notification.last
      expect(notification.post_id).to eq(post.id)
      expect(message.reload.notification_id).to eq(notification.id)
    end

    it "works for import success notification", :aggregate_failures do
      content = "Your post was successfully imported! #{ScrapePostJob.view_post(post.id)}"
      message = create(:message, sender_id: 0, subject: 'Post import succeeded', message: content)
      create_notifications(Message.where(id: message.id), :import_success)
      notification = Notification.last
      expect(notification.post_id).to eq(post.id)
      expect(message.reload.notification_id).to eq(notification.id)
    end

    it "works for many", :aggregate_failures do
      posts = create_list(:post, 10, unjoined_authors: [create(:user)])
      messages = posts.map do |post|
        subject = "New post by #{post.user.username}"
        content = "#{post.user.username} has just posted a new post entitled #{post.subject} in the #{post.board.name} continuity"
        content += " with #{post.unjoined_authors.first.username}. #{ScrapePostJob.view_post(post.id)}"
        create(:message, sender_id: 0, subject: subject, message: content)
      end
      messages = Message.where(id: messages.map(&:id))
      create_notifications(messages, :new_favorite_post)
      expect(Notification.count).to eq(10)
      notifications = Notification.all
      expect(notifications.pluck(:post_id)).to match_array(posts.map(&:id))
      expect(notifications.select(:notification_type).distinct.pluck(:notification_type)).to eq(['new_favorite_post'])
      expect(messages.reload.pluck(:notification_id)).to match_array(notifications.ids)
    end

    it "does not send emails" do
      notified = create(:user, email_notifications: true)
      subject = "#{coauthor.username} has joined a new thread"
      content = "#{coauthor.username} has just joined the post entitled #{post.subject} with "
      content += "#{author.username}. #{ScrapePostJob.view_post(post.id)}"
      message = create(:message, sender_id: 0, subject: subject, recipient: notified, message: content)

      expect {
        create_notifications(Message.where(id: message.id), :joined_favorite_post)
      }.not_to have_enqueued_email
    end
  end

  describe "#create_import_failure_notification" do
    let(:msg_subject) { 'Post import failed' }
    let(:content) { "The url <a href='#{import_url}'>#{import_url}</a> could not be successfully scraped. " }

    it "finds error message", :aggregate_failures do
      error = "Unrecognized username: wild_pegasus_appeared"
      message = create(:message, subject: msg_subject, message: content + error)
      create_import_failure_notification(message)
      notification = Notification.last
      expect(notification.id).to eq(message.reload.notification_id)
      expect(notification.notification_type).to eq('import_fail')
      expect(notification.post_id).to be_nil
      expect(notification.error_msg).to eq(error)
    end

    it "finds post_id", :aggregate_failures do
      post = create(:post, subject: 'linear b')
      message = create(:message, subject: msg_subject, message: content + "Your post was already imported! #{ScrapePostJob.view_post(post.id)}")
      create_import_failure_notification(message)
      notification = Notification.last
      expect(notification.id).to eq(message.reload.notification_id)
      expect(notification.notification_type).to eq('import_fail')
      expect(notification.post_id).to eq(post.id)
      expect(notification.error_msg).to be_nil
    end
  end

  describe "#setup_notification" do
    let(:message) { create(:message, sender_id: 0) }

    it "works for unread messages", :aggregate_failures do
      notification = setup_notification(message, :new_favorite_post)
      expect(notification.user).to eq(message.recipient)
      expect(notification.notification_type).to eq(:new_favorite_post.to_s)
      expect(notification.unread).to eq(true)
      expect(notification.read_at).to eq(nil)
      expect(notification.created_at).to be_the_same_time_as(message.created_at)
      expect(notification.updated_at).to be_the_same_time_as(message.updated_at)
    end

    it "works for read messages", :aggregate_failures do
      create_time = 1.day.ago
      Timecop.freeze(create_time) { message }
      time = create_time + 12.hours
      Timecop.freeze(time) do
        message.update!(unread: false, read_at: time)
      end
      notification = setup_notification(message, :new_favorite_post)
      expect(notification.user).to eq(message.recipient)
      expect(notification.notification_type).to eq(:new_favorite_post.to_s)
      expect(notification.unread).to eq(false)
      expect(notification.read_at).to be_the_same_time_as(time)
      expect(notification.created_at).to be_the_same_time_as(create_time)
      expect(notification.updated_at).to be_the_same_time_as(time)
    end
  end

  describe "#find_post_id" do
    let(:author) { create(:user) }
    let(:coauthor) { create(:user) }
    let(:post) { create(:post, user: author, unjoined_authors: [coauthor]) }

    it "finds post_id in new post notification" do
      subject = "New post by #{author.username}"
      content = "#{author.username} has just posted a new post entitled #{post.subject} in the #{post.board.name} continuity"
      content += " with #{coauthor.username}. #{ScrapePostJob.view_post(post.id)}"
      message = create(:message, sender_id: 0, subject: subject, message: content)
      post_id = find_post_id(message)
      expect(post_id).to eq(post.id)
    end

    it "finds post_id in joined post notification" do
      subject = "#{coauthor.username} has joined a new thread"
      content = "#{coauthor.username} has just joined the post entitled #{post.subject} with "
      content += "#{author.username}. #{ScrapePostJob.view_post(post.id)}"
      message = create(:message, sender_id: 0, subject: subject, message: content)
      post_id = find_post_id(message)
      expect(post_id).to eq(post.id)
    end

    it "finds post_id in import success notification" do
      content = "Your post was successfully imported! #{ScrapePostJob.view_post(post.id)}"
      message = create(:message, sender_id: 0, subject: 'Post import succeeded', message: content)
      post_id = find_post_id(message)
      expect(post_id).to eq(post.id)
    end
  end
end
