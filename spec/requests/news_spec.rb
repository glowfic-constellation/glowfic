RSpec.describe "News" do
  describe "management" do
    it "creates a new news post and edits it successfully" do
      user = create(:admin_user, password: known_test_password)
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

  describe "index" do
    let!(:news) { create(:news) }
    let(:body) { response.parsed_body }

    it 'works' do
      login

      get "/news"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response).to render_template('news/_news')

        expect(body.at_css('.content-header').text.strip).to eq('Site News')
        expect(body.at_css('.message-content').text).to eq(news.content)
      end
    end

    it 'includes create post for mods' do
      user = create(:mod_user)
      login(user)

      get "/news"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response).to render_template('news/_news')

        expect(body.at_css('.content-header').text.strip).to eq("Site News\n+ New News Post")
      end
    end

    it 'includes create post for admins' do
      user = create(:admin_user)
      login(user)

      get "/news"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response).to render_template('news/_news')

        expect(body.at_css('.content-header').text.strip).to eq("Site News\n+ New News Post")
      end
    end

    it 'works with many news posts' do
      news_posts = create_list(:news, 3)
      login

      get "/news"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response).to render_template('news/_news')

        expect(body.at_css('.content-header').text.strip).to eq('Site News')
        expect(body.at_css('.message-content').text).to eq(news_posts[2].content)
        expect(body.at_css('.paginator .normal-pagination').text.strip).to eq('< Newer 1 2 3 4 Older >')
      end
    end

    it 'works with no news posts' do
      news.destroy!
      login

      get "/news"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response).not_to render_template('news/_news')

        expect(body.at_css('.content-header').text.strip).to eq('Site News')
        expect(body.css('.message-content')).to be_empty
      end
    end
  end
end
