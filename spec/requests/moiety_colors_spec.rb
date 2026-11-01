RSpec.describe "Moiety colors on author names" do
  let(:author) { create(:user, moiety: 'abc123') }
  let(:replier) { create(:user, moiety: 'fed321') }
  let!(:thread) { create(:post, user: author) }
  let(:reader) { create(:user, password: known_test_password) }

  before(:each) { create(:reply, post: thread, user: replier) }

  def colored(user)
    "color: ##{user.moiety}"
  end

  context "with the preference on" do
    before(:each) do
      reader.update!(moiety_colors_unread: true)
      login(reader)
    end

    it "colors post and reply authors on the post" do
      get "/posts/#{thread.id}"
      expect(response.body).to include(colored(author)).and include(colored(replier))
    end

    it "colors authors and the last replier in post lists" do
      get "/posts"
      expect(response.body).to include(colored(author)).and include(colored(replier))
    end

    it "colors reply authors in reply search" do
      get "/replies/search", params: { commit: 'Search', post_id: thread.id }
      expect(response.body).to include(colored(replier))
    end
  end

  context "with the preference off" do
    before(:each) { login(reader) }

    it "leaves names plain on the post and in post lists" do
      get "/posts/#{thread.id}"
      expect(response.body).not_to include(colored(replier))
      get "/posts"
      expect(response.body).not_to include(colored(author))
      expect(response.body).not_to include(colored(replier))
    end
  end

  it "leaves names plain when logged out" do
    get "/posts"
    expect(response.body).not_to include(colored(author))
  end
end
