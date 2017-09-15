require "spec_helper"

RSpec.describe BugsController do
  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      data = {fake: 'abc'}
      user_id = login
      user = User.find(user_id)
      params = data.merge(controller: 'bugs', action: 'create', user_id: user.id).stringify_keys
      expect(ExceptionNotifier).to receive(:notify_exception).with(an_instance_of(Icon::UploadError), data: params)
      post :create, params: data
      expect(response.status).to eq(200)
      expect(response.json).to eq({})
    end
  end
end
