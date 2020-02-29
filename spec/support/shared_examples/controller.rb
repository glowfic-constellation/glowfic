module SharedExamples::Controller
  RSpec.shared_examples "GET new validations" do |object, klass|
    let(:user) { create(:user) }
    let(:key) { klass.foreign_key }

    it "requires login" do
      get :new, params: { key => -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid #{klass}" do
      login_as(user)
      get :new, params: { ley => -1 }
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
end
