require "spec_helper"

RSpec.describe ReportsController do
  describe "GET index" do
    it "succeeds when logged out" do
      get :index
      expect(response).to have_http_status(200)
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response).to have_http_status(200)
    end
  end

  describe "GET show" do
    it "requires valid type" do
      get :show, id: -1
      expect(response).to redirect_to(reports_url)
      expect(flash[:error]).to eq("Could not identify the type of report.")
    end

    it "succeeds with daily" do
      get :show, id: 'daily'
      expect(response).to have_http_status(200)
    end

    it "sets variables with logged in daily" do
      user = create(:user)
      view = PostView.create(user: user, post: create(:post))
      login_as(user)
      get :show, id: 'daily'
      expect(response).to have_http_status(200)
      expect(assigns(:board_views)).to be_empty
      expect(assigns(:opened_ids)).to match_array([view.post_id])
      expect(assigns(:opened_posts).map(&:read_at)).to match_array([view.read_at])
    end

    it "succeeds with monthly" do
      get :show, id: 'monthly'
      expect(response).to have_http_status(200)
    end

    context "with views" do
      render_views

      it "works" do
        3.times do create(:post) end
        create(:post, num_replies: 4, created_at: 2.days.ago)
        get :show, id: 'daily'
      end

      it "works with logged in" do
        user = create(:user)
        view = PostView.create(user: user, post: create(:post))
        login_as(user)
        get :show, id: 'daily'
      end
    end
  end
end
