RSpec.describe "News" do
  describe "management" do
    it "creates a new news post and edits it successfully" do
      user = create(:admin_user, password: "known")
      login(user)

      get "/news"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("News")
      end

      get "/news/new"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Create News Post")
      end

      expect {
        post "/news", params: {
          news: {
            content: "Sample news post",
          },
        }
      }.to change { News.count }.by(1)
      news = News.last

      aggregate_failures do
        expect(response).to redirect_to(news_index_path)
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("News post created.")
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("News")
        expect(response.body).to include("Sample news post")
      end

      get "/news/#{news.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit News Post")
      end

      patch "/news/#{news.id}", params: {
        news: {
          content: "Updated news post",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(news_index_path)
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("News post updated.")
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("News")
        expect(response.body).to include("Updated news post")
      end
    end
  end
end
