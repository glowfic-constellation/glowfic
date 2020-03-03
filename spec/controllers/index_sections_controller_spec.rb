require "spec_helper"

RSpec.describe IndexSectionsController do
  let(:klass) { IndexSection }
  let(:parent_klass) { Index }
  let(:redirect_override) { indexes_url }
  let(:parent_redirect_override) { index_url(parent) }

  describe "GET new" do
    let(:klass) { Index }

    include_examples 'GET new validations'

    it "works with index_id" do
      index = create(:index)
      login_as(index.user)
      get :new, params: { index_id: index.id }
      expect(response).to have_http_status(200)
    end
  end

  describe "POST create" do
    include_examples 'POST create with parent validations'

    it "succeeds" do
      index = create(:index)
      login_as(index.user)
      section_name = 'ValidSection'
      post :create, params: { index_section: {index_id: index.id, name: section_name} }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:success]).to eq("New section, #{section_name}, created for #{index.name}.")
      expect(assigns(:section).name).to eq(section_name)
    end
  end

  describe "GET show" do
    include_examples 'GET show validations'
  end

  describe "GET edit" do
    include_examples 'GET edit with parent validations'
  end

  describe "PUT update" do
    include_examples 'PUT update with parent validations'

    it "succeeds" do
      index_section = create(:index_section, name: 'TestSection1')
      login_as(index_section.index.user)
      section_name = 'TestSection2'
      put :update, params: { id: index_section.id, index_section: {name: section_name} }
      expect(response).to redirect_to(index_path(index_section.index))
      expect(index_section.reload.name).to eq(section_name)
      expect(flash[:success]).to eq("Index section updated.")
    end
  end

  describe "DELETE destroy" do
    include_examples 'DELETE destroy validations'

    it "handles destroy failure" do
      section = create(:index_section)
      index = section.index
      login_as(index.user)
      expect_any_instance_of(IndexSection).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: section.id }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:error]).to eq("Index section could not be deleted.")
      expect(index.reload.index_sections).to eq([section])
    end
  end
end
