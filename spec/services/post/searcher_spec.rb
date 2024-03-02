RSpec.describe Post::Searcher do
  it "finds all when no arguments given" do
    create_list(:post, 4)
    results = Post::Searcher.new.search({})
    expect(results).to match_array(Post.all)
  end

  it "filters by continuity" do
    board = create(:board)
    posts = create_list(:post, 2, board: board)
    create(:post)
    results = Post::Searcher.new.search({ board_id: post.board_id })
    expect(results).to match_array(posts)
  end

  it "filters by setting" do
    setting = create(:setting)
    post = create(:post, settings: [setting])
    create(:post)
    results = Post::Searcher.new.search({ setting_id: setting.id })
    expect(results).to match_array([post])
  end

  context "filters by subject" do
    let!(:post1) { create(:post, subject: 'contains stars') }
    let!(:post2) { create(:post, subject: 'contains Stars') }

    before(:each) { create(:post, subject: 'unrelated') }

    it "successfully" do
      results = Post::Searcher.new.search({ subject: 'stars' })
      expect(results).to match_array([post1, post2])
    end

    it "acronym" do
      post3 = create(:post, subject: 'Case starlight')
      results = Post::Searcher.new.search({ subject: 'cs', abbrev: true })
      expect(results).to match_array([post1, post2, post3])
    end

    it "exact match" do
      skip "TODO not yet implemented"
    end
  end

  it "does not mix up subject with content" do
    create(:post, subject: 'unrelated', content: 'contains stars')
    results = Post::Searcher.new.search({ subject: 'stars' })
    expect(results).to be_empty
  end

  context "filters by authors" do
    let(:author1) { create(:user) }
    let(:author2) { create(:user) }
    let!(:post1) { create(:post, user: author1) } # a1 only, post only
    let!(:post2) { create(:post) } # a2 only, reply only
    let!(:post3) { create(:post, user: author1) } # both authors, a1 post only
    let!(:post4) { create(:post) } # both authors, replies only

    before(:each) do
      create(:post)
      create(:reply, post: post2, user: author2)
      create(:reply, post: post3, user: author2)
      create(:reply, post: post4, user: author1)
      create(:reply, post: post4, user: author2)
    end

    it "one author" do
      results = Post::Searcher.new.search({ author_id: [author1.id] })
      expect(results).to match_array([post1, post3, post4])
    end

    it "multiple authors" do
      results = Post::Searcher.new.search({ author_id: [author1.id, author2.id] })
      expect(results).to match_array([post3, post4])
    end
  end

  it "filters by characters" do
    create(:reply, with_character: true)
    reply = create(:reply, with_character: true)
    post = create(:post, character: reply.character, user: reply.user)
    results = Post::Searcher.new.search({ commit: true, character_id: reply.character_id })
    expect(results).to match_array([reply.post, post])
  end

  it "filters by completed" do
    create(:post)
    post = create(:post, status: :complete)
    results = Post::Searcher.new.search({ completed: true })
    expect(results).to match_array(post)
  end

  it "sorts posts by tagged_at" do
    posts = create_list(:post, 4)
    create(:reply, post: posts[2])
    create(:reply, post: posts[1])
    results = Post::Searcher.new.search({})
    expect(results).to eq([posts[1], posts[2], posts[3], posts[0]])
  end
end
