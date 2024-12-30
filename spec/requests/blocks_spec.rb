RSpec.describe "Blocks" do
  describe "creation" do
    it "creates a new block and shows on the index list" do
      other_user = create(:user, username: "Evil User")
      self_user = create(:user, password: known_test_password)
      login(self_user)

      get "/blocks"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("Blocked Users")
        expect(response.body).to include("+ Block User")
      end

      get "/blocks/new"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Block User")
        expect(response.body).to include("Interactions")
      end

      expect {
        post "/blocks", params: {
          block: {
            blocked_user_id: other_user.id,
            block_interactions: false,
            hide_them: "posts",
            hide_me: "posts",
          },
        }
      }.to change { Block.count }.by(1)
      block = Block.last

      aggregate_failures do
        expect(response).to redirect_to(blocks_path)
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("User blocked.")

        expect(block.blocking_user).to eq(self_user)
        expect(block.blocked_user).to eq(other_user)
        expect(block.block_interactions).to eq(false)
        expect(block.hide_them).to eq("posts")
        expect(block.hide_me).to eq("posts")
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(response.body).to include("Blocked Users")
        expect(response.body).to include("Evil User")
        expect(response.body).to include("/blocks/#{block.id}/edit")
      end

      get "/blocks/#{block.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Block on Evil User")
        expect(response.body).to match(/User.*Evil User/m)
      end

      put "/blocks/#{block.id}", params: {
        block: {
          block_interactions: true,
          hide_them: "all",
          hide_me: "all",
        },
      }

      aggregate_failures do
        expect(response).to redirect_to(blocks_path)
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Block updated.")

        block.reload
        expect(block.block_interactions).to eq(true)
        expect(block.hide_them).to eq("all")
        expect(block.hide_me).to eq("all")
      end
    end
  end
end
