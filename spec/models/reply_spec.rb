RSpec.describe Reply do
  describe "#has_icons?" do
    let(:user) { create(:user) }

    context "without character" do
      let(:reply) { create(:reply, user: user) }

      it "is true with avatar" do
        icon = create(:icon, user: user)
        user.update!(avatar: icon)
        user.reload

        expect(reply.character).to be_nil
        expect(reply.has_icons?).to eq(true)
      end

      it "is false without avatar" do
        expect(reply.character).to be_nil
        expect(reply.has_icons?).not_to eq(true)
      end
    end

    context "with character" do
      let(:character) { create(:character, user: user) }
      let(:reply) { create(:reply, user: user, character: character) }

      it "is true with default icon" do
        icon = create(:icon, user: user)
        character.update!(default_icon: icon)
        expect(reply.has_icons?).to eq(true)
      end

      it "is false without galleries" do
        expect(reply.has_icons?).not_to eq(true)
      end

      it "is true with icons in galleries" do
        gallery = create(:gallery, user: user)
        gallery.icons << create(:icon, user: user)
        character.galleries << gallery
        expect(reply.has_icons?).to eq(true)
      end

      it "is false without icons in galleries" do
        character.galleries << create(:gallery, user: user)
        expect(reply.has_icons?).not_to eq(true)
      end
    end
  end

  describe "#notify_other_authors" do
    let(:notified_user) { create(:user, email_notifications: true) }
    let(:post) { create(:post, user: notified_user) }
    let(:another_notified_user) { create(:user, email_notifications: true) }

    before(:each) { ResqueSpec.reset! }

    it "does nothing if skip_notify is set" do
      create(:reply, post: post, skip_notify: true)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does nothing if the previous reply was yours" do
      reply = create(:reply, post: post, skip_notify: true)
      create(:reply, post: post, user: reply.user)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does nothing if the post was yours on the first reply" do
      create(:reply, post: post, user: notified_user)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does not send to authors with notifications off" do
      post = create(:post, user: create(:user, email_notifications: false))
      create(:reply, post: post)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does not send to emailless users" do
      notified_user.update_columns(email: nil) # rubocop:disable Rails/SkipsModelValidations
      create(:reply, post: post)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does not send to users who have opted out of owed" do
      post.opt_out_of_owed(notified_user)
      create(:reply, post: post)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "sends to all other active authors if previous reply wasn't yours" do
      create(:reply, user: another_notified_user, post: post, skip_notify: true)

      reply = create(:reply, post: post)
      expect(UserMailer).to have_queue_size_of(2)
      expect(UserMailer).to have_queued(:post_has_new_reply, [notified_user.id, reply.id])
      expect(UserMailer).to have_queued(:post_has_new_reply, [another_notified_user.id, reply.id])
    end

    it "sends if the post was yours but previous reply wasn't" do
      create(:reply, user: another_notified_user, post: post, skip_notify: true)

      reply = create(:reply, post: post, user: notified_user)
      expect(UserMailer).to have_queue_size_of(1)
      expect(UserMailer).to have_queued(:post_has_new_reply, [another_notified_user.id, reply.id])
    end
  end

  describe "authors interactions" do
    it "does not update can_owe upon creating a reply" do
      post = create(:post)
      reply = create(:reply, post: post)

      expect(post.author_for(reply.user).can_owe).to be(true)
      create(:reply, user: reply.user, post: post)
      expect(post.author_for(reply.user).can_owe).to be(true)

      author = post.author_for(reply.user)
      author.can_owe = false
      author.save!

      expect(post.author_for(reply.user).can_owe).to be(false)
      create(:reply, user: reply.user, post: post)
      expect(post.author_for(reply.user).can_owe).to be(false)
    end
  end

  describe ".ordered" do
    let(:post) { create(:post) }

    it "orders replies" do
      replies = create_list(:reply, 3, post: post)
      expect(post.replies.ordered).to eq(replies)
    end

    it "orders replies by reply_order, not created_at" do
      first_reply = Timecop.freeze(post.created_at + 1.second) { create(:reply, post: post) }
      second_reply = Timecop.freeze(first_reply.created_at - 5.seconds) { create(:reply, post: post) }
      third_reply = Timecop.freeze(first_reply.created_at - 3.seconds) { create(:reply, post: post) }
      expect(post.replies.ordered).not_to eq(post.replies.order(:created_at))
      expect(post.replies.order(:created_at)).to eq([second_reply, third_reply, first_reply])
      expect(post.replies.ordered).to eq([first_reply, second_reply, third_reply])
    end

    it "orders replies by reply order not ID" do
      replies = create_list(:reply, 3, post: post)
      replies[1].update_columns(reply_order: 2) # rubocop:disable Rails/SkipsModelValidations
      replies[2].update_columns(reply_order: 1) # rubocop:disable Rails/SkipsModelValidations
      expect(post.replies.ordered).to eq([replies[0], replies[2], replies[1]])
    end
  end

  describe "#destroy_subsequent_replies" do
    it "works" do
      post = create(:post)
      replies = create_list(:reply, 2, post: post)
      reply = create(:reply, post: post)
      create_list(:reply, 2, post: post)
      expect { reply.send(:destroy_subsequent_replies) }.to change { Reply.count }.by(-3)
      expect(Reply.where(id: replies.map(&:id)).count).to eq(2)
      expect(Reply.find_by(id: reply.id)).not_to be_present
      expect(post.reload.last_reply_id).to eq(replies[1].id)
    end
  end

  describe "#update_flat_post" do
    include ActiveJob::TestHelper

    let(:user) { create(:user) }
    let(:reply) { create(:reply, user: user, icon: create(:icon, user: user), character: create(:character, user: user)) }

    before(:each) do
      perform_enqueued_jobs { reply }
    end

    it "queues on update" do
      reply.update!(content: 'new text')
      expect(GenerateFlatPostJob).to have_been_enqueued.with(reply.post_id).on_queue('high')
    end

    it "queues on deletion" do
      reply.destroy!
      expect(GenerateFlatPostJob).to have_been_enqueued.with(reply.post_id).on_queue('high')
    end

    it "does not queue on update if 'skip_regenerate' is set" do
      reply.skip_regenerate = true
      reply.update!(content: 'new text')
      expect(GenerateFlatPostJob).not_to have_been_enqueued.with(reply.post_id)
    end

    it "does not queue on destroy if 'skip_regenerate' is set" do
      reply.skip_regenerate = true
      reply.destroy!
      expect(GenerateFlatPostJob).not_to have_been_enqueued.with(reply.post_id)
    end
  end

  describe "Writable" do
    describe "#name" do
      let(:user) { create(:user) }
      let(:character) { create(:character, user: user) }
      let(:reply) { create(:reply, character: character, user: user) }

      it "works without alias" do
        expect(reply.name).to eq(character.name)
      end

      it "works with alias" do
        calias = create(:alias, character: character)
        reply.update!(character_alias: calias)
        expect(reply.name).to eq(calias.name)
      end
    end
  end
end
