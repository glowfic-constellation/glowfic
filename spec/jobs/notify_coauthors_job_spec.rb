RSpec.describe NotifyCoauthorsJob do
  include ActiveJob::TestHelper

  let(:author) { create(:user) }
  let(:coauthor) { create(:user) }
  let(:unjoined) { create(:user) }
  let(:post) { create(:post, user: author, unjoined_authors: [coauthor, unjoined]) }

  before(:each) { clear_enqueued_jobs }

  context "validations" do
    let(:user) { create(:user) }
    let(:post) { create(:post) }

    it "does nothing with invalid post id" do
      expect {
        NotifyCoauthorsJob.perform_now(-1, user.id)
      }.not_to change { Notification.count }
    end

    it "does nothing with invalid coauthor id" do
      expect {
        NotifyCoauthorsJob.perform_now(post.id, -1)
      }.not_to change { Notification.count }
    end

    it "does nothing if post is private" do
      post.update!(privacy: :private)
      expect {
        NotifyCoauthorsJob.perform_now(post.id, user.id)
      }.not_to change { Notification.count }
    end

    it "does nothing if potential author cannot view post" do
      post.update!(privacy: :access_list)
      expect {
        NotifyCoauthorsJob.perform_now(post.id, user.id)
      }.not_to change { Notification.count }
    end

    it "works" do
      expect {
        NotifyCoauthorsJob.perform_now(post.id, user.id)
      }.to change { Notification.count }.by(1)
      notif = Notification.last
      expect(notif.notification_type).to eq('coauthor_invitation')
      expect(notif.user).to eq(user)
      expect(notif.post).to eq(post)
    end
  end

  context "on post creation" do
    it "does not notify post author" do
      expect { perform_enqueued_jobs { post } }.not_to change { Notification.where(user: author, notification_type: :coauthor_invitation).count }
    end

    it "notifies all listed coauthors" do
      expect { perform_enqueued_jobs { post } }.to change { Notification.where(notification_type: :coauthor_invitation).count }.by(2)
      notifs = Notification.where(notification_type: :coauthor_invitation)
      expect(notifs.pluck(:user_id)).to match_array([coauthor.id, unjoined.id])
      expect(notifs.pluck(:post_id)).to eq([post.id, post.id])
    end

    it "does not notify if post is private" do
      expect {
        perform_enqueued_jobs do
          create(:post, user: author, privacy: :private, unjoined_authors: [coauthor, unjoined])
        end
      }.not_to change { Notification.where(notification_type: :coauthor_invitation).count }
    end

    it "only notifies for authors with access" do
      expect {
        perform_enqueued_jobs do
          create(:post, user: author, privacy: :access_list, viewers: [coauthor], unjoined_authors: [coauthor, unjoined])
        end
      }.to change { Notification.where(notification_type: :coauthor_invitation).count }.by(1)
      notif = Notification.find_by(notification_type: :coauthor_invitation)
      expect(notif.user).to eq(coauthor)
    end

    it "does not queue for imported posts" do
      create(:post, user: author, unjoined_authors: [coauthor, unjoined], is_import: true)
      expect(NotifyCoauthorsJob).not_to have_been_enqueued
    end
  end

  context "on author add" do
    let(:new) { create(:user) }

    before(:each) { create(:reply, post: post, user: coauthor) }

    it "works" do
      expect {
        perform_enqueued_jobs do
          post.authors << new
        end
      }.to change { Notification.where(notification_type: :coauthor_invitation).count }.by(1)
      notif = Notification.find_by(notification_type: :coauthor_invitation)
      expect(notif.user).to eq(new)
    end

    it "does not notify if post is private" do
      post.update!(privacy: :private)
      expect {
        perform_enqueued_jobs do
          post.authors << new
        end
      }.not_to change { Notification.where(notification_type: :coauthor_invitation).count }
    end

    it "does not notify if author does not have access" do
      post.update!(privacy: :access_list, viewers: [coauthor, unjoined])
      expect {
        perform_enqueued_jobs do
          post.authors << new
        end
      }.not_to change { Notification.where(notification_type: :coauthor_invitation).count }
    end
  end

  context "on reply" do
    let(:replier) { create(:user) }

    before(:each) { create(:reply, post: post, user: coauthor) }

    it "does not notify" do
      expect {
        perform_enqueued_jobs do
          create(:reply, user: replier, post: post)
        end
      }.not_to change { Notification.where(notification_type: :coauthor_invitation).count }
    end

    it "does not queue on imported posts" do
      clear_enqueued_jobs
      create(:reply, user: replier, post: post, is_import: true)
      expect(NotifyCoauthorsJob).not_to have_been_enqueued
    end
  end
end
