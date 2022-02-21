RSpec.describe AccessCirclesController do
  let(:user) { create(:user) }
  let(:circle) { create(:circle, user: user) }
  let(:users) { User.where(id: create_list(:user, 5).map(&:id)) }
  let(:unrelated) { create(:user) }
  let(:description) { 'test description' }

  describe "GET index" do
    it "requires login" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "with user" do
      let(:user2) { create(:user) }

      before(:each) { login_as(user) }

      it "requires a valid user" do
        get :index, params: { user_id: -1 }
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end

      it "requires permission" do
        get :index, params: { user_id: user2.id }
        expect(flash[:error]).to eq('You do not have permission to view this page.')
        expect(response).to redirect_to(root_url)
      end

      it "works" do
        circles = create_list(:access_circle, 2, user: user)
        create_list(:access_circle, 3)
        get :index, params: { user_id: user.id }
        expect(flash[:error]).not_to be_present
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq("Your Access Circles")
        expect(assigns(:circles).ids).to match_array(circles.map(&:id))
      end

      it "works on other user for admin" do
        circles = create_list(:access_circle, 2, user: user2)
        create_list(:access_circle, 2, user: user)
        create_list(:access_circle, 3)
        user.update!(role_id: Permissible::ADMIN)
        get :index, params: { user_id: user2.id }
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user2)
        expect(assigns(:page_title)).to eq("#{user2.username}'s Access Circles")
        expect(assigns(:circles).ids).to match_array(circles.map(&:id))
      end
    end

    context "without user" do
      it "works" do
        circles = create_list(:access_circle, 3, owned: false)
        create_list(:access_circle, 3, owned: true)
        create(:access_circle, user: user, owned: true)
        login_as(user)
        get :index
        expect(response.status).to eq(200)
        expect(assigns(:public)).to eq(true)
        expect(assigns(:page_title)).to eq("Public Access Circles")
        expect(assigns(:circles).ids).to match_array(circles.map(&:id))
      end
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "with views" do
      render_views

      it "works" do
        login_as(user)
        get :new
        expect(response.status).to eq(200)
        expect(assigns(:circle).user_id).to eq(user.id)
        expect(assigns(:circle).new_record?).to eq(true)
      end
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid parameters" do
      login_as(user)
      post :create, params: { access_circle: { name: '' } }
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq('Your access circle could not be saved.')
      expect(flash[:error][:array]).to eq(["Name can't be blank"])
    end

    context "with views" do
      render_views

      it "keeps variables on failed save" do
        login_as(user)

        expect {
          post :create, params: { access_circle: { name: '', description: description, user_ids: users.ids } }
        }.not_to change { PostTag.count }

        expect(response).to render_template(:new)
        expect(flash[:error][:message]).to eq('Your access circle could not be saved.')
        expect(assigns(:circle).description).to eq(description)
        expect(assigns(:circle).user_ids).to eq(users.ids)
      end
    end

    it "works" do
      login_as(user)
      post :create, params: { id: circle.id, access_circle: { name: 'test name', description: description, user_ids: users.ids } }
      expect(response.status).to redirect_to(assigns(:circle))
      expect(flash[:success]).to eq('Access circle saved successfully.')
      expect(assigns(:circle).name).to eq('test name')
      expect(assigns(:circle).description).to eq(description)
      expect(assigns(:circle).user_ids).to eq(users.ids)
    end

    it "ignores invalid user_ids" do
      login_as(user)
      post :create, params: { access_circle: { name: 'Test name', user_ids: [-1, '', users[0].id] } }
      expect(response.status).to redirect_to(assigns(:circle))
      expect(flash[:success]).to eq('Access circle saved successfully.')
      expect(assigns(:circle).user_ids).to eq([users[0].id])
    end

    it "clears relevant caches" do
      login_as(user)
      unrelated.visible_posts
      user.visible_posts
      users.each(&:visible_posts)

      users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(true) }
      expect(Rails.cache.exist?(PostViewer.cache_string_for(unrelated.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(user.id))).to be(true)

      post :create, params: { id: circle.id, access_circle: { name: 'test name', description: description, user_ids: users.ids } }
      expect(flash[:success]).to eq('Access circle saved successfully.')

      users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(false) }
      expect(Rails.cache.exist?(PostViewer.cache_string_for(unrelated.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(user.id))).to be(true)
    end
  end

  describe "GET show" do
    it "requires login" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid circle" do
      user_id = login
      get :show, params: { id: -1 }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq("Access circle could not be found.")
    end

    it "requires permission" do
      user_id = login
      get :show, params: { id: circle.id }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq("Access circle could not be found.")
    end

    context "with views" do
      render_views

      before(:each) { login_as(user) }

      it "works on info view" do
        circle.update!(description: 'foobar')
        get :show, params: { id: circle.id }
        expect(response.status).to eq(200)
      end

      it "works on posts view" do
        posts = create_list(:post, 3, user: user, privacy: :access_list, access_circles: [circle])
        get :show, params: { id: circle.id, view: 'posts' }
        expect(response.status).to eq(200)
        expect(assigns(:posts).ids).to match_array(posts.map(&:id))
      end

      it "works on users view" do
        circle.update!(user_ids: users.ids)
        get :show, params: { id: circle.id, view: 'users' }
        expect(response.status).to eq(200)
        expect(assigns(:users).ids).to match_array(users.ids)
      end
    end

    it "works for non-owners with public circles" do
      circle.update!(owned: false)
      login
      get :show, params: { id: circle.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq(circle.name)
    end

    it "works for admins" do
      login_as(create(:admin_user))
      get :show, params: { id: circle.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq(circle.name)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid circle" do
      user_id = login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq("Access circle could not be found.")
    end

    it "requires permission" do
      user_id = login
      get :edit, params: { id: circle.id }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq("Access circle could not be found.")
    end

    it "requires permission for public circles" do
      circle.update!(owned: false)
      user_id = login
      get :edit, params: { id: circle.id }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq('You do not have permission to modify this access circle')
    end

    context "with views" do
      render_views

      it "works" do
        login_as(user)
        get :edit, params: { id: circle.id }
        expect(response.status).to eq(200)
        expect(assigns(:page_title)).to eq("Edit Access Circle: #{circle.name}")
      end
    end

    it "works for admins" do
      login_as(create(:admin_user))
      get :edit, params: { id: circle.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("Edit Access Circle: #{circle.name}")
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid circle" do
      user_id = login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq("Access circle could not be found.")
    end

    it "requires permission" do
      user_id = login
      put :update, params: { id: circle.id }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq("Access circle could not be found.")
    end

    it "requires permission for public circles" do
      circle.update!(owned: false)
      user_id = login
      put :update, params: { id: circle.id }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq('You do not have permission to modify this access circle')
    end

    it "requires valid parameters" do
      login_as(user)
      put :update, params: { id: circle.id, access_circle: { name: '' } }
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq('Your access circle could not be saved.')
      expect(flash[:error][:array]).to eq(["Name can't be blank"])
    end

    context "with views" do
      render_views

      it "keeps variables on failed save" do
        login_as(user)
        circle.update!(description: 'old description', user_ids: [create(:user).id])

        expect {
          put :update, params: { id: circle.id, access_circle: { name: '', description: description, user_ids: users.ids } }
        }.not_to change { PostTag.count }

        expect(response).to render_template(:edit)
        expect(flash[:error][:message]).to eq('Your access circle could not be saved.')
        expect(assigns(:circle).description).to eq(description)
        expect(assigns(:circle).user_ids).to eq(users.ids)
      end
    end

    it "works" do
      circle.update!(description: 'old description', user_ids: [create(:user).id])
      login_as(user)
      put :update, params: { id: circle.id, access_circle: { name: 'new name', description: description, user_ids: users.ids } }
      expect(response.status).to redirect_to(circle)
      expect(flash[:success]).to eq('Access circle saved successfully.')

      circle.reload
      expect(circle.name).to eq('new name')
      expect(circle.description).to eq(description)
      expect(circle.user_ids).to eq(users.ids)
    end

    it "ignores invalid user_ids" do
      login_as(user)
      put :update, params: { id: circle.id, access_circle: { name: 'Test name', user_ids: [-1, '', users[0].id] } }
      expect(response).to redirect_to(circle)
      expect(flash[:success]).to eq('Access circle saved successfully.')
      expect(circle.reload.user_ids).to eq([users[0].id])
    end

    it "clears relevant caches" do
      login_as(user)

      old_users = create_list(:user, 2)
      retained_users = User.where(id: create_list(:user, 2).map(&:id))
      circle.update!(users: old_users + retained_users)

      unrelated.visible_posts
      user.visible_posts
      users.each(&:visible_posts)
      old_users.each(&:visible_posts)
      retained_users.each(&:visible_posts)

      users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(true) }
      old_users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(true) }
      retained_users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(true) }
      expect(Rails.cache.exist?(PostViewer.cache_string_for(unrelated.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(user.id))).to be(true)

      put :update, params: {
        id: circle.id,
        access_circle: { name: 'test name', description: description, user_ids: (users.ids + retained_users.ids) },
      }
      expect(flash[:success]).to eq('Access circle saved successfully.')
      expect(circle.reload.user_ids).to match_array(users.ids + retained_users.ids)

      users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(false) }
      old_users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(false) }
      retained_users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(true) }
      expect(Rails.cache.exist?(PostViewer.cache_string_for(unrelated.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(user.id))).to be(true)
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid circle" do
      user_id = login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq("Access circle could not be found.")
    end

    it "requires permission" do
      user_id = login
      delete :destroy, params: { id: circle.id }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq("Access circle could not be found.")
    end

    it "requires permission for public circles" do
      circle.update!(owned: false)
      user_id = login
      delete :destroy, params: { id: circle.id }
      expect(response).to redirect_to(user_access_circles_path(user_id))
      expect(flash[:error]).to eq('You do not have permission to modify this access circle')
    end

    it "works" do
      login_as(user)
      delete :destroy, params: { id: circle.id }
      expect(response.status).to redirect_to(user_access_circles_path(user))
      expect(flash[:success]).to eq("Access circle deleted.")
    end

    it "works for admins" do
      admin = create(:admin_user)
      login_as(admin)
      delete :destroy, params: { id: circle.id }
      expect(response.status).to redirect_to(user_access_circles_path(admin))
      expect(flash[:success]).to eq("Access circle deleted.")
    end

    it "handles failure" do
      allow(AccessCircle).to receive(:find_by).with(id: circle.id.to_s).and_return(circle)
      allow(circle).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
      login_as(user)

      delete :destroy, params: { id: circle.id }
      expect(response).to redirect_to(circle)
      expect(flash[:error][:message]).to eq('Access circle could not be deleted.')
    end

    it "clears relevant caches" do
      login_as(user)
      circle.update!(users: users)

      unrelated.visible_posts
      user.visible_posts
      users.each(&:visible_posts)

      users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(true) }
      expect(Rails.cache.exist?(PostViewer.cache_string_for(unrelated.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(user.id))).to be(true)

      delete :destroy, params: { id: circle.id }
      expect(flash[:success]).to eq('Access circle deleted.')

      users.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(false) }
      expect(Rails.cache.exist?(PostViewer.cache_string_for(unrelated.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(user.id))).to be(true)
    end
  end
end
