require "spec_helper"

RSpec.describe SubcontinuitiesController do
  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      user = create(:user)
      continuity = create(:continuity)
      expect(continuity.editable_by?(user)).to eq(false)
      login_as(user)

      get :new, params: { continuity_id: continuity.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works with continuity_id" do
      continuity = create(:continuity)
      login_as(continuity.creator)
      get :new, params: { continuity_id: continuity.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Section")
    end

    it "works without continuity_id" do
      login
      get :new
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Section")
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      user = create(:user)
      continuity = create(:continuity)
      expect(continuity.editable_by?(user)).to eq(false)
      login_as(user)

      post :create, params: { subcontinuity: {continuity_id: continuity.id} }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "requires valid section" do
      continuity = create(:continuity)
      login_as(continuity.creator)
      post :create, params: { subcontinuity: {continuity_id: continuity.id} }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Section could not be created.")
    end

    it "requires valid continuity for section" do
      continuity = create(:continuity)
      login_as(continuity.creator)
      post :create, params: { subcontinuity: {name: 'fake'} }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Section could not be created.")
    end

    it "succeeds" do
      continuity = create(:continuity)
      login_as(continuity.creator)
      section_name = 'ValidSection'
      post :create, params: { subcontinuity: {continuity_id: continuity.id, name: section_name} }
      expect(response).to redirect_to(edit_continuity_url(continuity))
      expect(flash[:success]).to eq("New section, #{section_name}, has successfully been created for #{continuity.name}.")
      expect(assigns(:subcontinuity).name).to eq(section_name)
    end
  end

  describe "GET show" do
    it "requires valid section" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "does not require login" do
      section = create(:subcontinuity)
      posts = Array.new(2) { create(:post, continuity: section.continuity, section: section) }
      create(:post)
      create(:post, continuity: section.continuity)
      get :show, params: { id: section.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq(section.name)
      expect(assigns(:posts)).to match_array(posts)
    end

    it "works with login" do
      login
      section = create(:subcontinuity)
      posts = Array.new(2) { create(:post, continuity: section.continuity, section: section) }
      create(:post)
      create(:post, continuity: section.continuity)
      get :show, params: { id: section.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq(section.name)
      expect(assigns(:posts)).to match_array(posts)
    end

    it "orders posts correctly" do
      continuity = create(:continuity)
      section = create(:subcontinuity, continuity: continuity)
      post5 = create(:post, continuity: continuity, section: section)
      post1 = create(:post, continuity: continuity, section: section)
      post4 = create(:post, continuity: continuity, section: section)
      post3 = create(:post, continuity: continuity, section: section)
      post2 = create(:post, continuity: continuity, section: section)
      post1.update!(section_order: 1)
      post2.update!(section_order: 2)
      post3.update!(section_order: 3)
      post4.update!(section_order: 4)
      post5.update!(section_order: 5)
      get :show, params: { id: section.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq(section.name)
      expect(assigns(:posts)).to eq([post1, post2, post3, post4, post5])
    end

    it "calculates OpenGraph data" do
      user = create(:user, username: 'John Doe')
      continuity = create(:continuity, name: 'continuity', creator: user, writers: [create(:user, username: 'Jane Doe')])
      section = create(:subcontinuity, name: 'section', continuity: continuity, description: "test description")
      create(:post, subject: 'title', user: user, continuity: continuity, section: section)
      get :show, params: { id: section.id }

      meta_og = assigns(:meta_og)
      expect(meta_og.keys).to match_array([:url, :title, :description])
      expect(meta_og[:url]).to eq(subcontinuity_url(section))
      expect(meta_og[:title]).to eq('continuity » section')
      expect(meta_og[:description]).to eq("Jane Doe, John Doe – 1 post\ntest description")
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid section" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "requires permission" do
      section = create(:subcontinuity)
      login
      get :edit, params: { id: section.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works" do
      section = create(:subcontinuity)
      login_as(section.continuity.creator)
      get :edit, params: { id: section.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq("Edit #{section.name}")
      expect(assigns(:subcontinuity)).to eq(section)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires continuity permission" do
      user = create(:user)
      login_as(user)
      subcontinuity = create(:subcontinuity)
      expect(subcontinuity.continuity).not_to be_editable_by(user)

      put :update, params: { id: subcontinuity.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "requires valid params" do
      subcontinuity = create(:subcontinuity)
      login_as(subcontinuity.continuity.creator)
      put :update, params: { id: subcontinuity.id, subcontinuity: {name: ''} }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq("Section could not be updated.")
    end

    it "succeeds" do
      subcontinuity = create(:subcontinuity, name: 'TestSection1')
      login_as(subcontinuity.continuity.creator)
      section_name = 'TestSection2'
      put :update, params: { id: subcontinuity.id, subcontinuity: {name: section_name} }
      expect(response).to redirect_to(subcontinuity_path(subcontinuity))
      expect(subcontinuity.reload.name).to eq(section_name)
      expect(flash[:success]).to eq("#{section_name} has been successfully updated.")
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid section" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "requires permission" do
      section = create(:subcontinuity)
      login
      delete :destroy, params: { id: section.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works" do
      section = create(:subcontinuity)
      login_as(section.continuity.creator)
      delete :destroy, params: { id: section.id }
      expect(response).to redirect_to(edit_continuity_url(section.continuity))
      expect(flash[:success]).to eq("Section deleted.")
      expect(Subcontinuity.find_by_id(section.id)).to be_nil
    end

    it "handles destroy failure" do
      section = create(:subcontinuity)
      post = create(:post, user: section.continuity.creator, continuity: section.continuity, section: section)
      login_as(section.continuity.creator)
      expect_any_instance_of(Subcontinuity).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: section.id }
      expect(response).to redirect_to(subcontinuity_url(section))
      expect(flash[:error]).to eq({message: "Section could not be deleted.", array: []})
      expect(post.reload.section).to eq(section)
    end
  end
end
