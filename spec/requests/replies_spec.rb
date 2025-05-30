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

    it "works with invalid post", :aggregate_failures do
      private_post = create(:post, privacy: :private)

      get "/replies/search?post_id=#{private_post.id}&commit=Search"

      expect(response).to have_http_status(200)
      expect(response).to render_template(:search)
      expect(response.body).to include("You do not have permission to view this post.")
    end
  end
end
