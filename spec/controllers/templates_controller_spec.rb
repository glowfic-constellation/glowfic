require "spec_helper"

RSpec.describe TemplatesController do
  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "works" do
      login
      get :new
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq("New Template")
      expect(assigns(:template)).to be_a_new_record
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      login
      post :create
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("Your template could not be saved.")
      expect(assigns(:page_title)).to eq("New Template")
      expect(assigns(:template)).not_to be_valid
      expect(assigns(:template)).to be_a_new_record
    end

    it "works" do
      login
      post :create, template: {name: 'testtest'}
      created = Template.last
      expect(response).to redirect_to(template_url(created))
      expect(flash[:success]).to eq("Template saved successfully.")
    end
  end

  describe "GET show" do
    it "requires valid template" do
      get :show, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "works logged in" do
      login
      get :show, id: create(:template).id
      expect(response).to have_http_status(200)
    end

    it "works logged out" do
      get :show, id: create(:template).id
      expect(response).to have_http_status(200)
    end

    it "sets correct variables" do
      template = create(:template)
      char1 = create(:character, user: template.user, template: template)
      char2 = create(:character, user: template.user, template: template)
      non_char = create(:character)
      template_post = create(:post, user: template.user, character: char1)
      reply_post = create(:post)
      create(:reply, post: reply_post, user: template.user, character: char2)
      create(:post, character: non_char, user: non_char.user)

      get :show, id: template.id
      expect(assigns(:page_title)).to eq(template.name)
      expect(assigns(:posts).map(&:id)).to eq([reply_post.id, template_post.id])
      expect(assigns(:user)).to eq(template.user)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid template" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "requires your template" do
      template = create(:template)
      login
      get :edit, id: template.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("That is not your template.")
    end

    it "works" do
      template = create(:template)
      login_as(template.user)
      get :edit, id: template.id
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq("Edit Template: #{template.name}")
      expect(assigns(:template)).to eq(template)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid template" do
      login
      put :update, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "requires your template" do
      template = create(:template)
      login
      put :update, id: template.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("That is not your template.")
    end

    it "requires valid params" do
      template = create(:template)
      login_as(template.user)
      put :update, id: template.id, template: {name: ''}
      expect(assigns(:template)).not_to be_valid
      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq("Your template could not be saved.")
    end

    it "works" do
      template = create(:template)
      new_name = template.name + 'new'
      login_as(template.user)
      put :update, id: template.id, template: {name: new_name}
      expect(response).to redirect_to(template_url(template))
      expect(flash[:success]).to eq("Template saved successfully.")
      expect(template.reload.name).to eq(new_name)
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid template" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "requires your template" do
      user = create(:user)
      login_as(user)
      template = create(:template)
      delete :destroy, id: template.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("That is not your template.")
    end

    it "succeeds" do
      template = create(:template)
      login_as(template.user)
      delete :destroy, id: template.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:success]).to eq("Template deleted successfully.")
    end
  end
end
