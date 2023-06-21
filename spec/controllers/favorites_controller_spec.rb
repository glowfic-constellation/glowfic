RSpec.describe FavoritesController do
  describe "GET index" do
    it "succeeds when logged out" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response.status).to eq(200)
    end

    it "has no posts when no favorites" do
      login
      get :index
      expect(assigns(:posts)).to be_empty
    end

    context "it only shows favorites" do
      let (:user) { create(:user) }
      let!(:user_post) { create(:post, user: user) }
      let!(:post) { create(:post) }
      let (:continuity) { create(:continuity, creator: user) }
      let!(:continuity_post) { create(:post, board: continuity) }
      let!(:continuity_user_post) { create(:post, board: continuity, user: user) }

      it "shows user's post when user is favorited" do
        favorite = create(:favorite, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([user_post, continuity_user_post])
      end

      it "shows post when post is favorited" do
        favorite = create(:favorite, favorite: post)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([post])
      end

      it "shows continuity posts when continuity is favorited" do
        favorite = create(:favorite, favorite: continuity)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([continuity_post, continuity_user_post])
      end

      it "shows both post and user post when post and user are favorited" do
        favorite = create(:favorite, favorite: post)
        favorite = create(:favorite, user: favorite.user, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([post, user_post, continuity_user_post])
      end

      it "shows both post and continuity post when post and continuity are favorited" do
        favorite = create(:favorite, favorite: post)
        favorite = create(:favorite, user: favorite.user, favorite: continuity)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([post, continuity_post, continuity_user_post])
      end

      it "shows user and continuity posts when continuity and user are favorited" do
        favorite = create(:favorite, favorite: user)
        favorite = create(:favorite, user: favorite.user, favorite: continuity)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([user_post, continuity_post, continuity_user_post])
      end

      it "does not duplicate posts if both a user post and user are favorited" do
        favorite = create(:favorite, favorite: user_post)
        favorite = create(:favorite, user: favorite.user, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([user_post, continuity_user_post])
      end

      it "does not duplicate posts if both a continuity post and continuity are favorited" do
        favorite = create(:favorite, favorite: continuity_post)
        favorite = create(:favorite, user: favorite.user, favorite: continuity)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([continuity_post, continuity_user_post])
      end

      it "handles all three types simultaneously" do
        favorite = create(:favorite, favorite: post)
        favorite = create(:favorite, user: favorite.user, favorite: continuity)
        favorite = create(:favorite, user: favorite.user, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([continuity_post, continuity_user_post, user_post, post])
      end

      it "orders favorited posts correctly" do
        user_post.update!(tagged_at: 2.minutes.ago)
        continuity_post.update!(tagged_at: 5.minutes.ago)
        continuity_user_post.update!(tagged_at: Time.zone.now)
        favorite = create(:favorite, favorite: continuity)
        create(:favorite, user: favorite.user, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to eq([continuity_user_post, user_post, continuity_post])
      end
    end
  end

  describe "POST create" do
    let(:user) { create(:user) }
    let(:fav_post) { create(:post) }

    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires a valid param" do
      login
      post :create
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq('No favorite specified.')
    end

    it "requires valid user if given" do
      login
      post :create, params: { user_id: -1 }
      expect(response).to redirect_to(users_path)
      expect(flash[:error]).to eq('User could not be found.')
    end

    it "requires valid post if given" do
      login
      post :create, params: { post_id: -1 }
      expect(response).to redirect_to(posts_path)
      expect(flash[:error]).to eq('Post could not be found.')
    end

    it "requires valid continuity if given" do
      login
      post :create, params: { board_id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq('Continuity could not be found.')
    end

    it "handles invalid favorite" do
      login_as(user)
      post :create, params: { user_id: user.id }
      expect(response).to redirect_to(user_path(user))
      expect(flash[:error][:message]).to eq('Your favorite could not be saved because of the following problems:')
    end

    it "favorites a user" do
      fav = create(:user)
      login_as(user)
      post :create, params: { user_id: fav.id }
      expect(Favorite.between(user, fav)).not_to be_nil
      expect(response).to redirect_to(user_url(fav))
      expect(flash[:success]).to eq("Your favorite has been saved.")
    end

    it "favorites a post" do
      login_as(user)
      post :create, params: { post_id: fav_post.id }
      expect(Favorite.between(user, fav_post)).not_to be_nil
      expect(response).to redirect_to(post_url(fav_post))
      expect(flash[:success]).to eq("Your favorite has been saved.")
    end

    it "favorites a post with a page/per redirect" do
      login_as(user)
      post :create, params: { post_id: fav_post.id, page: 3, per_page: 10 }
      expect(Favorite.between(user, fav_post)).not_to be_nil
      expect(response).to redirect_to(post_url(fav_post, page: 3, per_page: 10))
      expect(flash[:success]).to eq("Your favorite has been saved.")
    end

    it "favorites a post without a page redirect for first page" do
      login_as(user)
      post :create, params: { post_id: fav_post.id, page: 1, per_page: 25 }
      expect(Favorite.between(user, fav_post)).not_to be_nil
      expect(response).to redirect_to(post_url(fav_post))
      expect(flash[:success]).to eq("Your favorite has been saved.")
    end

    it "favorites a continuity" do
      user = create(:user)
      continuity = create(:continuity)
      login_as(user)
      post :create, params: { board_id: continuity.id }
      expect(Favorite.between(user, continuity)).not_to be_nil
      expect(response).to redirect_to(continuity_url(continuity))
      expect(flash[:success]).to eq("Your favorite has been saved.")
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid favorite" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(favorites_url)
      expect(flash[:error]).to eq("Favorite could not be found.")
    end

    it "requires your favorite" do
      login
      delete :destroy, params: { id: create(:favorite, favorite: create(:user)).id }
      expect(response).to redirect_to(favorites_url)
      expect(flash[:error]).to eq("That is not your favorite.")
    end

    it "destroys continuity favorite" do
      favorite = create(:favorite, favorite: create(:continuity))
      login_as(favorite.user)
      delete :destroy, params: { id: favorite.id }
      expect(response).to redirect_to(continuity_url(favorite.favorite))
      expect(flash[:success]).to eq("Favorite removed.")
    end

    it "destroys post favorite" do
      favorite = create(:favorite, favorite: create(:post))
      login_as(favorite.user)
      delete :destroy, params: { id: favorite.id }
      expect(response).to redirect_to(post_url(favorite.favorite))
      expect(flash[:success]).to eq("Favorite removed.")
    end

    it "destroys user favorite" do
      favorite = create(:favorite, favorite: create(:user))
      login_as(favorite.user)
      delete :destroy, params: { id: favorite.id }
      expect(response).to redirect_to(user_url(favorite.favorite))
      expect(flash[:success]).to eq("Favorite removed.")
    end

    it "handles destroy failure" do
      favorite = create(:favorite, favorite: create(:post))
      login_as(favorite.user)

      allow(Favorite).to receive(:find_by).and_call_original
      allow(Favorite).to receive(:find_by).with(id: favorite.id.to_s).and_return(favorite)
      allow(favorite).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      expect(favorite).to receive(:destroy!)

      delete :destroy, params: { id: favorite.id }

      expect(response).to redirect_to(favorites_path)
      expect(flash[:error]).to eq({ message: "Favorite could not be deleted.", array: [] })
      expect(Favorite.find_by(id: favorite.id)).not_to be_nil
    end
  end
end
