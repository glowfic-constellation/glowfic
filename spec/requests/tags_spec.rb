RSpec.describe "Tags" do
  describe "editing" do
    it "updates a tag" do
      user = login
      setting = create(:setting, user: user)
      get "/tags/#{setting.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit Setting")
      end

      patch "/tags/#{setting.id}", params: {
        tag: {
          name: "test tag 1",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(tag_path(setting))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Tag updated.")

        setting.reload
        expect(setting.name).to eq("test tag 1")
      end
    end
  end
end
