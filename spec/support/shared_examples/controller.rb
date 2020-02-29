module SharedExamples
module Controller
  RSpec.shared_examples "GET new validations" do |klass|
    let(:user) { create(:user) }
    let(:object) { create(klass) }
    let(:key) { klass.foreign_key }

    it "requires login" do
      get :new, params: { key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{klass}" do
      login_as(user)
      get :new, params: { key => -1 }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("#{klass.capitalize} could not be found.")
    end

    it "requires your #{klass}" do
      login_as(user)
      get :new, params: { key => object.id }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("That is not your #{klass}.")
    end
  end

  RSpec.shared_examples "POST create validations" do |klass, name|
    let(:self_key) { klass.foreign_key }
    let(:klass_name) { (name || klass).capitalize }

    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with missing params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_name} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_name}")
      expect(assigns(klass)).to be_a_new_record
    end

    it "fails with invalid params" do
      login
      post :create, params: { self_key => {name: ''} }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_name} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_name}")
      expect(assigns(klass)).to be_a_new_record
    end
  end

  RSpec.shared_examples "POST create with parent validations" do |parent_klass, klass, name|
    let(:user) { create(:user) }
    let(:parent) { create(parent_klass) }
    let(:parent_key) { parent_klass.foreign_key }
    let(:self_key) { klass.foreign_key }
    let(:klass_name) { (name || klass).capitalize }
    let(:assign) { (name || klass).downcase.to_sym }

    it "requires login" do
      post :create, params: { parent_key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{parent_klass}" do
      login_as(user)
      post :create, params: { parent_key => -1 }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("#{parent_klass.capitalize} could not be found.")
    end

    it "requires your #{parent_klass}" do
      login_as(user)
      post :create, params: { parent_key => parent.id }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("That is not your #{parent_klass}.")
    end

    it "fails with missing params" do
      login_as(parent.user)
      post :create, params: { parent_key => parent.id }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_name} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_name}: #{parent.name}")
      expect(assigns(assign)).to be_a_new_record
    end

    it "fails with invalid params" do
      login_as(parent.user)
      post :create, params: { parent_key => parent.id, self_key => {name: ''} }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_name} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_name}: #{parent.name}")
      expect(assigns(assign)).to be_a_new_record
    end
  end

  RSpec.shared_examples "GET show validations" do |klass, name|
    let(:klass_name) { (name || klass).capitalize }
    let(:object) { create(klass) }

    it "requires valid #{klass}" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("#{name.capitalize} could not be found.")
    end

    it "works logged in" do
      login
      get :show, params: { id: object.id }
      expect(response.status).to eq(200)
    end

    it "works logged out" do
      get :show, params: { id: object.id }
      expect(response.status).to eq(200)
    end
  end

  RSpec.shared_examples 'GET edit validations' do |klass, name|
    let(:klass_name) { (name || klass).downcase }
    let(:object) { create(klass) }

    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{klass}" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("#{klass_name.capitalize} could not be found.")
    end

    it "requires permission" do
      login
      get :edit, params: { id: object.id }
      expect(response).to redirect_to(url_for(object))
      expect(flash[:error]).to eq("You do not have permission to edit that #{klass_name}.")
    end

    it "succeeds" do
      login_as(object.user)
      get :edit, params: { id: object.id }
      expect(response.status).to eq(200)
    end
  end

  RSpec.shared_examples 'PUT update validations' do |klass, name|
    let(:klass_name) { (name || klass).downcase }
    let(:object) { create(klass) }
    let(:key) { klass.foreign_key }

    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{klass}" do
      login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("#{klass_name.capitalize} could not be found.")
    end

    it "requires permission" do
      login
      put :update, params: { id: object.id }
      expect(response).to redirect_to(url_for(object))
      expect(flash[:error]).to eq("You do not have permission to edit that #{klass_name}.")
    end

    it "requires valid params" do
      login_as(object.user)
      put :update, params: { id: object.id, klass => {name: ''} }
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("#{klass_name.capitalize} could not be created.")
      expect(flash[:error][:array]).to be_present
    end
  end

  RSpec.shared_examples 'DELETE destroy validations' do |parent_klass, klass, name|
    let(:user) { create(:user) }
    let(:parent) { create(parent_klass) }
    let(:parent_key) { parent_klass.foreign_key }
    klass_name = (name || klass).downcase

    it "requires login" do
      delete :destroy, params: { id: -1, parent_key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{parent_klass}" do
      login_as(user)
      delete :destroy, params: { id: -1, parent_key => -1 }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires your #{parent_klass}" do
      login_as(user)
      expect(parent.user_id).not_to eq(user.id)
      delete :destroy, params: { id: -1, parent_key => parent.id }
      expect(response).to redirect_to(redirect)
      expect(flash[:error]).to eq("That is not your character.")
    end

    it "requires valid #{klass_name}" do
      login_as(parent.user)
      delete :destroy, params: { id: -1, parent_key => parent.id }
      expect(response).to redirect_to(parent_redirect)
      expect(flash[:error]).to eq("Alias could not be found.")
    end

    it "requires #{klass_name} to match #{parent}" do
      child = create(:alias)
      login_as(parent.user)
      expect(parent.id).not_to eq(child[parent_key])
      delete :destroy, params: { id: child.id, parent_key => parent.id }
      expect(response).to redirect_to(parent_redirect)
      expect(flash[:error]).to eq("Alias could not be found for that character.")
    end
  end
end
end
