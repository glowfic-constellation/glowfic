require "spec_helper"

RSpec.describe Reply do
  describe "#has_icons?" do
    let(:user) { create(:user) }

    context "without character" do
      let(:reply) { create(:reply, user: user) }

      it "is true with avatar" do
        icon = create(:icon, user: user)
        user.update_attributes(avatar: icon)
        user.reload

        expect(reply.character).to be_nil
        expect(reply.has_icons?).to be_true
      end

      it "is false without avatar" do
        expect(reply.character).to be_nil
        expect(reply.has_icons?).not_to be_true
      end
    end

    context "with character" do
      let(:character) { create(:character, user: user) }
      let(:reply) { create(:reply, user: user, character: character) }

      it "is true with default icon" do
        icon = create(:icon, user: user)
        character.update_attributes(default_icon: icon)
        expect(reply.has_icons?).to be_true
      end

      it "is false without galleries" do
        expect(reply.has_icons?).not_to be_true
      end

      it "is true with icons in galleries" do
        gallery = create(:gallery, user: user)
        gallery.icons << create(:icon, user: user)
        character.galleries << gallery
        expect(reply.has_icons?).to be_true
      end

      it "is false without icons in galleries" do
        character.galleries << create(:gallery, user: user)
        expect(reply.has_icons?).not_to be_true
      end
    end
  end

  describe "#notify_other_authors" do
    before(:each) do ResqueSpec.reset! end

    it "does nothing if skip_notify is set" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

      create(:reply, post: post, skip_notify: true)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does nothing if the previous reply was yours" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

      reply = create(:reply, post: post, skip_notify: true)

      create(:reply, post: post, user: reply.user)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does nothing if the post was yours on the first reply" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

      create(:reply, post: post, user: notified_user)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "sends to all other active authors if previous reply wasn't yours" do
      post = create(:post)
      expect(post.user.email_notifications).not_to be_true

      user = create(:user)
      user.update_attribute('email', nil)
      create(:reply, user: user, post: post, skip_notify: true)

      notified_user = create(:user, email_notifications: true)
      create(:reply, user: notified_user, post: post, skip_notify: true)

      another_notified_user = create(:user, email_notifications: true)
      create(:reply, user: another_notified_user, post: post, skip_notify: true)

      reply = create(:reply, post: post)
      expect(UserMailer).to have_queue_size_of(2)
      expect(UserMailer).to have_queued(:post_has_new_reply, [notified_user.id, reply.id])
      expect(UserMailer).to have_queued(:post_has_new_reply, [another_notified_user.id, reply.id])
    end

    it "sends if the post was yours but previous reply wasn't" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

      another_notified_user = create(:user, email_notifications: true)
      create(:reply, user: another_notified_user, post: post, skip_notify: true)

      reply = create(:reply, post: post, user: notified_user)
      expect(UserMailer).to have_queue_size_of(1)
      expect(UserMailer).to have_queued(:post_has_new_reply, [another_notified_user.id, reply.id])
    end
  end
end
