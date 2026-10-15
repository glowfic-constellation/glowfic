RSpec.describe "Icon" do
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

  describe "replace" do
    it "does not run a query per gallery" do
      user = login
      icon = create(:icon, user: user)
      create(:gallery, user: user, icon_count: 1).icons << icon
      expect_constant_queries("/icons/#{icon.id}/replace") do
        2.times { create(:gallery, user: user, icon_count: 1).icons << icon }
      end
    end

    it "replaces post and reply icons" do
      user = login
      icon = create(:icon, user: user, keyword: "original")
      other = create(:icon, user: user, keyword: "target")

      model = create(:post, user: user, icon: icon)
      reply = create(:reply, post: model, user: user, icon: icon)
      unaffected = create(:reply, user: user)

      get "/icons/#{icon.id}/replace"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:replace)
        expect(response.body).to include("Replace All Uses of Icon")
        expect(response.body).to include("original")
        expect(response.body).to include("target")
      end

      post "/icons/#{icon.id}/do_replace", params: {
        icon_dropdown: other.id,
      }
      aggregate_failures do
        expect(response).to redirect_to(icon_path(icon))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("All uses of this icon will be replaced.")
      end

      perform_enqueued_jobs

      expect(model.reload.icon).to eq(other)
      expect(reply.reload.icon).to eq(other)
      expect(unaffected.reload.icon).not_to eq(other)
    end
  end
end
