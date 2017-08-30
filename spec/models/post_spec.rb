require "spec_helper"

RSpec.describe Post do
  it "should have the right timestamps" do
    # creation
    post = create(:post)
    expect(post.edited_at).to be_the_same_time_as(post.created_at)
    expect(post.tagged_at).to be_the_same_time_as(post.created_at)

    # edited with no replies updates edit and tag
    post.content = 'new content'
    post.save
    expect(post.tagged_at).to be_the_same_time_as(post.edited_at)
    expect(post.tagged_at).to be > post.created_at
    old_edited_at = post.edited_at
    old_tagged_at = post.tagged_at

    # invalid edit field with no replies updates nothing
    post.status = Post::STATUS_COMPLETE
    post.save
    expect(post.tagged_at).to be_the_same_time_as(old_tagged_at)
    expect(post.edited_at).to be_the_same_time_as(old_edited_at)

    # reply created updates tag but not edit
    reply = create(:reply, post: post)
    post.reload
    expect(post.tagged_at).to be_the_same_time_as(reply.created_at)
    expect(post.edited_at).to be_the_same_time_as(old_edited_at)
    expect(post.tagged_at).to be > post.edited_at
    old_tagged_at = post.tagged_at

    # edited with replies updates edit but not tag
    post.content = 'newer content'
    post.save
    expect(post.tagged_at).to be_the_same_time_as(old_tagged_at)
    expect(post.edited_at).to be > old_edited_at
    old_edited_at = post.edited_at

    # invalid edit field with replies updates nothing
    post.status = Post::STATUS_ACTIVE
    post.save
    expect(post.tagged_at).to be_the_same_time_as(old_tagged_at)
    expect(post.edited_at).to be_the_same_time_as(old_edited_at)

    # second reply created updates tag but not edit
    reply2 = create(:reply, post: post)
    post.reload
    expect(post.tagged_at).to be_the_same_time_as(reply2.created_at)
    expect(post.updated_at).to be >= reply2.created_at
    expect(post.tagged_at).to be > post.edited_at
    old_tagged_at = post.tagged_at
    old_edited_at = post.edited_at

    # first reply updated updates nothing
    reply.content = 'new content'
    reply.skip_post_update = true unless reply.post.last_reply_id == reply.id
    reply.save
    post.reload
    expect(post.tagged_at).to be_the_same_time_as(old_tagged_at) # BAD
    expect(post.edited_at).to be_the_same_time_as(old_edited_at)

    # second reply updated updates tag but not edit
    reply2.content = 'new content'
    reply2.skip_post_update = true unless reply2.post.last_reply_id == reply2.id
    reply2.save
    post.reload
    expect(post.tagged_at).to be_the_same_time_as(reply2.updated_at)
    expect(post.edited_at).to be_the_same_time_as(old_edited_at)
  end

  it "should allow blank content" do
    post = create(:post, content: '')
    expect(post.id).not_to be_nil
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
        expect(post.has_icons?).to be_true
      end

      it "is false without avatar" do
        expect(post.character).to be_nil
        expect(post.has_icons?).not_to be_true
      end
    end

    context "with character" do
      let(:character) { create(:character, user: user) }
      let(:post) { create(:post, user: user, character: character) }

      it "is true with default icon" do
        icon = create(:icon, user: user)
        character.update_attributes(default_icon: icon)
        expect(post.has_icons?).to be_true
      end

      it "is false without galleries" do
        expect(post.has_icons?).not_to be_true
      end

      it "is true with icons in galleries" do
        gallery = create(:gallery, user: user)
        gallery.icons << create(:icon, user: user)
        character.galleries << gallery
        expect(post.has_icons?).to be_true
      end

      it "is false without icons in galleries" do
        character.galleries << create(:gallery, user: user)
        expect(post.has_icons?).not_to be_true
      end
    end
  end

  describe "validations" do
    it "requires user" do
      post = create(:post)
      expect(post.valid?).to be_true
      post.user = nil
      expect(post.valid?).not_to be_true
    end

    it "requires user's character" do
      post = create(:post)
      character = create(:character)
      expect(post.user).not_to eq(character.user)
      post.character = character
      expect(post.valid?).not_to be_true
    end

    it "requires user's icon" do
      post = create(:post)
      icon = create(:icon)
      expect(post.user).not_to eq(icon.user)
      post.icon = icon
      expect(post.valid?).not_to be_true
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
  end

  describe "#visible_to?" do
    context "public" do
      let(:post) { create(:post, privacy: Post::PRIVACY_PUBLIC) }

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
      let(:post) { create(:post, privacy: Post::PRIVACY_PRIVATE) }

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
      let(:post) { create(:post, privacy: Post::PRIVACY_LIST) }

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
      let(:post) { create(:post, privacy: Post::PRIVACY_REGISTERED) }
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

  it "should enqueue a message after creation" do
    author = create(:user)
    notified = create(:user)
    create(:favorite, user: notified, favorite: author)
    post = create(:post, user: author)
    post.run_callbacks(:commit) # deal with tests running in a transaction
    expect(NotifyFollowersOfNewPostJob).to have_queued(post.id)
  end

  # from Taggable concern; duplicated between PostSpec, CharacterSpec, GallerySpec
  context "tags" do
    let(:taggable) { create(:post) }
    ['label', 'setting', 'content_warning'].each do |type|
      it "creates new #{type} tags if they don't exist" do
        taggable.send(type + '_ids=', ['_tag'])
        expect(taggable.send(type + 's').map(&:name)).to match_array(['tag'])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        tag_ids = taggable.send(type + '_ids')
        expect(tags.map(&:name)).to match_array(['tag'])
        expect(tags.map(&:user)).to match_array([taggable.user])
      end

      it "uses extant tags with same name and type for #{type}" do
        tag = create(type)
        old_user = tag.user
        taggable.send(type + '_ids=', ['_' + tag.name])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        expect(tags).to match_array([tag])
        expect(tags.map(&:user)).to match_array([old_user])
      end

      it "does not use extant tags of a different type with same name for #{type}" do
        name = "Example Tag"
        tag = create(:tag, type: 'NonexistentTag', name: name)
        taggable.send(type + '_ids=', ['_' + name])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        tag_ids = taggable.send(type + '_ids')
        expect(tags.map(&:name)).to match_array([name])
        expect(tags.map(&:user)).to match_array([taggable.user])
        expect(tags).not_to include(tag)
        expect(tag_ids).to match_array(tags.map(&:id))
      end

      it "uses extant #{type} tags by id" do
        tag = create(type)
        old_user = tag.user
        taggable.send(type + '_ids=', [tag.id.to_s])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        tag_ids = taggable.send(type + '_ids')
        expect(tags).to match_array([tag])
        expect(tags.map(&:user)).to match_array([old_user])
        expect(tag_ids).to match_array([tag.id])
      end

      it "removes #{type} tags when not in list given" do
        tag = create(type)
        taggable.send(type + 's=', [tag])
        taggable.save
        taggable.reload
        expect(taggable.send(type + 's')).to match_array([tag])
        taggable.send(type + '_ids=', [])
        taggable.save
        taggable.reload
        expect(taggable.send(type + 's')).to eq([])
        expect(taggable.send(type + '_ids')).to eq([])
      end

      it "only adds #{type} tags once if given multiple times" do
        name = 'Example Tag'
        tag = create(type, name: name)
        old_user = tag.user
        taggable.send(type + '_ids=', ['_' + name, '_' + name, tag.id.to_s, tag.id.to_s])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        tag_ids = taggable.send(type + '_ids')
        expect(tags).to match_array([tag])
        expect(tags.map(&:user)).to match_array([old_user])
        expect(tag_ids).to match_array([tag.id])
      end

      it "orders #{type} tags by order added to model" do
        tag1 = create(type)
        tag2 = create(type)
        tag3 = create(type)
        tag4 = create(type)

        taggable.send(type + '_ids=', [tag3.id, '_fake1', '_'+tag1.name, '_fake2', tag4.id])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        expect(tags[0]).to eq(tag3)
        expect(tags[2]).to eq(tag1)
        expect(tags[4]).to eq(tag4)
        expect(tags.map(&:name)).to eq([tag3.name, 'fake1', tag1.name, 'fake2', tag4.name])

        taggable.send(type + '_ids=', taggable.send(type + '_ids') + ['_'+tag2.name, '_fake3', '_fake4'])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        tag_ids = taggable.send(type + '_ids')
        expect(tags[0]).to eq(tag3)
        expect(tags[2]).to eq(tag1)
        expect(tags[5]).to eq(tag2)
        expect(tags.map(&:name)).to eq([tag3.name, 'fake1', tag1.name, 'fake2', tag4.name, tag2.name, 'fake3', 'fake4'])
      end
    end
  end
end
