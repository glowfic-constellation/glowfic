RSpec.describe Reply::Searcher do
  describe "#setup" do
    context "with a visible post" do
      it "sets users, characters, templates, boards from the post" do
        user = create(:user)
        template = create(:template, user: user)
        char = create(:character, user: user, template: template)
        post = create(:post, user: user, character: char)
        create(:reply, post: post, user: user, character: char)

        searcher = Reply::Searcher.new(current_user: user, post: post)
        searcher.setup({})

        expect(searcher.users).to include(user)
        expect(searcher.characters).to include(char)
        expect(searcher.templates).to include(template)
        expect(searcher.boards).to eq([post.board])
      end
    end

    context "with a non-visible post" do
      it "does not set data" do
        user = create(:user)
        post = create(:post, privacy: :private)

        searcher = Reply::Searcher.new(current_user: user, post: post)
        searcher.setup({})

        expect(searcher.users).to be_nil
        expect(searcher.characters).to be_nil
        expect(searcher.templates).to be_nil
        expect(searcher.boards).to be_nil
      end
    end

    context "without a post" do
      it "sets users from author_id param" do
        user = create(:user)
        searcher = Reply::Searcher.new(current_user: user)
        searcher.setup({ author_id: user.id })
        expect(searcher.users).to include(user)
      end

      it "sets characters from character_id param" do
        char = create(:character)
        searcher = Reply::Searcher.new
        searcher.setup({ character_id: char.id })
        expect(searcher.characters).to include(char)
      end

      it "sets boards from board_id param" do
        board = create(:board)
        searcher = Reply::Searcher.new
        searcher.setup({ board_id: board.id })
        expect(searcher.boards).to include(board)
      end

      it "loads templates without specific params" do
        create(:template)
        searcher = Reply::Searcher.new
        searcher.setup({})
        expect(searcher.templates).to be_present
      end

      it "does not set users without author_id" do
        searcher = Reply::Searcher.new
        searcher.setup({})
        expect(searcher.users).to be_nil
      end
    end
  end

  describe "#search" do
    it "filters by author_id" do
      reply = create(:reply)
      create(:reply) # other reply
      searcher = Reply::Searcher.new(Reply.all)
      results = searcher.search({ author_id: reply.user_id, commit: true }, page: 1)
      expect(results).to include(reply)
    end

    it "filters by character_id" do
      reply = create(:reply, with_character: true)
      create(:reply) # other reply
      searcher = Reply::Searcher.new(Reply.all)
      results = searcher.search({ character_id: reply.character_id, commit: true }, page: 1)
      expect(results).to include(reply)
    end

    it "filters by icon_id" do
      reply = create(:reply, with_icon: true)
      create(:reply) # other reply
      searcher = Reply::Searcher.new(Reply.all)
      results = searcher.search({ icon_id: reply.icon_id, commit: true }, page: 1)
      expect(results).to include(reply)
    end

    it "filters by board_id" do
      reply = create(:reply)
      create(:reply) # other reply
      searcher = Reply::Searcher.new(Reply.all)
      results = searcher.search({ board_id: reply.post.board_id, commit: true }, page: 1)
      expect(results).to include(reply)
    end

    it "filters by post when post is set" do
      reply = create(:reply)
      create(:reply) # other reply
      searcher = Reply::Searcher.new(Reply.all, post: reply.post)
      results = searcher.search({ commit: true }, page: 1)
      expect(results).to include(reply)
    end

    it "sorts by created_new" do
      reply1 = create(:reply)
      reply2 = Timecop.freeze(reply1.created_at + 2.minutes) { create(:reply) }
      searcher = Reply::Searcher.new(Reply.all)
      results = searcher.search({ sort: 'created_new', commit: true }, page: 1)
      expect(results.index(reply2)).to be < results.index(reply1)
    end

    it "sorts by created_old" do
      reply1 = create(:reply)
      reply2 = Timecop.freeze(reply1.created_at + 2.minutes) { create(:reply) }
      searcher = Reply::Searcher.new(Reply.all)
      results = searcher.search({ sort: 'created_old', commit: true }, page: 1)
      expect(results.index(reply1)).to be < results.index(reply2)
    end

    it "filters by template_id" do
      template = create(:template)
      char = create(:character, template: template, user: template.user)
      reply = create(:reply, character: char, user: char.user)
      create(:reply)
      searcher = Reply::Searcher.new(Reply.all)
      results = searcher.search({ template_id: template.id, commit: true }, page: 1)
      expect(results).to include(reply)
    end

    it "excludes hidden posts for logged-in user" do
      user = create(:user)
      reply = create(:reply)
      Block.create!(blocking_user: user, blocked_user: reply.post.user, hide_them: :posts, hide_me: :none)
      other_reply = create(:reply)
      searcher = Reply::Searcher.new(Reply.all, current_user: user)
      results = searcher.search({ commit: true }, page: 1)
      expect(results).not_to include(reply)
      expect(results).to include(other_reply)
    end

    it "includes hidden posts when show_blocked is set" do
      user = create(:user)
      reply = create(:reply)
      Block.create!(blocking_user: user, blocked_user: reply.post.user, hide_them: :posts, hide_me: :none)
      searcher = Reply::Searcher.new(Reply.all, current_user: user)
      results = searcher.search({ commit: true, show_blocked: true }, page: 1)
      expect(results).to include(reply)
    end

    it "skips icon join when condensed" do
      create(:reply, with_icon: true)
      searcher = Reply::Searcher.new(Reply.all)
      results = searcher.search({ commit: true, condensed: true }, page: 1)
      expect(results).to be_present
    end
  end
end
