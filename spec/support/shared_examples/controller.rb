include Rails.application.routes.url_helpers
default_url_options[:host] = 'test.host'

module SharedExamples
module Controller
  RSpec.shared_context "shared context" do |klass, name|
    let(:index_redirect) do
      return redirect_override if defined? redirect_override
      url_for(controller: klass.tableize)
    end
    let(:self_redirect) { url_for(object) }
    let(:user) { create(:user) }
    let(:object) { create(klass) }
    let(:self_key) { klass.foreign_key }
    let(:klass_name) { (name || klass).downcase }
  end

  RSpec.shared_context "shared parent context" do |parent_klass, klass, name|
    include_context "shared context", klass, name

    let(:parent) { object.send(parent_klass) }
    let(:parent_key) { parent_klass.foreign_key }
  end

  RSpec.shared_examples "GET index validations" do
    it "succeeds when logged out" do
      get :index
      expect(response.status).to eq(200)
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response.status).to eq(200)
    end
  end

  RSpec.shared_examples "GET new validations" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end
  end

  RSpec.shared_examples "GET new with parent validations" do |klass, name|
    include_context "shared context", klass, name

    it "requires login" do
      get :new, params: { self_key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{klass}" do
      login_as(user)
      get :new, params: { self_key => -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{name.capitalize} could not be found.")
    end

    it "requires your #{klass}" do
      login_as(user)
      get :new, params: { self_key => object.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("That is not your #{name}.").or eq("You do not have permission to edit this #{name}.")
    end
  end

  RSpec.shared_examples "POST create validations" do |klass, name|
    include_context "shared context", klass, name

    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with missing params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_name.capitalize} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_name.capitalize}")
      expect(assigns(klass)).to be_a_new_record
    end

    it "fails with invalid params" do
      login
      post :create, params: { self_key => {name: ''} }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_name.capitalize} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_name.capitalize}")
      expect(assigns(klass)).to be_a_new_record
    end
  end

  RSpec.shared_examples "POST create with parent validations" do |parent_klass, parent_name, klass, name|
    let(:assign) do
      return :alias if klass == CharacterAlias
      klass.to_sym
    end

    include_context "shared parent context", parent_klass, klass, name

    it "requires login" do
      post :create, params: { parent_key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{parent_klass}" do
      login_as(user)
      post :create, params: { parent_key => -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{parent_name.capitalize} could not be found.")
    end

    it "requires your #{parent_klass}" do
      login_as(user)
      post :create, params: { parent_key => parent.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("That is not your #{parent_name}.").or eq("You do not have permission to edit this #{parent_name}.")
    end

    it "fails with missing params" do
      login_as(parent.user)
      post :create, params: { parent_key => parent.id }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_name.capitalize} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_name.capitalize}").or eq("New #{klass_name.capitalize}: #{parent.name}")
      expect(assigns(assign)).to be_a_new_record
    end

    it "fails with invalid params" do
      login_as(parent.user)
      post :create, params: { parent_key => parent.id, self_key => {name: ''} }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_name.capitalize} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_name.capitalize}").or eq("New #{klass_name.capitalize}: #{parent.name}")
      expect(assigns(assign)).to be_a_new_record
    end
  end

  RSpec.shared_examples "GET show validations" do |klass, name|
    include_context "shared context", klass, name

    it "requires valid #{klass}" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(index_redirect)
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

  RSpec.shared_examples 'GET edit validations shared' do |klass|
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{klass}" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{klass_name.capitalize} could not be found.")
    end

    it "requires permission" do
      login
      get :edit, params: { id: object.id }
      expect(response).to redirect_to(self_redirect)
      expect(flash[:error]).to eq("You do not have permission to edit that #{klass_name}.")
    end
  end

  RSpec.shared_examples 'GET edit validations' do |klass, name|
    include_context "shared context", klass, name
    include_examples 'GET edit validations shared', klass

    it "succeeds" do
      login_as(object.user)
      get :edit, params: { id: object.id }
      expect(response.status).to eq(200)
    end
  end

  RSpec.shared_examples 'GET edit with parent validations' do |parent_klass, klass, name|
    include_context "shared parent context", parent_klass, klass, name
    include_examples 'GET edit validations shared', klass

    it "succeeds" do
      login_as(parent.user)
      get :edit, params: { id: object.id }
      expect(response.status).to eq(200)
    end
  end

  RSpec.shared_examples 'PUT update validations shared' do |klass|
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{klass}" do
      login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{klass_name.capitalize} could not be found.")
    end

    it "requires permission" do
      login
      put :update, params: { id: object.id }
      expect(response).to redirect_to(self_redirect)
      expect(flash[:error]).to eq("You do not have permission to edit that #{klass_name}.")
    end
  end

  RSpec.shared_examples 'PUT update validations' do |klass, name|
    include_context "shared context", klass, name
    include_examples 'PUT update validations shared', klass

    it "requires valid params" do
      login_as(object.user)
      put :update, params: { id: object.id, klass => {name: ''} }
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("#{klass_name.capitalize} could not be updated.")
      expect(flash[:error][:array]).to be_present
    end
  end

  RSpec.shared_examples 'PUT update with parent validations' do |parent_klass, klass, name|
    include_context "shared parent context", parent_klass, klass, name
    include_examples 'PUT update validations shared', klass

    it "requires valid params" do
      login_as(parent.user)
      put :update, params: { id: object.id, klass => {name: ''} }
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("#{klass_name.capitalize} could not be updated.")
      expect(flash[:error][:array]).to be_present
    end
  end

  RSpec.shared_examples 'DELETE destroy validations' do |klass, name|
    include_context "shared context", klass, name

    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{klass}" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{klass_name.capitalize} could not be found.")
    end

    it "requires permission" do
      login
      delete :destroy, params: { id: object.id }
      expect(response).to redirect_to(self_redirect)
      expect(flash[:error]).to eq("You do not have permission to edit that #{klass_name}.")
    end

    it "succeeds" do
      login_as(object.creator)
      delete :destroy, params: { id: object.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:success]).to eq("#{klass_name.capitalize} deleted.")
      expect{object.reload}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  RSpec.shared_examples 'DELETE destroy with parent validations' do |parent_klass, klass, parent_name, name|
    let(:parent_redirect) do
      redirect_override if defined? redirect_override
      url_for(controller: parent_klass.tableize, action: 'edit', id: parent.id)
    end

    include_context "shared parent context", parent_klass, klass, name
    klass_name = (name || klass).downcase

    it "requires login" do
      delete :destroy, params: { id: -1, parent_key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires your #{parent_klass}" do
      login
      delete :destroy, params: { id: object.id, parent_key => parent.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("That is not your #{parent_name}.").or eq("You do not have permission to edit this #{parent_name}.")
    end

    it "requires valid #{klass_name}" do
      login_as(parent.user)
      delete :destroy, params: { id: -1, parent_key => parent.id }
      expect(response).to redirect_to(parent_redirect)
      expect(flash[:error]).to eq("#{klass.capitalize} could not be found.")
    end

    it "requires #{klass_name} to match #{parent_klass}" do
      child = create(klass)
      login_as(parent.user)
      expect(parent.id).not_to eq(child[parent_key])
      delete :destroy, params: { id: child.id, parent_key => parent.id }
      expect(response).to redirect_to(parent_redirect)
      expect(flash[:error]).to eq("Alias could not be found for that character.")
    end
  end
end
end
