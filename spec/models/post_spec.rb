require "spec_helper"
require "support/shared_examples_for_taggable"

RSpec.describe Post do
  it "should have the right timestamps" do
    # creation
    post = create(:post)
    reply = reply2 = nil # to handle variable scoping issues with Timecop
    expect(post.edited_at).to be_the_same_time_as(post.created_at)
    expect(post.tagged_at).to be_the_same_time_as(post.created_at)
    old_edited_at = post.edited_at
    old_tagged_at = post.tagged_at

    # edited with no replies updates edit and tag
    Timecop.freeze(old_tagged_at + 1.hour) do
      post.content = 'new content'
      post.save
      expect(post.tagged_at).to be_the_same_time_as(post.edited_at)
      expect(post.tagged_at).to be > post.created_at
      old_edited_at = post.edited_at
      old_tagged_at = post.tagged_at
    end

    # invalid edit field with no replies updates nothing
    Timecop.freeze(old_tagged_at + 2.hours) do
      post.section_order = post.section_order + 1
      post.save
      expect(post.tagged_at).to be_the_same_time_as(old_tagged_at)
      expect(post.edited_at).to be_the_same_time_as(old_edited_at)
    end

    # reply created updates tag but not edit
    Timecop.freeze(old_tagged_at + 3.hours) do
      reply = create(:reply, post: post)
      post.reload
      expect(post.tagged_at).to be_the_same_time_as(reply.created_at)
      expect(post.edited_at).to be_the_same_time_as(old_edited_at)
      expect(post.tagged_at).to be > post.edited_at
      old_tagged_at = post.tagged_at
    end

    # edited with replies updates edit but not tag
    Timecop.freeze(old_tagged_at + 4.hours) do
      post.content = 'newer content'
      post.save
      expect(post.tagged_at).to be_the_same_time_as(old_tagged_at)
      expect(post.edited_at).to be > old_edited_at
      old_edited_at = post.edited_at
    end

    # edited status with replies updates edit and tag
    Timecop.freeze(old_tagged_at + 5.hours) do
      post.status = Post::STATUS_COMPLETE
      post.save
      expect(post.tagged_at).to be > old_tagged_at
      expect(post.edited_at).to be > old_edited_at
      old_edited_at = post.edited_at
      old_tagged_at = post.tagged_at
    end

    # invalid edit field with replies updates nothing
    Timecop.freeze(old_tagged_at + 6.hours) do
      post.section_order = post.section_order + 1
      post.save
      expect(post.tagged_at).to be_the_same_time_as(old_tagged_at)
      expect(post.edited_at).to be_the_same_time_as(old_edited_at)
    end

    # second reply created updates tag but not edit
    Timecop.freeze(old_tagged_at + 7.hours) do
      reply2 = create(:reply, post: post)
      post.reload
      expect(post.tagged_at).to be_the_same_time_as(reply2.created_at)
      expect(post.updated_at).to be >= reply2.created_at
      expect(post.tagged_at).to be > post.edited_at
      old_tagged_at = post.tagged_at
      old_edited_at = post.edited_at
    end

    # first reply updated updates nothing
    Timecop.freeze(old_tagged_at + 8.hours) do
      reply.content = 'new content'
      reply.skip_post_update = true unless reply.post.last_reply_id == reply.id
      reply.save
      post.reload
      expect(post.tagged_at).to be_the_same_time_as(old_tagged_at) # BAD
      expect(post.edited_at).to be_the_same_time_as(old_edited_at)
    end

    # second reply updated updates tag but not edit
    Timecop.freeze(old_tagged_at + 9.hours) do
      reply2.content = 'new content'
      reply2.skip_post_update = true unless reply2.post.last_reply_id == reply2.id
      reply2.save
      post.reload
      expect(post.tagged_at).to be_the_same_time_as(reply2.updated_at)
      expect(post.edited_at).to be_the_same_time_as(old_edited_at)
    end
  end

  describe "#destroy" do
    it "should delete views" do
      post = create(:post)
      user = create(:user)
      expect(PostView.count).to be_zero
      post.mark_read(user)
      expect(PostView.count).not_to be_zero
      post.destroy
      expect(PostView.count).to be_zero
    end
  end

  describe "#edited_at" do
    it "should update when a field is changed" do
      post = create(:post)
      expect(post.edited_at).to eq(post.created_at)
      post.content = 'new content now'
      post.save
      expect(post.edited_at).not_to eq(post.created_at)
    end

    it "should update when multiple fields are changed" do
      post = create(:post)
      expect(post.edited_at).to eq(post.created_at)
      post.content = 'new content now'
      post.description = 'description'
      post.save
      expect(post.edited_at).not_to eq(post.created_at)
    end

    it "should not update when skip is set" do
      post = create(:post)
      expect(post.edited_at).to eq(post.created_at)
      post.skip_edited = true
      post.touch
      expect(post.edited_at).to eq(post.created_at)
    end

    it "should not update when a reply is made" do
      post = create(:post)
      expect(post.edited_at).to eq(post.created_at)
      create(:reply, post: post, user: post.user)
      expect(post.edited_at).to eq(post.created_at)
    end
  end

  describe "#section_order" do
    it "should be set on create" do
      board = create(:board)
      5.times do |i|
        post = create(:post, board_id: board.id)
        expect(post.section_order).to eq(i)
      end
    end

    it "should be set in its section on create" do
      board = create(:board)
      section = create(:board_section, board_id: board.id)
      5.times do |i|
        post = create(:post, board_id: board.id, section_id: section.id)
        expect(post.section_order).to eq(i)
      end
    end

    it "should handle mix and match section/no section creates" do
      board = create(:board)
      section = create(:board_section, board_id: board.id)
      expect(section.section_order).to eq(0)
      5.times do |i|
        post = create(:post, board_id: board.id, section_id: section.id)
        expect(post.section_order).to eq(i)
      end
      post = create(:post, board_id: board.id)
      expect(post.section_order).to eq(0)
      post = create(:post, board_id: board.id)
      expect(post.section_order).to eq(1)
      post = create(:post, board_id: board.id, section_id: section.id)
      expect(post.section_order).to eq(5)
      section = create(:board_section, board_id: board.id)
      expect(section.section_order).to eq(1)
      post = create(:post, board_id: board.id)
      expect(post.section_order).to eq(2)

      board.board_sections.order('section_order asc').each_with_index do |section, i|
        expect(section.section_order).to eq(i)
      end

      board.posts.where(section_id: nil).order('section_order asc').each_with_index do |section, i|
        expect(section.section_order).to eq(i)
      end

      section.posts.order('section_order asc').each_with_index do |section, i|
        expect(section.section_order).to eq(i)
      end
    end

    it "should update when section is changed" do
      board = create(:board)
      section = create(:board_section, board_id: board.id)
      post = create(:post, board_id: board.id, section_id: section.id)
      expect(post.section_order).to eq(0)
      post = create(:post, board_id: board.id, section_id: section.id)
      expect(post.section_order).to eq(1)
      section = create(:board_section, board_id: board.id)
      post.section_id = section.id
      post.save
      post.reload
      expect(post.section_order).to eq(0)
    end

    it "should update when board is changed" do
      board = create(:board)
      create(:post, board_id: board.id)
      create(:post, board_id: board.id)
      post = create(:post, board_id: board.id)
      expect(post.section_order).to eq(2)
      board = create(:board)
      post.board = board
      post.save
      post.reload
      expect(post.section_order).to eq(0)
    end

    it "should not increment on non-section update" do
      board = create(:board)
      post = create(:post, board_id: board.id)
      expect(post.section_order).to eq(0)
      create(:post, board_id: board.id)
      create(:post, board_id: board.id)
      post.update_attributes(content: 'new content')
      post.reload
      expect(post.section_order).to eq(0)
    end

    it "should reorder upon deletion" do
      board = create(:board)
      board.coauthors << create(:user)
      post0 = create(:post, board_id: board.id, user: board.creator)
      expect(post0.section_order).to eq(0)
      post1 = create(:post, board_id: board.id, user: board.creator)
      expect(post1.section_order).to eq(1)
      post2 = create(:post, board_id: board.id, user: board.creator)
      expect(post2.section_order).to eq(2)
      post3 = create(:post, board_id: board.id, user: board.creator)
      expect(post3.section_order).to eq(3)
      post1.destroy
      expect(post0.reload.section_order).to eq(0)
      expect(post2.reload.section_order).to eq(1)
      expect(post3.reload.section_order).to eq(2)
    end

    it "should reorder upon board change" do
      board = create(:board)
      board.coauthors << create(:user)
      post0 = create(:post, board_id: board.id, user: board.creator)
      expect(post0.section_order).to eq(0)
      post1 = create(:post, board_id: board.id, user: board.creator)
      expect(post1.section_order).to eq(1)
      post2 = create(:post, board_id: board.id, user: board.creator)
      expect(post2.section_order).to eq(2)
      post3 = create(:post, board_id: board.id, user: board.creator)
      expect(post3.section_order).to eq(3)
      post1.board = create(:board)
      post1.save
      expect(post0.reload.section_order).to eq(0)
      expect(post2.reload.section_order).to eq(1)
      expect(post3.reload.section_order).to eq(2)
    end

    it "should autofill correctly upon board change" do
      board = create(:board)
      board2 = create(:board)
      post0 = create(:post, board_id: board.id)
      post1 = create(:post, board_id: board.id)
      post2 = create(:post, board_id: board2.id)
      expect(post0.section_order).to eq(0)
      expect(post1.section_order).to eq(1)
      expect(post2.section_order).to eq(0)

      post2.board_id = board.id
      post2.skip_edited = true
      post2.save

      expect(post0.section_order).to eq(0)
      expect(post1.section_order).to eq(1)
      expect(post2.section_order).to eq(2)
    end

    it "should autofill correctly upon board change with mix" do
      board = create(:board)
      board2 = create(:board)

      section1 = create(:board_section, board_id: board.id)
      post = create(:post, board_id: board.id)
      section2 = create(:board_section, board_id: board.id)

      expect(section1.section_order).to eq(0)
      expect(post.section_order).to eq(0)
      expect(section2.section_order).to eq(1)

      post.board_id = board2.id
      post.skip_edited = true
      post.save

      expect(post.reload.section_order).to eq(0)
      expect(section1.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
    end
  end

  describe "#has_icons?" do
    let(:user) { create(:user) }

    context "without character" do
      let(:post) { create(:post, user: user) }

      it "is true with avatar" do
        icon = create(:icon, user: user)
        user.update_attributes(avatar: icon)
        user.reload

        expect(post.character).to be_nil
        expect(post.has_icons?).to eq(true)
      end

      it "is false without avatar" do
        expect(post.character).to be_nil
        expect(post.has_icons?).not_to eq(true)
      end
    end

    context "with character" do
      let(:character) { create(:character, user: user) }
      let(:post) { create(:post, user: user, character: character) }

      it "is true with default icon" do
        icon = create(:icon, user: user)
        character.update_attributes(default_icon: icon)
        expect(post.has_icons?).to eq(true)
      end

      it "is false without galleries" do
        expect(post.has_icons?).not_to eq(true)
      end

      it "is true with icons in galleries" do
        gallery = create(:gallery, user: user)
        gallery.icons << create(:icon, user: user)
        character.galleries << gallery
        expect(post.has_icons?).to eq(true)
      end

      it "is false without icons in galleries" do
        character.galleries << create(:gallery, user: user)
        expect(post.has_icons?).not_to eq(true)
      end
    end
  end

  describe "validations" do
    it "requires user" do
      post = create(:post)
      expect(post.valid?).to eq(true)
      post.user = nil
      expect(post.valid?).not_to eq(true)
    end

    it "requires user's character" do
      post = create(:post)
      character = create(:character)
      expect(post.user).not_to eq(character.user)
      post.character = character
      expect(post.valid?).not_to eq(true)
    end

    it "requires user's icon" do
      post = create(:post)
      icon = create(:icon)
      expect(post.user).not_to eq(icon.user)
      post.icon = icon
      expect(post.valid?).not_to eq(true)
    end

    it "requires board the user can access" do
      board = create(:board)
      board.coauthors << create(:user)
      post = create(:post)
      expect(post.valid?).to eq(true)
      post.board = board
      expect(post.valid?).not_to eq(true)
    end

    it "requires board section matching board" do
      post = create(:post)
      expect(post.valid?).to eq(true)
      post.section = create(:board_section)
      expect(post.valid?).not_to eq(true)
    end

    it "should allow blank content" do
      post = create(:post, content: '')
      expect(post.id).not_to be_nil
    end
  end

  describe "#word_count" do
    it "guesses correctly with replies" do
      post = create(:post, content: 'one two three four five')
      create(:reply, post: post, content: 'six seven')
      create(:reply, post: post, content: 'eight')
      expect(post.word_count).to eq(5)
      expect(post.total_word_count).to eq(8)
    end

    it "guesses correctly without replies" do
      post = create(:post, content: 'one two three four five')
      expect(post.word_count).to eq(5)
      expect(post.total_word_count).to eq(5)
    end

    it "orders users correctly" do
      post = create(:post, content: 'one')
      two = create(:reply, post: post, content: 'two two')
      three = create(:reply, post: post, content: 'three three three')
      post = Post.find(post.id) # authors get cached
      counts = post.author_word_counts
      expect(counts[0][0]).to eq(three.user.username)
      expect(counts[0][1]).to eq(3)
      expect(counts[1][0]).to eq(two.user.username)
      expect(counts[1][1]).to eq(2)
      expect(counts[2][0]).to eq(post.user.username)
      expect(counts[2][1]).to eq(1)
    end

    it "handles never posted users" do
      post = create(:post)
      expect(post.word_count_for(create(:user))).to eq(0)
    end

    it "handles posted no replies" do
      post = create(:post, content: 'a a a a')
      expect(post.word_count_for(post.user)).to eq(4)
    end

    it "handles posted + replies" do
      post = create(:post, content: 'a a a a')
      create(:reply, user: post.user, post: post, content: 'a a a')
      create(:reply, post: post, user: post.user, content: 'a a')
      create(:reply, post: post, content: 'c')
      expect(post.word_count_for(post.user)).to eq(9)
    end

    it "handles only replies" do
      post = create(:post, content: 'a a a a')
      reply = create(:reply, post: post, content: 'b b b')
      create(:reply, post: post, user: reply.user, content: 'b b')
      create(:reply, post: post, content: 'c')
      expect(post.word_count_for(reply.user)).to eq(5)
    end
  end

  describe "#visible_to?" do
    context "public" do
      let(:post) { create(:post, privacy: Concealable::PUBLIC) }

      it "is visible to poster" do
        expect(post).to be_visible_to(post.user)
      end

      it "is visible to author" do
        reply = create(:reply, post: post)
        expect(post).to be_visible_to(reply.user)
      end

      it "is visible to site user" do
        expect(post).to be_visible_to(create(:user))
      end

      it "is visible to logged out users" do
        expect(post).to be_visible_to(nil)
      end
    end

    context "private" do
      let(:post) { create(:post, privacy: Concealable::PRIVATE) }

      it "is visible to poster" do
        expect(post).to be_visible_to(post.user)
      end

      it "is not visible to author" do # TODO seems wrong
        reply = create(:reply, post: post)
        expect(post).not_to be_visible_to(reply.user)
      end

      it "is not visible to site user" do
        expect(post).not_to be_visible_to(create(:user))
      end

      it "is not visible to logged out users" do
        expect(post).not_to be_visible_to(nil)
      end
    end

    context "list" do
      let(:post) { create(:post, privacy: Concealable::ACCESS_LIST) }

      it "is visible to poster" do
        expect(post).to be_visible_to(post.user)
      end

      it "is visible to list user" do
        user = create(:user)
        post.viewers << user
        expect(post.reload).to be_visible_to(user)
      end

      it "is not visible to author" do # TODO seems wrong
        reply = create(:reply, post: post)
        expect(post).not_to be_visible_to(reply.user)
      end

      it "is not visible to site user" do
        expect(post).not_to be_visible_to(create(:user))
      end

      it "is not visible to logged out users" do
        expect(post).not_to be_visible_to(nil)
      end
    end

    context "registered" do
      let(:post) { create(:post, privacy: Concealable::REGISTERED) }
      it "is visible to poster" do
        expect(post).to be_visible_to(post.user)
      end

      it "is visible to author" do
        reply = create(:reply, post: post)
        expect(post).to be_visible_to(reply.user)
      end

      it "is visible to arbitrary site user" do
        expect(post).to be_visible_to(create(:user))
      end

      it "is not visible to logged out (nil) users" do
        expect(post).not_to be_visible_to(nil)
      end
    end
  end

  describe "#first_unread_for" do
    it "uses instance variable if set" do
      post = create(:post)
      post.instance_variable_set('@first_unread', 3)
      expect(post).not_to receive(:last_read)
      expect(post.first_unread_for(nil)).to eq(3)
    end

    it "uses itself if not yet viewed" do
      post = create(:post)
      create(:reply, post: post)
      expect(post.first_unread_for(post.user)).to eq(post)
    end

    context "with replies" do
      let(:post) { create(:post) }
      before(:each) { create(:reply, post: post) }

      it "uses nil if full post viewed" do
        post.mark_read(post.user)
        expect(post.first_unread_for(post.user)).to be_nil
      end

      it "uses nil if full continuity viewed" do
        post.board.mark_read(post.user)
        expect(post.first_unread_for(post.user)).to be_nil
      end

      it "uses reply created after viewed_at if partially viewed" do
        post.mark_read(post.user)
        unread = create(:reply, post: post)
        expect(post.first_unread_for(post.user)).to eq(unread)
      end

      it "handles status changes" do
        post.mark_read(post.user)
        unread = create(:reply, post: post)
        expect(post.first_unread_for(post.user)).to eq(unread)
        expect(post.read_time_for(post.replies)).to be_the_same_time_as(unread.created_at)

        Timecop.freeze(unread.created_at + 1.day) do
          post.status = Post::STATUS_COMPLETE
          post.save

          post.description = 'new description to add another audit'
          post.save
        end

        post.reload
        expect(post.edited_at).to be > unread.updated_at
        expect(post.first_unread_for(post.user)).to eq(unread)
        expect(post.read_time_for(post.replies)).to be_the_same_time_as(post.edited_at)
      end
    end

    context "without replies" do
      let(:post) { create(:post) }

      it "uses nil if post viewed" do
        post.mark_read(post.user)
        expect(post.first_unread_for(post.user)).to be_nil
      end

      it "uses nil if continuity viewed" do
        post.board.mark_read(post.user)
        expect(post.first_unread_for(post.user)).to be_nil
      end
    end
  end

  describe "#recent_characters_for" do
    it "is blank if user has not responded to post" do
      post = create(:post)
      create(:reply, post: post)
      user = create(:user)
      expect(post.authors).not_to include(user)
      expect(post.recent_characters_for(user, 4)).to be_blank
    end

    it "includes the post character if relevant" do
      char = create(:character)
      post = create(:post, user: char.user, character: char)
      expect(post.recent_characters_for(char.user, 4)).to match_array([char])
    end

    it "only includes characters for specified author" do
      other_char1 = create(:character)
      other_char2 = create(:character)
      post = create(:post, user: other_char1.user, character: other_char1)
      create(:reply, post: post, user: other_char2.user, character: other_char2)
      reply = create(:reply, character_id: nil)
      expect(post.recent_characters_for(reply.user, 4)).to be_blank
    end

    it "returns correctly ordered information without duplicates" do
      user = create(:user)
      char = create(:character, user: user)
      post = create(:post, user: user, character: char)
      reply_char = create(:character, user: user)
      reply_char2 = create(:character, user: user)
      create(:reply, post: post, user: user, character: reply_char)
      create(:reply, post: post, user: user, character: reply_char)
      create(:reply, post: post, user: user, character: char)
      create(:reply, post: post, user: user, character: reply_char2)
      coauthor = create(:user)
      cochar = create(:character, user: coauthor)
      create(:reply, post: post, user: coauthor, character: cochar)

      other_char = create(:character, user: user)
      other_post = create(:post, user: user, character: other_char)
      create(:reply, post: other_post, user: user, character: other_char)
      create(:reply, post: post, user: coauthor, character: cochar)

      expect(post.recent_characters_for(user, 4)).to eq([reply_char2, char, reply_char])
    end

    it "limits the amount of returned data" do
      user = create(:user)
      characters = Array.new(10) { create(:character, user: user) }
      post_char = create(:character, user: user)
      post = create(:post, user: user, character: post_char)
      characters.each do |char|
        create(:reply, user: user, post: post, character: char)
      end

      expect(post.recent_characters_for(user, 9)).to eq(characters[-9..-1].reverse)
      expect(post.recent_characters_for(user, 10)).to eq(characters.reverse)
    end
  end

  describe "#reset_warnings" do
    let(:post) { create(:post) }
    let(:warning) { create(:content_warning) }
    let(:user) { create(:user) }
    before(:each) do
      post.content_warnings << warning
      post.hide_warnings_for(user)
      expect(post).not_to be_show_warnings_for(user)
    end

    it "does not reset on update" do
      post.content = 'new content'
      post.save
      expect(post.reload).not_to be_show_warnings_for(user)
    end

    it "does not reset on remove" do
      post.content_warnings.delete(warning)
      expect(post.reload).not_to be_show_warnings_for(user)
    end

    it "resets with new warning without changing read time" do
      at_time = 3.days.ago
      post.mark_read(user, at_time, true)
      post.content_warnings << create(:content_warning)
      expect(post.reload).to be_show_warnings_for(user)
      expect(post.last_read(user)).to be_the_same_time_as(at_time)
    end
  end

  describe "#build_new_reply_for" do
    it "uses a draft if one exists" do
      post = create(:post)
      draft = create(:reply_draft, post: post)
      reply = post.build_new_reply_for(draft.user)
      expect(reply).to be_a_new_record
      expect(reply.user).to eq(draft.user)
      expect(reply.content).to eq(draft.content)
    end

    it "copies most recent reply details if present" do
      post = create(:post)
      last_reply = create(:reply, post: post, with_character: true, with_icon: true)
      last_reply.character.default_icon = create(:icon, user: last_reply.user)
      last_reply.character.save
      last_reply.reload
      reply = post.build_new_reply_for(last_reply.user)
      expect(reply).to be_a_new_record
      expect(reply.user).to eq(last_reply.user)
      expect(reply.icon_id).to eq(last_reply.character.default_icon_id)
      expect(reply.character_id).to eq(last_reply.character_id)
    end

    it "copies post details if it belongs to the user" do
      post = create(:post, with_character: true, with_icon: true)
      reply = post.build_new_reply_for(post.user)
      expect(reply).to be_a_new_record
      expect(reply.user).to eq(post.user)
      expect(reply.icon_id).to eq(post.character.default_icon_id)
      expect(reply.character_id).to eq(post.character_id)
    end

    it "uses active character if available" do
      post = create(:post)
      character = create(:character, with_default_icon: true)
      character.user.active_character = character
      character.user.save

      reply = post.build_new_reply_for(character.user)

      expect(reply).to be_a_new_record
      expect(reply.user).to eq(character.user)
      expect(reply.icon_id).to eq(character.default_icon_id)
      expect(reply.character_id).to eq(character.id)
    end

    it "does not use avatar for active character without icons" do
      post = create(:post)
      icon = create(:icon)
      character = create(:character, user: icon.user)

      user = icon.user
      user.avatar = icon
      user.active_character = character
      user.save

      reply = post.build_new_reply_for(user)

      expect(reply).to be_a_new_record
      expect(reply.user).to eq(user)
      expect(reply.icon_id).to be_nil
      expect(reply.character_id).to eq(character.id)
    end

    it "uses avatar if available" do
      post = create(:post)
      icon = create(:icon)
      icon.user.avatar = icon
      icon.user.save

      reply = post.build_new_reply_for(icon.user)

      expect(reply).to be_a_new_record
      expect(reply.user).to eq(icon.user)
      expect(reply.icon_id).to eq(icon.user.avatar_id)
      expect(reply.character_id).to be_nil
    end

    it "handles new user" do
      post = create(:post)
      user = create(:user)

      reply = post.build_new_reply_for(user)

      expect(reply).to be_a_new_record
      expect(reply.user).to eq(user)
      expect(reply.icon_id).to be_nil
      expect(reply.character_id).to be_nil
    end
  end

  context "callbacks" do
    include ActiveJob::TestHelper
    it "should enqueue a message after creation" do
      clear_enqueued_jobs
      author = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: author)
      post = create(:post, user: author)
      post.run_callbacks(:commit) # deal with tests running in a transaction
      expect(NotifyFollowersOfNewPostJob).to have_been_enqueued.with(post.id).on_queue('notifier')
    end
  end

  # from Taggable concern
  context "tags" do
    it_behaves_like 'taggable', 'label'
    it_behaves_like 'taggable', 'setting'
    it_behaves_like 'taggable', 'content_warning'
  end
end
