require "spec_helper"

RSpec.describe Reply do
  describe "view cache" do
    before(:each) do
      @reply = create(:reply, with_icon: true, with_character: true)
      @key = @reply.send(:view_cache_key)
      Rails.cache.write(@key, 'test')
    end

    it "should expire when the reply is updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.content = 'something new'
      @reply.save
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should expire when the reply is destroyed" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.destroy
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should expire when the character is updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.character.name = 'something new'
      @reply.character.save
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should only expire when relevant character fields are updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.character.template = create(:template)
      @reply.character.save
      expect(Rails.cache.read(@key)).to eq('test')
    end

    it "should expire when the icon is updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.icon.keyword = 'something new'
      @reply.icon.save
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should only expire when relevant icon fields are updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.icon.has_gallery = !@reply.icon.has_gallery
      @reply.icon.save
      expect(Rails.cache.read(@key)).to eq('test')
    end

    it "should expire when the user is updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.user.username = 'something new'
      @reply.user.save
      expect(Rails.cache.read(@key)).to be_nil
    end

    it "should only expire when relevant user fields are updated" do
      expect(Rails.cache.read(@key)).to eq('test')
      @reply.user.moiety = 'something new'
      @reply.user.save
      expect(Rails.cache.read(@key)).to eq('test')
    end
  end

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
    it "does nothing if skip_notify is set" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

      ActionMailer::Base.deliveries.clear
      create(:reply, post: post, skip_notify: true)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it "does nothing if the previous reply was yours" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

      reply = create(:reply, post: post, skip_notify: true)

      ActionMailer::Base.deliveries.clear
      create(:reply, post: post, user: reply.user)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it "does nothing if the post was yours on the first reply" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

      ActionMailer::Base.deliveries.clear
      create(:reply, post: post, user: notified_user)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
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

      ActionMailer::Base.deliveries.clear
      create(:reply, post: post)
      expect(ActionMailer::Base.deliveries.count).to eq(2)
    end

    it "sends if the post was yours but previous reply wasn't" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

      another_notified_user = create(:user, email_notifications: true)
      create(:reply, user: another_notified_user, post: post, skip_notify: true)

      ActionMailer::Base.deliveries.clear
      create(:reply, post: post, user: notified_user)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end
end
