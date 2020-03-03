module SharedExamples
  def self.name_for(klass)
    case klass.to_s
      when 'CharacterAlias'
        'alias'
      when 'BoardSection'
        'section'
      when 'Board'
        'continuity'
      else
        klass.to_s.underscore.humanize(capitalize: false)
    end
  end
end

module SharedExamples::Controller
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  RSpec.shared_context "shared context" do
    let(:index_redirect) do
      return redirect_override if defined? redirect_override
      url_for(controller: klass.table_name)
    end
    let(:self_redirect) { url_for(object) }
    let(:user) { create(:user) }
    let(:object) { create(self_sym) }
    let(:self_sym) { klass.to_s.underscore.to_sym }
    let(:self_key) { klass.to_s.foreign_key }
    let(:klass_name) { SharedExamples.name_for(klass) }
    let(:klass_cname) { klass_name.capitalize }
  end

  RSpec.shared_context "shared parent context" do
    include_context "shared context"

    let(:parent) { object.send(parent_klass.to_s.underscore) }
    let(:parent_key) { parent_klass.to_s.foreign_key }
    let(:parent_name) { SharedExamples.name_for(parent_klass) }
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

  RSpec.shared_examples "GET new with parent validations" do
    include_context "shared context"

    it "requires login" do
      get :new, params: { self_key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid parent" do
      skip if klass == Board
      login_as(user)
      get :new, params: { self_key => -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{klass_cname} could not be found.")
    end

    it "requires your parent" do
      login_as(user)
      get :new, params: { self_key => object.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("That is not your #{klass_name}.").or eq("You do not have permission to edit this #{klass_name}.")
    end
  end

  RSpec.shared_examples "POST create validations" do
    include_context "shared context"

    let(:error_msg) do
      return error_msg_override if defined? error_msg_override
      "#{klass_cname} could not be created."
    end

    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with missing params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq(error_msg).or eq("Your #{klass_name} could not be saved because of the following problems:")
      expect(assigns(:page_title)).to eq("New #{klass_cname}")
      expect(assigns(self_sym)).to be_a_new_record
    end

    it "fails with invalid params" do
      login
      post :create, params: { self_key => {name: ''} }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq(error_msg).or eq("Your #{klass_name} could not be saved because of the following problems:")
      expect(assigns(:page_title)).to eq("New #{klass_cname}")
      expect(assigns(self_sym)).to be_a_new_record
    end
  end

  RSpec.shared_examples "POST create with parent validations" do
    let(:assign) do
      return :alias if klass == CharacterAlias
      self_sym
    end

    include_context "shared parent context"

    it "requires login" do
      post :create, params: { parent_key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid parent" do
      login_as(user)
      post :create, params: { parent_key => -1 }
      expect(response).to redirect_to(index_redirect).or render_template(:new)
      expect(flash[:error]).to eq("#{parent_name.capitalize} could not be found.")
        .or eq({
          message: "#{klass_cname} could not be created.",
          array: ["#{parent_klass.to_s.capitalize} must exist", "Name can't be blank"]
        })
    end

    it "requires your parent" do
      login_as(user)
      post :create, params: { parent_key => parent.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("That is not your #{parent_name}.").or eq("You do not have permission to edit this #{parent_name}.")
    end

    it "fails with missing params" do
      login_as(parent.user)
      post :create, params: { parent_key => parent.id }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_cname} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_cname}").or eq("New #{klass_cname}: #{parent.name}")
      expect(assigns(assign)).to be_a_new_record
    end

    it "fails with invalid params" do
      login_as(parent.user)
      post :create, params: { parent_key => parent.id, self_key => {name: ''} }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("#{klass_cname} could not be created.")
      expect(assigns(:page_title)).to eq("New #{klass_cname}").or eq("New #{klass_cname}: #{parent.name}")
      expect(assigns(assign)).to be_a_new_record
    end
  end

  RSpec.shared_examples "GET show validations" do
    include_context "shared context"

    it "requires valid instance" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(index_redirect).or redirect_to(root_url)
      expect(flash[:error]).to eq("#{klass_cname} could not be found.")
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

  RSpec.shared_examples 'GET edit validations shared' do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid instance" do
      login_as(user)
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{klass_cname} could not be found.")
    end
  end

  RSpec.shared_examples 'GET edit validations' do
    include_context "shared context"
    include_examples 'GET edit validations shared'

    it "requires permission" do
      login_as(user)
      get :edit, params: { id: object.id }
      expect(response).to redirect_to(self_redirect).or redirect_to(index_redirect)
      expect(flash[:error]).to eq("You do not have permission to edit that #{klass_name}.")
        .or eq("That is not your #{klass_name}.")
    end

    it "succeeds" do
      login_as(object.user)
      get :edit, params: { id: object.id }
      expect(response.status).to eq(200)
    end
  end

  RSpec.shared_examples 'GET edit with parent validations' do
    include_context "shared parent context"
    include_examples 'GET edit validations shared'

    it "requires permission" do
      login
      get :edit, params: { id: object.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("You do not have permission to edit this #{parent_name}.")
    end

    it "succeeds" do
      login_as(parent.user)
      get :edit, params: { id: object.id }
      expect(response.status).to eq(200)
    end
  end

  RSpec.shared_examples 'PUT update validations shared' do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid instance" do
      login_as(user)
      put :update, params: { id: -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{klass_cname} could not be found.")
    end
  end

  RSpec.shared_examples 'PUT update validations' do
    include_context "shared context"
    include_examples 'PUT update validations shared'

    let(:error_msg) do
      return error_msg_override if defined? error_msg_override
      "#{klass_cname} could not be updated."
    end

    it "requires permission" do
      login_as(user)
      put :update, params: { id: object.id }
      expect(response).to redirect_to(self_redirect).or redirect_to(index_redirect)
      expect(flash[:error]).to eq("You do not have permission to edit that #{klass_name}.")
        .or eq("That is not your #{klass_name}.")
    end

    it "requires valid params" do
      login_as(object.user)
      put :update, params: { id: object.id, self_sym => {name: ''} }
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq(error_msg).or eq("#{klass_cname} could not be saved.")
      expect(flash[:error][:array]).to be_present
    end
  end

  RSpec.shared_examples 'PUT update with parent validations' do
    include_context "shared parent context"
    include_examples 'PUT update validations shared'

    it "requires permission" do
      login
      put :update, params: { id: object.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("You do not have permission to edit this #{parent_name}.")
    end

    it "requires valid params" do
      login_as(parent.user)
      put :update, params: { id: object.id, self_sym => {name: ''} }
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("#{klass_cname} could not be updated.")
      expect(flash[:error][:array]).to be_present
    end
  end

  RSpec.shared_examples 'DELETE destroy validations' do
    include_context "shared context"

    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid instance" do
      login_as(user)
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{klass_cname} could not be found.")
    end

    it "requires permission" do
      login_as(user)
      delete :destroy, params: { id: object.id }
      expect(response).to redirect_to(self_redirect).or redirect_to(index_redirect)
      expect(flash[:error]).to eq("You do not have permission to edit that #{klass_name}.")
        .or eq("That is not your #{klass_name}.")
    end

    it "succeeds" do
      object = create(self_sym, user: user)
      login_as(user)
      delete :destroy, params: { id: object.id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:success]).to eq("#{klass_cname} deleted.").or eq("#{klass_cname} deleted successfully.")
      expect{object.reload}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  RSpec.shared_examples 'DELETE destroy with parent validations' do
    let(:parent_redirect) do
      return parent_redirect_override if defined? parent_redirect_override
      return redirect_override if defined? redirect_override
      url_for(controller: parent_klass.table_name, action: 'edit', id: parent.id)
    end

    include_context "shared parent context"

    it "requires login" do
      delete :destroy, params: { id: -1, parent_key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires your parent" do
      login_as(user)
      delete :destroy, params: { id: object.id, parent_key => create(parent_klass.to_s.underscore).id }
      expect(response).to redirect_to(index_redirect)
      expect(flash[:error]).to eq("That is not your #{parent_name}.").or eq("You do not have permission to edit this #{parent_name}.")
    end

    it "requires valid instance" do
      login_as(parent.user)
      delete :destroy, params: { id: -1, parent_key => parent.id }
      expect(response).to redirect_to(parent_redirect).or redirect_to(index_redirect)
      expect(flash[:error]).to eq("#{klass_cname} could not be found.")
    end

    it "requires instance to match parent" do
      child = create(self_sym)
      login_as(parent.user)
      expect(parent.id).not_to eq(child[parent_key])
      delete :destroy, params: { id: child.id, parent_key => parent.id }
      expect(response).to redirect_to(parent_redirect)
      expect(flash[:error]).to eq("Alias could not be found for that character.").or eq("You do not have permission to edit this #{parent_name}.")
    end
  end
end
