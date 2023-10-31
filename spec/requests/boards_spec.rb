RSpec.describe "Continuities" do
  describe "creation" do
    it "creates a new board and shows on the boards list" do
      login
      get "/boards/new"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Create Continuity")
      end

      expect {
        post "/boards", params: {
          board: {
            name: "Sample",
            coauthor_ids: [],
            cameo_ids: [],
            authors_locked: true,
            description: "Sample board description",
          },
        }
      }.to change { Board.count }.by(1)

      aggregate_failures do
        expect(response).to redirect_to(continuities_path)
        expect(flash[:error]).to be_nil
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("Sample")
        expect(response.body).to include("Continuity created.")
      end

      user = Board.last
      get "/boards/#{user.id}"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("Sample")
        expect(response.body).to include("+ New Post")
      end
    end
  end
end
