RSpec.describe "Reply" do
  describe "search" do
    it "works" do
      create(:reply, content: "Sample reply")
      create(:reply, content: "Other reply")

      get "/replies/search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("Search Replies")
      end

      get "/replies/search?subj_content=Sample&commit=Search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("Search Replies")
        expect(response.body).to include("<b>Sample</b> reply")
        expect(response.body).not_to include("Other")
      end
    end

    it "works with invalid post" do
      private_post = create(:post, privacy: :private)

      get "/replies/search?post_id=#{private_post.id}&commit=Search"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("You do not have permission to view this post.")
      end
    end
  end

  describe "API search" do
    it "does not run a query per reply" do
      add_reply = lambda do
        calias = create(:alias)
        create(:reply, user: calias.character.user, character: calias.character, character_alias: calias, with_icon: true, content: 'a seagull')
      end
      add_reply.call
      expect_constant_queries("/api/v1/replies?subj_content=seagull") { 2.times { add_reply.call } }
      expect(response.parsed_body['results'].size).to eq(3)
    end
  end
end
