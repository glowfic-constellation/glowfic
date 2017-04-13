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
        view = PostView.create(user: user, post: create(:post))
        login_as(user)
        get :show, id: 'daily'
      end
    end
  end

  describe "#posts_for" do
    default_zone = Time.zone
    {
      # 2017-11-05 10:00, clock goes back in Eastern
      "without timezone" => [default_zone, [2017, 11, 05, 10, 00]],
      # 2017-10-29 10:00, clock goes back in GMT/BST
      "with timezone" => ["Europe/London", [2017, 10, 29, 10, 00]]
    }.each do |name, data|
      zone = data.first
      dst_day_params = data.last
      context name do
        before(:each) { Time.zone = zone }
        after(:each) { Time.zone = default_zone }
        it "should work on a regular day" do
          time = Time.zone.local(2017, 01, 02, 10, 00) # 2017-01-02 10:00
          day = time.beginning_of_day
          shown_posts = Array.new(24) do |i| # 0 .. 23
            step = day + i.hours
            Timecop.freeze(step) { create(:post) }
          end
          shown_posts.each do |post|
            expect(post.tagged_at).to be_between(day, day.end_of_day).inclusive
          end

          hidden_post1 = Timecop.freeze(day - 1.hour) { create(:post) }
          hidden_post2 = Timecop.freeze(day.end_of_day + 1.hour) { create(:post) }
          expect(hidden_post1.tagged_at).not_to be_between(day, day.end_of_day).inclusive
          expect(hidden_post2.tagged_at).not_to be_between(day, day.end_of_day).inclusive

          expect(controller.send(:posts_for, time)).to match_array(shown_posts)
        end

        it "should work on a daylight change day" do
          time = Time.zone.local(*dst_day_params)
          # clock goes back; 25 hours in the day
          day = time.beginning_of_day
          shown_posts = Array.new(25) do |i| # 0 .. 24
            step = day + i.hours
            Timecop.freeze(step) { create(:post) }
          end
          shown_posts.each do |post|
            expect(post.tagged_at).to be_between(day, day.end_of_day).inclusive
          end

          hidden_post1 = Timecop.freeze(day - 1.hour) { create(:post) }
          hidden_post2 = Timecop.freeze(day.end_of_day + 1.hour) { create(:post) }
          expect(hidden_post1.tagged_at).not_to be_between(day, day.end_of_day).inclusive
          expect(hidden_post2.tagged_at).not_to be_between(day, day.end_of_day).inclusive

          expect(controller.send(:posts_for, time)).to match_array(shown_posts)
        end
      end
    end
  end
end
