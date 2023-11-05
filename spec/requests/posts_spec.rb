RSpec.describe "Post" do
  describe "hidden list" do
    it "shows hidden posts" do
      user = login
      shown = create(:post, subject: "Shown post")
      hidden = create(:post, subject: "Hidden post")
      hidden.ignore(user)

      get "/posts/hidden"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:hidden)
        expect(response.body).to include("Hidden from Unread")
        expect(response.body).to include("Hidden post")
        expect(response.body).not_to include("Shown post")
      end
    end
  end
end
