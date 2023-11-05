RSpec.describe "Icons" do
  describe "editing" do
    it "updates an icon" do
      user = login
      icon = create(:icon, user: user)
      get "/icons/#{icon.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit Icon")
        expect(response.body).to include("URL")
        expect(response.body).to include("Keyword")
        expect(response.body).to include("Credit")
      end

      patch "/icons/#{icon.id}", params: {
        icon: {
          url: "https://example.com/icon.png",
          keyword: "test icon 1",
          credit: "Test credit",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(icon_path(icon))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Icon updated.")

        icon.reload
        expect(icon.url).to eq("https://example.com/icon.png")
        expect(icon.keyword).to eq("test icon 1")
        expect(icon.credit).to eq("Test credit")
      end

      follow_redirect!
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("test icon 1")
        expect(response.body).to include("Test credit")
        expect(response.body).to include("https://example.com/icon.png")
      end
    end
  end
end
