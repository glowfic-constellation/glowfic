RSpec.describe TagWranglingsController do
  render_views

  let(:wrangler) { create(:wrangler_user) }
  let(:setting) { create(:setting) }

  def assign_scope
    create(:wrangling_assignment, user: wrangler, setting: setting)
  end

  describe "GET index" do
    it "requires login" do
      get :index
      expect(response).to redirect_to(root_url)
    end

    it "refuses an ordinary user" do
      login_as(create(:user))
      get :index
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq("You do not have permission to wrangle tags.")
    end

    it "refuses a mod" do
      login_as(create(:mod_user))
      get :index
      expect(response).to redirect_to(root_path)
    end

    it "succeeds for a wrangler" do
      assign_scope
      login_as(wrangler)
      get :index
      expect(response).to have_http_status(200)
    end

    it "succeeds for an admin with no assignments" do
      login_as(create(:admin_user))
      get :index
      expect(response).to have_http_status(200)
    end

    it "rejects an invalid type filter" do
      login_as(create(:admin_user))
      get :index, params: { type: 'NotAType' }
      expect(response).to redirect_to(tag_wranglings_path)
      expect(flash[:error]).to eq("Invalid filter")
    end

    it "shows only tags within a wrangler's scope" do
      assign_scope
      in_scope = create(:label)
      create(:post, settings: [setting], labels: [in_scope])
      out_of_scope = create(:label)
      login_as(wrangler)

      get :index
      expect(assigns(:tags)).to include(in_scope)
      expect(assigns(:tags)).not_to include(out_of_scope)
    end

    it "surfaces clusters of near-identical names" do
      login_as(create(:admin_user))
      create(:label, name: 'Bar Fight')
      create(:label, name: 'bar fights')
      create(:label, name: 'Unrelated')

      get :index, params: { type: 'Label' }

      expect(assigns(:clusters)).to be_present
      expect(assigns(:clusters).first[:names]).to match_array(['Bar Fight', 'bar fights'])
    end

    it "orders the queue by usage" do
      login_as(create(:admin_user))
      rare = create(:label)
      common = create(:label)
      create(:post, labels: [rare])
      create_list(:post, 3, labels: [common])

      get :index, params: { type: 'Label' }
      expect(assigns(:tags).first).to eq(common)
    end
  end

  describe "PATCH update" do
    before(:each) { assign_scope }

    it "marks a tag canonical" do
      login_as(wrangler)
      patch :update, params: { id: setting.id, commit_action: 'canonical' }
      expect(setting.reload).to be_canonical
    end

    it "marks a tag unwrangleable" do
      login_as(wrangler)
      patch :update, params: { id: setting.id, commit_action: 'unwrangleable' }
      expect(setting.reload).to be_unwrangleable
    end

    it "merges as a synonym by default" do
      target = create(:setting)
      create(:wrangling_assignment, user: wrangler, setting: target)
      login_as(wrangler)

      patch :update, params: { id: setting.id, commit_action: 'merge', merger_id: target.id }

      expect(setting.reload.merger).to eq(target)
      expect(Tag.find_by(id: setting.id)).to be_present
    end

    it "does not let a wrangler destroy the loser" do
      target = create(:setting)
      create(:wrangling_assignment, user: wrangler, setting: target)
      login_as(wrangler)

      patch :update, params: { id: setting.id, commit_action: 'merge', merger_id: target.id, destroy_loser: '1' }

      expect(Tag.find_by(id: setting.id)).to be_present
      expect(setting.reload.merger).to eq(target)
    end

    it "lets an admin destroy the loser" do
      target = create(:setting)
      login_as(create(:admin_user))

      patch :update, params: { id: setting.id, commit_action: 'merge', merger_id: target.id, destroy_loser: '1' }

      expect(Tag.find_by(id: setting.id)).to be_nil
    end

    it "refuses a merge of a tag into itself" do
      login_as(create(:admin_user))
      patch :update, params: { id: setting.id, commit_action: 'merge', merger_id: setting.id, destroy_loser: '1' }

      expect(Tag.find_by(id: setting.id)).to be_present
      expect(flash[:error]).to eq("Merge target must be a different existing tag of the same type.")
    end

    it "refuses to mark a synonym canonical" do
      canonical = create(:setting, canonical: true)
      setting.update!(merger: canonical)
      login_as(create(:admin_user))

      patch :update, params: { id: setting.id, commit_action: 'canonical' }

      expect(setting.reload).not_to be_canonical
      expect(flash[:error]).to include("synonym cannot be marked canonical")
    end

    it "refuses to merge into a tag that is itself a synonym" do
      canonical = create(:setting, canonical: true)
      synonym = create(:setting)
      synonym.update!(merger: canonical)
      login_as(create(:admin_user))

      patch :update, params: { id: setting.id, commit_action: 'merge', merger_id: synonym.id }

      expect(setting.reload.merger).to be_nil
      expect(flash[:error]).to include("itself a synonym")
    end

    it "refuses a merge across types" do
      login_as(create(:admin_user))
      patch :update, params: { id: setting.id, commit_action: 'merge', merger_id: create(:label).id }
      expect(flash[:error]).to eq("Merge target must be a different existing tag of the same type.")
    end

    it "refuses a tag outside the wrangler's scope" do
      other = create(:setting)
      login_as(wrangler)
      patch :update, params: { id: other.id, commit_action: 'canonical' }
      expect(other.reload).not_to be_canonical
      expect(flash[:error]).to eq("You do not have permission to wrangle this tag.")
    end

    it "handles a missing tag" do
      login_as(wrangler)
      patch :update, params: { id: -1, commit_action: 'canonical' }
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "rejects an unknown action" do
      login_as(wrangler)
      patch :update, params: { id: setting.id, commit_action: 'explode' }
      expect(flash[:error]).to eq("Unrecognized wrangling action.")
    end
  end
end
