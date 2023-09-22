RSpec.describe Reply do
  describe "validations" do
    describe "#author_can_write_in_post" do
      let(:creator) { create(:user) }
      let(:board) { create(:board, writers: [creator], authors_locked: true) }
      let(:post) { create(:post, user: creator, board: board, authors_locked: true) }
      let(:user) { create(:user) }

      it "requires board access" do
        post.update!(authors_locked: false)
        expect(user.writes_in?(board)).to eq(false)
        reply = build(:reply, post: post, user: user)
        expect(reply).not_to be_valid
      end

      it "requires post access" do
        board.update!(cameos: [user])
        expect(post.author_for(user)).to be_nil
        reply = build(:reply, post: post, user: user)
        expect(reply).not_to be_valid
      end

      it "works" do
        board.update!(cameos: [user])
        post.update!(unjoined_authors: [user])
        reply = build(:reply, post: post, user: user)
        expect(reply).to be_valid
      end
    end
  end

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
    before(:each) { ResqueSpec.reset! }

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

    it "does not send to authors with notifications off" do
      post = create(:post)
      expect(post.user.email_notifications).not_to eq(true)
      create(:reply, post: post)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does not send to emailless users" do
      user = create(:user)
      user.update_columns(email: nil) # rubocop:disable Rails/SkipsModelValidations
      post = create(:post, user: user)
      create(:reply, post: post)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does not send to users who have opted out of owed" do
      user = create(:user, email_notifications: true)
      post = create(:post, user: user)
      post.opt_out_of_owed(user)
      create(:reply, post: post)
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "sends to all other active authors if previous reply wasn't yours" do
      notified_user = create(:user, email_notifications: true)
      post = create(:post, user: notified_user)

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
      first_reply = create(:reply, post: post)
      second_reply = create(:reply, post: post)
      third_reply = create(:reply, post: post)
      expect(post.replies.ordered).to eq([first_reply, second_reply, third_reply])
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
      first_reply = create(:reply, post: post)
      second_reply = create(:reply, post: post)
      third_reply = create(:reply, post: post)
      second_reply.update_columns(reply_order: 2) # rubocop:disable Rails/SkipsModelValidations
      third_reply.update_columns(reply_order: 1) # rubocop:disable Rails/SkipsModelValidations
      expect(post.replies.ordered).to eq([first_reply, third_reply, second_reply])
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

  describe "#post_page" do
    let(:post) { create(:post) }
    let(:reply) { create(:reply, post: post) }

    it "works with default per_page" do
      create_list(:reply, 30, post: post)
      expect(reply.post_page).to eq(2)
    end

    it "works with zero per_page" do
      expect(reply.post_page(0)).to eq(1)
    end

    it "works with per_page greater than reply number" do
      create_list(:reply, 5, post: post)
      expect(reply.post_page(10)).to eq(1)
    end
  end
end
