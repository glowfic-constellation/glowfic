RSpec.describe MergePostsJob do
  let(:user) { create(:user) }
  let(:source_post) { create(:post, user: user, authors_locked: true) }
  let(:target_post) { create(:post, user: user, authors_locked: true) }
  let(:source_replies) { create_list(:reply, 3, post: source_post, user: user) }
  let(:target_replies) { create_list(:reply, 4, post: target_post, user: user) }

  def merge_at(target_reply, privacy: 'public', setting_ids: [], content_warning_ids: [], label_ids: [])
    MergePostsJob.perform_now(source_post.id, target_reply.id, privacy, setting_ids, content_warning_ids, label_ids)
  end

  describe "validations" do
    it "requires existing source post" do
      expect {
        MergePostsJob.perform_now(-1, target_replies.first.id, 'public', [], [], [])
      }.to raise_error(RuntimeError, "Couldn't find source post")
    end

    it "requires existing target reply" do
      expect {
        MergePostsJob.perform_now(source_post.id, -1, 'public', [], [], [])
      }.to raise_error(RuntimeError, "Couldn't find target reply")
    end
  end

  it "splices the source's replies in after a mid-thread target reply" do
    source_replies
    target_replies

    merge_at(target_replies[1])

    expected = [target_post.written, target_replies[0], target_replies[1],
                source_post.written, *source_replies,
                target_replies[2], target_replies[3]]
    expect(target_post.replies.ordered).to eq(expected)
    expect(target_post.replies.ordered.map(&:reply_order)).to eq((0..8).to_a)
    expect(Reply.where(post_id: source_post.id)).to be_empty
  end

  it "splices the source's replies in right after the written" do
    source_replies
    target_replies

    merge_at(target_post.written)

    expected = [target_post.written, source_post.written, *source_replies, *target_replies]
    expect(target_post.replies.ordered).to eq(expected)
    expect(target_post.replies.ordered.map(&:reply_order)).to eq((0..8).to_a)
  end

  it "preserves reply ids and timestamps" do
    reply = source_replies.first
    old_created_at = reply.created_at
    old_updated_at = reply.updated_at

    merge_at(target_replies.last)

    reply.reload
    expect(reply.post_id).to eq(target_post.id)
    expect(reply.created_at).to be_the_same_time_as(old_created_at)
    expect(reply.updated_at).to be_the_same_time_as(old_updated_at)
  end

  it "moves bookmarks along with the replies" do
    moved = create(:bookmark, reply: source_replies.first, post: source_post, user: user)
    stays = create(:bookmark, reply: target_replies.first, post: target_post, user: user)

    merge_at(target_replies.last)

    expect(moved.reload.post_id).to eq(target_post.id)
    expect(stays.reload.post_id).to eq(target_post.id)
  end

  it "applies the chosen metadata" do
    setting = create(:setting)
    warning = create(:content_warning)
    label = create(:label)
    target_post.update!(settings: [create(:setting)])

    merge_at(target_replies.last, privacy: 'access_list', setting_ids: [setting.id], content_warning_ids: [warning.id], label_ids: [label.id])

    target_post.reload
    expect(target_post.privacy).to eq('access_list')
    expect(target_post.settings).to eq([setting])
    expect(target_post.content_warnings).to eq([warning])
    expect(target_post.labels).to eq([label])
  end

  it "updates the last reply cache when merging at the end" do
    source_replies
    target_replies

    merge_at(target_replies.last)

    target_post.reload
    expect(target_post.last_reply_id).to eq(source_replies.last.id)
    expect(target_post.last_user_id).to eq(source_replies.last.user_id)
  end

  it "keeps the last reply cache when merging mid-thread" do
    source_replies
    target_replies

    merge_at(target_replies[0])

    target_post.reload
    expect(target_post.last_reply_id).to eq(target_replies.last.id)
  end

  it "uses the newer tagged_at of the two posts" do
    Timecop.freeze(2.days.ago) { target_replies }
    source_replies

    source_tagged = source_post.reload.tagged_at
    merge_at(target_replies.last)

    expect(target_post.reload.tagged_at).to be_the_same_time_as(source_tagged)
  end

  it "keeps the target's tagged_at when it is newer" do
    Timecop.freeze(2.days.ago) { source_replies }
    target_replies

    target_tagged = target_post.reload.tagged_at
    merge_at(target_replies.last)

    expect(target_post.reload.tagged_at).to be_the_same_time_as(target_tagged)
  end

  describe "authors" do
    let(:coauthor) { create(:user) }

    it "copies source-only authors onto the target" do
      joined_at = 2.days.ago
      create(:post_author, post: source_post, user: coauthor, joined: true, joined_at: joined_at,
        can_owe: false, private_note: 'my note',)

      merge_at(target_replies.last)

      author = target_post.author_for(coauthor)
      expect(author.joined).to eq(true)
      expect(author.joined_at).to be_the_same_time_as(joined_at)
      expect(author.can_owe).to eq(false)
      expect(author.private_note).to eq('my note')
    end

    it "merges authors on both posts" do
      early = 3.days.ago
      late = 1.day.ago
      create(:post_author, post: source_post, user: coauthor, joined: true, joined_at: early,
        can_owe: false, can_reply: true, private_note: 'source note',)
      create(:post_author, post: target_post, user: coauthor, joined: false, joined_at: late,
        can_owe: true, can_reply: false, private_note: 'target note',)

      merge_at(target_replies.last)

      author = target_post.author_for(coauthor)
      expect(author.private_note).to eq("target note\n\n<hr>\n\nsource note")
      expect(author.joined).to eq(true)
      expect(author.joined_at).to be_the_same_time_as(early)
      expect(author.can_reply).to eq(true)
      expect(author.can_owe).to eq(true) # the target's setting wins
    end

    it "keeps a one-sided note without a separator" do
      create(:post_author, post: source_post, user: coauthor, private_note: 'source note')
      create(:post_author, post: target_post, user: coauthor)

      merge_at(target_replies.last)

      expect(target_post.author_for(coauthor).private_note).to eq('source note')
    end
  end

  describe "drafts" do
    it "moves drafts to the target" do
      draft = create(:reply_draft, post: source_post, user: user)

      merge_at(target_replies.last)

      expect(draft.reload.post_id).to eq(target_post.id)
    end

    it "preserves a displaced draft in the author's notes" do
      target_replies # materialize before drafting; posting a reply destroys its author's draft
      target_post.author_for(user).update!(private_note: 'existing note')
      character = create(:character, user: user, screenname: 'some-screenname')
      icon = create(:icon, user: user, keyword: 'happy')
      create(:reply_draft, post: source_post, user: user, content: 'draft words', character: character, icon: icon)
      kept_draft = create(:reply_draft, post: target_post, user: user, content: 'target draft')

      merge_at(target_replies.last)

      expect(ReplyDraft.where(post_id: source_post.id)).to be_empty
      expect(kept_draft.reload.content).to eq('target draft')
      note = target_post.author_for(user).reload.private_note
      header = "<strong>Unposted draft from \"#{source_post.subject}\":</strong>\n" \
               "#{character.name} | some-screenname | icon: happy\n<br>\ndraft words"
      expect(note).to eq("#{header}\n\n<hr>\n\nexisting note")
    end

    it "preserves a non-author's displaced draft in their surviving target draft" do
      target_replies
      drafter = create(:user)
      [source_post, target_post].each { |post| post.update!(authors_locked: false) }
      create(:reply_draft, post: source_post, user: drafter, content: 'source words')
      target_draft = create(:reply_draft, post: target_post, user: drafter, content: 'target words')
      [source_post, target_post].each { |post| post.update!(authors_locked: true) }

      merge_at(target_replies.last)

      expect(target_post.author_for(drafter)).to be_nil
      expect(target_draft.reload.content).to include("Unposted draft from \"#{source_post.subject}\"")
      expect(target_draft.content).to include('source words')
      expect(target_draft.content).to end_with('target words')
    end

    it "marks NPCs in a displaced draft's notes" do
      target_replies # materialize before drafting; posting a reply destroys its author's draft
      npc = create(:character, user: user, npc: true, screenname: nil)
      create(:reply_draft, post: source_post, user: user, content: 'draft words', character: npc)
      create(:reply_draft, post: target_post, user: user, content: 'target draft')

      merge_at(target_replies.last)

      note = target_post.author_for(user).reload.private_note
      expect(note).to include("#{npc.name} (NPC)\n<br>\ndraft words")
    end
  end

  describe "unread markers" do
    let(:reader) { create(:user) }
    let(:early) { 3.days.ago }
    let(:late) { 1.day.ago }

    before(:each) do
      source_replies
      target_replies
    end

    # fresh finds to avoid the cached @view crossing users
    def mark_read_at(post, reply, at_time)
      Post.find(post.id).mark_read(reader, at_time: at_time, force: true, at_reply: reply)
    end

    def reader_view
      target_post.views.find_by(user: reader)
    end

    it "keeps markers for users caught up on both when merging mid-thread" do
      mark_read_at(source_post, source_replies.last, early)
      mark_read_at(target_post, target_replies.last, late)

      merge_at(target_replies[1])

      expect(reader_view.last_read_reply).to eq(target_replies.last)
      expect(reader_view.read_at).to be_the_same_time_as(late) # the max of the two
      expect(Post.find(target_post.id).first_unread_for(reader)).to be_nil
    end

    it "moves markers to the source's last reply for users caught up on both when merging at the end" do
      mark_read_at(source_post, source_replies.last, late)
      mark_read_at(target_post, target_replies.last, early)

      merge_at(target_replies.last)

      expect(reader_view.last_read_reply).to eq(source_replies.last)
      expect(reader_view.read_at).to be_the_same_time_as(late)
      expect(Post.find(target_post.id).first_unread_for(reader)).to be_nil
    end

    it "keeps markers for users caught up on the source only" do
      mark_read_at(source_post, source_replies.last, late)
      mark_read_at(target_post, target_replies[2], early)

      merge_at(target_post.written)

      expect(reader_view.last_read_reply).to eq(target_replies[2])
      expect(reader_view.read_at).to be_the_same_time_as(early) # the min of the two
      expect(Post.find(target_post.id).first_unread_for(reader)).to eq(target_replies[3])
    end

    it "moves markers to their source position for users caught up on the target only" do
      mark_read_at(source_post, source_replies[0], late)
      mark_read_at(target_post, target_replies.last, early)

      merge_at(target_replies[1])

      expect(reader_view.last_read_reply).to eq(source_replies[0])
      expect(reader_view.read_at).to be_the_same_time_as(early)
      expect(Post.find(target_post.id).first_unread_for(reader)).to eq(source_replies[1])
    end

    it "moves markers to the earliest position for users caught up on neither" do
      mark_read_at(source_post, source_replies[0], early)
      mark_read_at(target_post, target_replies[2], late)

      merge_at(target_post.written) # the source's replies land before the target marker

      expect(reader_view.last_read_reply).to eq(source_replies[0])
      expect(Post.find(target_post.id).first_unread_for(reader)).to eq(source_replies[1])
    end

    it "keeps the target marker for users caught up on neither when it is earliest" do
      mark_read_at(source_post, source_replies[0], early)
      mark_read_at(target_post, target_replies[0], late)

      merge_at(target_replies.last) # the source's replies land after the target marker

      expect(reader_view.last_read_reply).to eq(target_replies[0])
      expect(Post.find(target_post.id).first_unread_for(reader)).to eq(target_replies[1])
    end

    it "creates no view for users who only opened the source" do
      mark_read_at(source_post, source_replies.last, late)

      merge_at(target_replies.last)

      expect(reader_view).to be_nil
    end

    it "rewinds markers past the insertion point for users who never opened the source" do
      mark_read_at(target_post, target_replies[2], late)

      merge_at(target_replies[0])

      expect(reader_view.last_read_reply).to eq(target_replies[0])
      expect(Post.find(target_post.id).first_unread_for(reader)).to eq(source_post.written)
    end

    it "rewinds markers for users who hid the source without reading it" do
      Post.find(source_post.id).ignore(reader) # creates a view with no read_at
      mark_read_at(target_post, target_replies[2], late)

      merge_at(target_replies[0])

      expect(reader_view.last_read_reply).to eq(target_replies[0])
      expect(Post.find(target_post.id).first_unread_for(reader)).to eq(source_post.written)
    end

    it "leaves markers before the insertion point for users who never opened the source" do
      mark_read_at(target_post, target_replies[0], late)

      merge_at(target_replies[2])

      expect(reader_view.last_read_reply).to eq(target_replies[0])
      expect(Post.find(target_post.id).first_unread_for(reader)).to eq(target_replies[1])
    end
  end

  it "adds all authors to the access list when merging to access list privacy" do
    coauthor = create(:user)
    create(:post_author, post: source_post, user: coauthor)

    merge_at(target_replies.last, privacy: 'access_list')

    expect(target_post.reload.viewers.map(&:id)).to match_array([coauthor.id])
    expect(target_post.visible_to?(coauthor)).to eq(true)
    expect(target_post.visible_to?(user)).to eq(true) # the creator needs no viewer row
  end

  it "does not add author viewers under other privacies" do
    coauthor = create(:user)
    create(:post_author, post: source_post, user: coauthor)

    merge_at(target_replies.last, privacy: 'registered')

    expect(target_post.reload.viewers).to be_empty
  end

  describe "notifications" do
    let(:reader) { create(:user) }

    before(:each) do
      source_replies
      target_replies
    end

    def read_post(post, user)
      Post.find(post.id).mark_read(user, at_reply: Post.find(post.id).replies.ordered.last)
    end

    it "notifies all authors of either post" do
      coauthor = create(:user)
      create(:post_author, post: source_post, user: coauthor)
      read_post(target_post, user) # proves skip_check_read: the author has read the target

      merge_at(target_replies.last)

      author_notice = Notification.find_by(user: user)
      expect(author_notice.notification_type).to eq('post_merged_author')
      expect(author_notice.post_id).to eq(target_post.id)
      expect(author_notice.unread).to eq(true)
      expect(author_notice.message).to include("Post \"#{source_post.subject}\" has been merged into \"#{target_post.subject}\"")
      expect(author_notice.message).to include("href=\"/replies/#{target_replies.last.id}\"")
      expect(Notification.find_by(user: coauthor).notification_type).to eq('post_merged_author')
    end

    it "notifies source openers who can see the merged post" do
      read_post(source_post, reader)

      merge_at(target_replies.last)

      notice = Notification.find_by(user: reader)
      expect(notice.notification_type).to eq('source_post_merged')
      expect(notice.post_id).to eq(target_post.id)
    end

    it "does not notify source openers who cannot see the merged post" do
      read_post(source_post, reader)

      merge_at(target_replies.last, privacy: 'access_list')

      expect(Notification.find_by(user: reader)).to be_nil
    end

    it "notifies target openers with markers past the insertion point" do
      Post.find(target_post.id).mark_read(reader, at_reply: target_replies[2])

      merge_at(target_replies[0])

      expect(Notification.find_by(user: reader).notification_type).to eq('target_post_merged')
    end

    it "does not notify target openers who cannot see the merged post" do
      Post.find(target_post.id).mark_read(reader, at_reply: target_replies[2])

      merge_at(target_replies[0], privacy: 'access_list')

      expect(Notification.find_by(user: reader)).to be_nil
    end

    it "does not notify target openers with markers before the insertion point" do
      Post.find(target_post.id).mark_read(reader, at_reply: target_replies[0])

      merge_at(target_replies[2])

      expect(Notification.find_by(user: reader)).to be_nil
    end

    it "notifies source openers only once even with both posts opened" do
      read_post(source_post, reader)
      Post.find(target_post.id).mark_read(reader, at_reply: target_replies[2])

      merge_at(target_replies[0])

      expect(Notification.where(user: reader).count).to eq(1)
      expect(Notification.find_by(user: reader).notification_type).to eq('source_post_merged')
    end
  end

  describe "post references" do
    it "migrates favorites, deduplicating followers of both" do
      follower = create(:user)
      both_follower = create(:user)
      create(:favorite, user: follower, favorite: source_post)
      create(:favorite, user: both_follower, favorite: source_post)
      kept = create(:favorite, user: both_follower, favorite: target_post)

      merge_at(target_replies.last)

      expect(Favorite.where(user: follower, favorite: target_post)).to exist
      expect(Favorite.where(user: both_follower).count).to eq(1)
      expect(Favorite.find_by(user: both_follower)).to eq(kept)
    end

    it "migrates index entries, deduplicating indexes listing both" do
      index = create(:index)
      both_index = create(:index)
      create(:index_post, index: index, post: source_post)
      create(:index_post, index: both_index, post: source_post)
      create(:index_post, index: both_index, post: target_post)

      merge_at(target_replies.last)

      expect(IndexPost.where(index: index, post: target_post)).to exist
      expect(IndexPost.where(index: both_index, post: target_post).count).to eq(1)
      expect(IndexPost.where(post: source_post.id)).to be_empty
    end

    it "repoints old notifications at the merged post" do
      reader = create(:user)
      notice = create(:notification, user: reader, post: source_post, notification_type: :new_favorite_post)

      merge_at(target_replies.last)

      expect(notice.reload.post_id).to eq(target_post.id)
    end
  end

  it "deletes the source post" do
    source_replies
    reader = create(:user)
    Post.find(source_post.id).mark_read(reader, at_reply: source_replies.last)

    merge_at(target_replies.last)

    expect(Post.find_by(id: source_post.id)).to be_nil
    expect(Post::View.where(post_id: source_post.id)).to be_empty
  end

  it "takes an author-set hiatus off the target" do
    target_replies
    target_post.update!(status: :hiatus)

    merge_at(target_replies.last)

    expect(target_post.reload.status).to eq('active')
  end

  it "regenerates the target's flat post" do
    source_replies
    target_replies
    $redis.del(GenerateFlatPostJob.lock_key(target_post.id)) # release the lock from the replies' creation
    expect {
      merge_at(target_replies.last)
    }.to enqueue_job(GenerateFlatPostJob).with(target_post.id)
  end
end
