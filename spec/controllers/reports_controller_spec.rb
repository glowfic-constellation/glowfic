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
      post = create(:post)
      post.mark_read(user)
      time = post.last_read(user)
      login_as(user)
      get :show, id: 'daily'
      expect(response).to have_http_status(200)
      expect(assigns(:board_views)).to be_empty
      expect(assigns(:opened_ids)).to match_array([post.id])
      expect(assigns(:opened_posts).length).to eq(1)
      expect(assigns(:opened_posts).first.read_at).to be_the_same_time_as(time)
    end

    it "succeeds with monthly" do
      get :show, id: 'monthly'
      expect(response).to have_http_status(200)
    end

    context "with views" do
      render_views

      it "works" do
        3.times do create(:post) end
        Post.last.user.update_attributes(moiety: 'abcdef')
        create(:post, num_replies: 4, created_at: 2.days.ago)
        get :show, id: 'daily'
      end

      it "works with logged in" do
        user = create(:user)
        DailyReport.mark_read(user, 3.day.ago.to_date)
        view = PostView.create(user: user, post: create(:post))
        login_as(user)
        get :show, id: 'daily'
      end
    end

    context "reading" do
      before(:each) do
        Time.zone = "UTC"
      end

      it "does not mark read for today's unfinished report" do
        user = create(:user)
        expect(user.report_view).to be_nil
        login_as(user)
        get :show, id: 'daily'
        expect(user.reload.report_view).to be_nil
      end

      it "marks read for previous days" do
        user = create(:user)
        expect(user.report_view).to be_nil
        login_as(user)
        get :show, id: 'daily', day: 2.days.ago.to_date.to_s
        expect(user.reload.report_view).not_to be_nil
        expect(user.report_view.read_at.to_date).to eq(2.days.ago.to_date)
      end

      it "does not mark read for ignoring users" do
        user = create(:user, ignore_unread_daily_report: true)
        expect(user.report_view).to be_nil
        login_as(user)
        get :show, id: 'daily', day: 2.days.ago.to_date.to_s
        expect(user.report_view).to be_nil
      end

      it "marks read for previous days when already read once" do
        user = create(:user)
        expect(user.report_view).to be_nil
        DailyReport.mark_read(user, 3.day.ago.to_date)
        login_as(user)
        get :show, id: 'daily', day: 2.days.ago.to_date.to_s
        expect(user.reload.report_view).not_to be_nil
        expect(user.report_view.read_at.to_date).to eq(2.days.ago.to_date)
      end

      it "does not mark read if you've read more recently" do
        user = create(:user)
        expect(user.report_view).to be_nil
        DailyReport.mark_read(user, 2.day.ago.to_date)
        login_as(user)
        get :show, id: 'daily', day: 3.days.ago.to_date.to_s
        expect(user.reload.report_view).not_to be_nil
        expect(user.report_view.read_at.to_date).to eq(2.days.ago.to_date)
      end
    end
  end
end
