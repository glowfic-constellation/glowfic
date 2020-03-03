require "spec_helper"

RSpec.describe IndexesController do
  let(:klass) { Index }

  describe "GET index" do
    include_examples 'GET index validations'
  end

  describe "GET new" do
    include_examples 'GET new validations'
  end

  describe "POST create" do
    include_examples 'POST create validations'

    it "succeeds" do
      login
      name = 'ValidSection'
      post :create, params: { index: {name: name} }
      expect(response).to redirect_to(index_url(assigns(:index)))
      expect(flash[:success]).to eq("Index created!")
      expect(assigns(:index).name).to eq(name)
    end
  end

  describe "GET show" do
    include_examples 'GET show validations'

    it "requires visible index" do
      index = create(:index, privacy: Concealable::PRIVATE)
      get :show, params: { id: index.id }
      expect(response).to redirect_to(indexes_url)
      expect(flash[:error]).to eq('You do not have permission to view this index.')
    end

    it "orders sectionless posts correctly" do
      index = create(:index)
      post1 = create(:index_post, index: index)
      post2 = create(:index_post, index: index)
      post3 = create(:index_post, index: index)
      post2.update!(section_order: 0)
      post3.update!(section_order: 1)
      post1.update!(section_order: 2)
      get :show, params: { id: index.id }
      expect(assigns(:sectionless)).to eq([post2.post, post3.post, post1.post])
    end
  end

  describe "GET edit" do
    include_examples 'GET edit validations'
  end

  describe "PUT update" do
    include_examples 'PUT update validations'

    it "succeeds" do
      index = create(:index)
      login_as(index.user)
      name = 'ValidSection' + index.name
      put :update, params: { id: index.id, index: {name: name} }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:success]).to eq("Index updated.")
      expect(index.reload.name).to eq(name)
    end
  end

  describe "DELETE destroy" do
    include_examples 'DELETE destroy validations'

    it "handles destroy failure" do
      index = create(:index)
      section = create(:index_section, index: index)
      login_as(index.user)
      expect_any_instance_of(Index).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: index.id }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:error]).to eq("Index could not be deleted.")
      expect(section.reload.index).to eq(index)
    end
  end
end
