RSpec.describe PostHelper do
  describe "#author_links", :aggregate_failures do
    let(:post) { create(:post) }

    context "with only deleted users" do
      before(:each) { post.user.update!(deleted: true) }

      it "handles only a deleted user" do
        post.reload
        expect(helper.author_links(post)).to eq('(deleted user)')
      end

      it "handles only two deleted users" do
        reply = create(:reply, post: post)
        reply.user.update!(deleted: true)
        post.reload
        expect(helper.author_links(post)).to eq('(deleted users)')
      end

      it "handles >4 deleted users" do
        replies = create_list(:reply, 4, post: post)
        replies.each { |r| r.user.update!(deleted: true) }
        post.reload
        expect(helper.author_links(post)).to eq('(deleted users)')
      end
    end

    context "with active and deleted users" do
      let!(:reply) { create(:reply, post: post) }

      before(:each) { post.reload }

      it "handles two users with post user deleted" do
        post.user.update!(deleted: true)
        expect(helper.author_links(post)).to eq(helper.user_link(reply.user) + ' and 1 deleted user')
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles two users with reply user deleted" do
        reply.user.update!(deleted: true)
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ' and 1 deleted user')
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles three users with one deleted" do
        post.user.update!(username: 'xxx')
        reply.user.update!(deleted: true)
        reply = create(:reply, post: post, user: create(:user, username: 'yyy'))
        links = [post.user, reply.user].map { |u| helper.user_link(u) }.join(', ')
        expect(helper.author_links(post)).to eq(links + ' and 1 deleted user')
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles three users with two deleted" do
        reply.user.update!(deleted: true)
        reply = create(:reply, post: post)
        reply.user.update!(deleted: true)
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ' and 2 deleted users')
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles >4 users with post user first" do
        post.user.update!(username: 'zzz')
        reply.user.update!(username: 'yyy')
        reply = create(:reply, post: post, user: create(:user, username: 'xxx'))
        reply.user.update!(deleted: true)
        create(:reply, post: post, user: create(:user, username: 'www'))
        create(:reply, post: post, user: create(:user, username: 'vvv'))
        post.reload
        stats_link = helper.link_to('4 others', stats_post_path(post), title: 'vvv, www, yyy')
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ' and ' + stats_link)
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles >4 users with alphabetical user first iff post user deleted" do
        post.user.update!(username: 'zzz', deleted: true)
        reply.user.update!(username: 'yyy')
        create(:reply, post: post, user: create(:user, username: 'xxx'))
        reply = create(:reply, post: post, user: create(:user, username: 'aaa'))
        create(:reply, post: post, user: create(:user, username: 'vvv'))
        post.reload
        stats_link = helper.link_to('4 others', stats_post_path(post), title: 'vvv, xxx, yyy')
        expect(helper.author_links(post)).to eq(helper.user_link(reply.user) + ' and ' + stats_link)
        expect(helper.author_links(post)).to be_html_safe
      end
    end

    context "with only active users" do
      it "handles only one user" do
        post.reload
        expect(helper.author_links(post)).to eq(helper.user_link(post.user))
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles two users with commas" do
        post.user.update!(username: 'xxx')
        reply = create(:reply, post: post, user: create(:user, username: 'yyy'))
        post.reload
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ', ' + helper.user_link(reply.user))
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles three users with commas and no and" do
        post.user.update!(username: 'zzz')
        users = [post.user]
        users << create(:reply, post: post, user: create(:user, username: 'yyy')).user
        users << create(:reply, post: post, user: create(:user, username: 'xxx')).user
        post.reload
        expect(helper.author_links(post)).to eq(users.reverse.map { |u| helper.user_link(u) }.join(', '))
        expect(helper.author_links(post)).to be_html_safe
      end

      it "handles >4 users with post user first" do
        post.user.update!(username: 'zzz')
        create(:reply, post: post, user: create(:user, username: 'yyy'))
        create(:reply, post: post, user: create(:user, username: 'xxx'))
        create(:reply, post: post, user: create(:user, username: 'www'))
        create(:reply, post: post, user: create(:user, username: 'vvv'))
        post.reload
        stats_link = helper.link_to('4 others', stats_post_path(post), title: 'vvv, www, xxx, yyy')
        expect(helper.author_links(post)).to eq(helper.user_link(post.user) + ' and ' + stats_link)
        expect(helper.author_links(post)).to be_html_safe
      end
    end
  end

  describe "#allowed_boards" do
    it "includes open-to-everyone boards" do
      board = create(:board)
      user = create(:user)
      post = build(:post)
      expect(helper.allowed_boards(post, user)).to eq([board])
    end

    it "includes locked boards with user in" do
      user = create(:user)
      board = create(:board, authors_locked: true, authors: [user])
      post = build(:post)
      expect(helper.allowed_boards(post, user)).to eq([board])
    end

    it "hides boards that user can't write in" do
      create(:board, authors_locked: true)
      user = create(:user)
      post = build(:post)
      expect(helper.allowed_boards(post, user)).to eq([])
    end

    it "shows the post's board even if the user can't write in it" do
      board = create(:board, authors_locked: true)
      user = create(:user)
      post = build(:post, board: board)
      expect(helper.allowed_boards(post, user)).to eq([board])
    end

    it "orders boards" do
      board_a = create(:board, name: "A")
      board_b_pinned = create(:board, name: "B", pinned: true)
      board_c = create(:board, name: "C")
      user = create(:user)
      post = build(:post)
      expect(helper.allowed_boards(post, user)).to eq([board_b_pinned, board_a, board_c])
    end
  end

  describe "#shortened_desc" do
    it "uses full string if short enough" do
      text = 'a' * 100
      expect(helper.shortened_desc(text, 1)).to eq(text)
    end

    it "uses 255 chars if single long paragraph" do
      text = 'a' * 300
      more = '<a href="#" id="expanddesc-1" class="expanddesc">more &raquo;</a>'
      dots = '<span id="dots-1">... </span>'
      expand = '<span class="hidden" id="desc-1">' + ('a' * 45) + '</span>'
      expect(helper.shortened_desc(text, 1)).to eq(('a' * 255) + dots + expand + more)
    end
  end

  describe "#anchored_continuity_path" do
    it "anchors for sectioned post" do
      section = create(:board_section)
      post = create(:post, board: section.board, section: section)
      expect(helper.anchored_continuity_path(post)).to eq(continuity_path(post.board_id) + "#section-" + section.id.to_s)
    end

    it "does not anchor for unsectioned post" do
      post = create(:post)
      expect(helper.anchored_continuity_path(post)).to eq(continuity_path(post.board_id))
    end
  end

  shared_examples "unread_or_opened" do
    let(:post) { create(:post) }

    it "requires a post" do
      expect(method(nil, [1, 2])).to eq(false)
    end

    it "requires an id list" do
      expect(method(post, nil)).to eq(false)
    end

    it "returns true if id in list" do
      expect(method(post, [1, 2, post.id])).to eq(true)
    end

    it "returns false if id not in list" do
      expect(method(post, [1, 2])).to eq(false)
    end
  end

  describe "#unread_post?" do
    def method(post, ids)
      helper.unread_post?(post, ids)
    end

    it_behaves_like 'unread_or_opened'
  end

  describe "#opened_post?" do
    def method(post, ids)
      helper.opened_post?(post, ids)
    end

    it_behaves_like 'unread_or_opened'
  end
end
