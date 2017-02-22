require "spec_helper"

RSpec.describe UsersController do
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

    context "with moieties" do
      render_views

      it "displays the name" do
        user = create(:user, moiety: 'fed123', moiety_name: 'moietycolor')
        get :index
        expect(response.body).to include('moietycolor')
        expect(response.body).to include('fed123')
      end
    end
  end

  describe "GET new" do
    it "succeeds when logged out" do
      get :new
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "complains when logged in" do
      login
      post :create
      expect(response).to redirect_to(boards_path)
      expect(flash[:error]).to eq('You are already logged in.')
    end
  end

  describe "POST create" do
    it "complains when logged in" do
      login
      post :create
      expect(response).to redirect_to(boards_path)
      expect(flash[:error]).to eq('You are already logged in.')
    end

    it "requires beta secret" do
      post :create
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("This is in beta. Please come back later.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "requires valid fields" do
      post :create, secret: "ALLHAILTHECOIN"
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("There was a problem completing your sign up.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "signs you up" do
      user = build(:user).attributes.merge(password: 'testpassword', password_confirmation: 'testpassword')
      expect {
        post :create, {secret: "ALLHAILTHECOIN"}.merge(user: user)
      }.to change{User.count}.by(1)
      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("User created! You have been logged in.")
      expect(assigns(:current_user)).not_to be_nil
      expect(assigns(:current_user).username).to eq(user['username'])
    end
  end

  describe "GET show" do
    it "requires valid user" do
      get :show, id: -1
      expect(response).to redirect_to(users_url)
      expect(flash[:error]).to eq("User could not be found.")
    end

    it "works when logged out" do
      user = create(:user)
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "works when logged in as someone else" do
      user = create(:user)
      login
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "works when logged in as yourself" do
      user = create(:user)
      login_as(user)
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "sets the correct variables" do
      user = create(:user)
      posts = 3.times.collect do create(:post, user: user) end
      create(:post)
      get :show, id: user.id
      expect(assigns(:page_title)).to eq(user.username)
      expect(assigns(:posts).to_a).to match_array(posts)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds" do
      login
      get :edit, id: -1
      expect(response.status).to eq(200)
    end

    context "with views" do
      render_views

      it "displays options" do
        login
        get :edit, id: -1
      end
    end
  end

  describe "PUT update" do
    it "has more tests" do
      skip
    end
  end

  describe "POST username" do
    it "complains when logged in" do
      skip "TODO not yet implemented"
    end

    it "requires username" do
      post :username
      expect(response.json['error']).to eq("No username provided.")
    end

    it "finds user" do
      user = create(:user)
      post :username, username: user.username
      expect(response.json['username_free']).not_to be_true
    end

    it "finds free username" do
      user = create(:user)
      post :username, username: user.username + 'nope'
      expect(response.json['username_free']).to be_true
    end
  end

  describe "PUT password" do
    it "has more tests" do
      skip
    end
  end
end
