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

    it "does not return deleted users" do
      user = create(:user, deleted: true)
      create_list(:user, 4)
      get :index
      expect(assigns(:users).length).to eq(4)
      expect(assigns(:users)).not_to include(user)
    end

    context "with moieties" do
      render_views

      it "displays the name" do
        create(:user, moiety: 'fed123', moiety_name: 'moietycolor')
        get :index
        expect(response.body).to include('moietycolor')
        expect(response.body).to include('fed123')
      end
    end
  end

  describe "GET new" do
    it "can be disabled" do
      allow(ENV).to receive(:fetch).with('SIGNUPS_LOCKED', nil).and_return('yep')
      get :new
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq("We're sorry, signups are currently closed.")
    end

    it "shows message when upgrades locked" do
      allow(ENV).to receive(:fetch).with('SIGNUPS_LOCKED', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('UPGRADES_LOCKED', nil).and_return('yep')
      get :new
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("Full accounts are currently unavailable. You are welcome to sign up for a reader account.")
    end

    it "succeeds when logged out" do
      get :new
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Sign Up')
    end

    it "complains when logged in" do
      login
      post :create
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq('You are already logged in.')
    end
  end

  describe "POST create" do
    it "can be disabled" do
      allow(ENV).to receive(:fetch).with('SIGNUPS_LOCKED', nil).and_return('yep')
      post :create
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to eq("We're sorry, signups are currently closed.")
    end

    it "complains when logged in" do
      login
      post :create
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq('You are already logged in.')
    end

    it "requires tos acceptance" do
      post :create
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("You must accept the Terms and Conditions to use the Constellation.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
    end

    it "requires stupid captcha" do
      post :create, params: { tos: true }
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("Please check your math and try again.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
    end

    it "requires valid fields" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('ALLHAILTHECOIN')
      post :create, params: { secret: "ALLHAILTHECOIN", tos: true, addition: '14' }
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("There was a problem completing your sign up.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
    end

    it "rejects short passwords" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('ALLHAILTHECOIN')
      user = build(:user).attributes.with_indifferent_access.merge(password: 'short', password_confirmation: 'short')
      post :create, params: { secret: 'ALLHAILTHECOIN', tos: true, addition: '14' }.merge(user: user)
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq('There was a problem completing your sign up.')
      expect(flash[:error][:array]).to eq(['Password is too short (minimum is 6 characters)'])
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
    end

    it "signs you up" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('ALLHAILTHECOIN')
      pass = 'testpassword'
      user = build(:user).attributes.with_indifferent_access.merge(password: pass, password_confirmation: pass, email: 'testemail@example.com')

      expect {
        post :create, params: { secret: "ALLHAILTHECOIN", tos: true, addition: '14' }.merge(user: user)
      }.to change { User.count }.by(1)
      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("User created! You have been logged in.")

      new_user = assigns(:current_user)
      expect(new_user).not_to be_nil
      expect(new_user.username).to eq(user[:username])
      expect(new_user.authenticate(user[:password])).to eq(true)
      expect(new_user.email).to eq(user[:email])
      expect(new_user.read_only?).to eq(false)
    end

    it "creates reader account without secret" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('ALLHAILTHECOIN')
      pass = 'testpassword'
      user = build(:user).attributes.with_indifferent_access.merge(password: pass, password_confirmation: pass, email: 'testemail@example.com')

      post :create, params: { tos: true, addition: '14' }.merge(user: user)

      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("User created! You have been logged in.")
      expect(assigns(:user).read_only?).to eq(true)
    end

    it "creates reader account with upgrade lock" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('ALLHAILTHECOIN')
      allow(ENV).to receive(:fetch).with('SIGNUPS_LOCKED', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('UPGRADES_LOCKED', nil).and_return('yep')
      pass = 'testpassword'
      user = build(:user).attributes.with_indifferent_access.merge(password: pass, password_confirmation: pass, email: 'testemail@example.com')

      post :create, params: { secret: "ALLHAILTHECOIN", tos: true, addition: '14' }.merge(user: user)

      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("User created! You have been logged in.")
      expect(flash[:error]).to eq("We're sorry, full accounts are currently unavailable.")
      expect(assigns(:user).read_only?).to eq(true)
    end

    it "allows long passwords" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('ALLHAILTHECOIN')
      pass = 'this is a long password to test the password validation feature and to see if it accepts this'
      user = build(:user).attributes.with_indifferent_access.merge(password: pass, password_confirmation: pass)
      expect {
        post :create, params: { secret: 'ALLHAILTHECOIN', tos: true, addition: '14' }.merge(user: user)
      }.to change { User.count }.by(1)
      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("User created! You have been logged in.")
      expect(assigns(:current_user)).not_to be_nil
      expect(assigns(:current_user).username).to eq(user['username'])
      expect(assigns(:current_user).authenticate(pass)).to eq(true)
    end

    it "strips spaces" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('ALLHAILTHECOIN')
      user = build(:user, username: 'withspace ').attributes
      user = user.with_indifferent_access.merge(password: 'password', password_confirmation: 'password')
      post :create, params: { secret: 'ALLHAILTHECOIN', tos: true, addition: '14' }.merge(user: user)
      expect(flash[:success]).to eq("User created! You have been logged in.")
      expect(assigns(:current_user).username).to eq('withspace')
    end
  end

  describe "GET show" do
    it "requires valid user" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(users_url)
      expect(flash[:error]).to eq("User could not be found.")
    end

    it "requires non-deleted user" do
      user = create(:user, deleted: true)
      get :show, params: { id: user.id }
      expect(response).to redirect_to(users_url)
      expect(flash[:error]).to eq("User could not be found.")
    end

    it "works when logged out" do
      user = create(:user)
      get :show, params: { id: user.id }
      expect(response.status).to eq(200)
    end

    it "works when logged in as someone else" do
      user = create(:user)
      login
      get :show, params: { id: user.id }
      expect(response.status).to eq(200)
    end

    it "works when logged in as yourself" do
      user = create(:user)
      login_as(user)
      get :show, params: { id: user.id }
      expect(response.status).to eq(200)
    end

    it "sets the correct variables" do
      user = create(:user)
      posts = create_list(:post, 3, user: user)
      create(:post)
      get :show, params: { id: user.id }
      expect(assigns(:page_title)).to eq(user.username)
      expect(assigns(:posts).to_a).to match_array(posts)
    end

    it "sorts posts correctly" do
      user = create(:user)
      post1 = create(:post)
      post2 = create(:post, user: user)
      post3 = create(:post)
      create(:reply, post: post3, user: user)
      create(:reply, post: post2)
      create(:reply, post: post1, user: user)
      create(:post)
      get :show, params: { id: user.id }
      expect(assigns(:posts).to_a).to eq([post1, post2, post3])
    end

    it "calculates OpenGraph meta for a bare user" do
      user = create(:user, username: 'user')

      get :show, params: { id: user.id }

      meta_og = assigns(:meta_og)
      expect(meta_og.keys).to match_array([:url, :title, :description])
      expect(meta_og[:url]).to eq(user_url(user))
      expect(meta_og[:title]).to eq('user')
      expect(meta_og[:description]).to eq('No continuities.')
    end

    it "calculates OpenGraph meta for user with settings and an avatar" do
      user = create(:user, username: 'user')
      user.update!(avatar: create(:icon))
      create(:board, name: "Board 1", creator: user)
      create(:board, name: "Board 2", creator: user)

      get :show, params: { id: user.id }

      meta_og = assigns(:meta_og)
      expect(meta_og.keys).to match_array([:url, :title, :description, :image])
      expect(meta_og[:url]).to eq(user_url(user))
      expect(meta_og[:title]).to eq('user')
      expect(meta_og[:description]).to eq('Continuities: Board 1, Board 2')
      expect(meta_og[:image].keys).to match_array([:src, :width, :height])
      expect(meta_og[:image][:src]).to eq(user.avatar.url)
      expect(meta_og[:image][:width]).to eq('75')
      expect(meta_og[:image][:width]).to eq('75')
    end
  end

  describe "GET edit" do
    let(:user)  { create(:user) }
    let(:user_id) { user.id }

    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires own user" do
      login
      get :edit, params: { id: user_id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq('You do not have permission to modify this account.')
    end

    it "succeeds" do
      login_as(user)
      get :edit, params: { id: user_id }
      expect(response.status).to eq(200)
    end

    context "with views" do
      render_views

      it "displays options" do
        login_as(user)
        expect { get :edit, params: { id: user_id } }.not_to raise_error
      end

      it "displays options for readers" do
        user = create(:reader_user)
        login_as(user)
        expect { get :edit, params: { id: user.id } }.not_to raise_error
      end
    end
  end

  describe "GET profile_edit" do
    let(:user)  { create(:user) }
    let(:user_id) { user.id }

    it "requires login" do
      get :profile_edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires own user" do
      login
      get :profile_edit, params: { id: user_id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq('You do not have permission to modify this account.')
    end

    it "succeeds" do
      login_as(user)
      get :profile_edit, params: { id: user_id }
      expect(response.status).to eq(200)
    end

    context "with views" do
      render_views

      it "displays options" do
        login_as(user)
        expect { get :profile_edit, params: { id: user_id } }.not_to raise_error
      end
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      user = create(:user)
      login_as(user)
      put :update, params: { id: user.id, user: { moiety: 'A' } }
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq('Changes could not be saved because of the following problems:')
    end

    it "does not update another user" do
      user1 = create(:user)
      user2 = create(:user)
      login_as(user1)
      put :update, params: { id: user2.id, user: { email: 'bademail@example.com' } }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq('You do not have permission to modify this account.')
      expect(user2.reload.email).not_to eq('bademail@example.com')
    end

    it "updates settings with valid params" do
      user = create(:user)
      login_as(user)

      user_details = {
        email: 'testuser314@example.com',
        email_notifications: true,
        favorite_notifications: false,
        show_user_in_switcher: false,
        default_character_split: 'none',
      }

      # ensure new values are different, so test tests correct things
      user_details.each do |key, value|
        expect(user.public_send(key)).not_to eq(value)
      end

      put :update, params: { id: user.id, user: user_details }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved.')

      user.reload
      user_details.each do |key, value|
        expect(user.public_send(key)).to eq(value)
      end
    end

    it "updates profile with valid params" do
      user = create(:user)
      login_as(user)

      author_cw = create(:content_warning)

      user_details = {
        profile: 'Profile Description',
        profile_editor_mode: 'rtf',
        moiety_name: 'Testmoiety',
        moiety: 'AAAAAA',
        content_warning_ids: [author_cw.id],
      }

      # ensure new values are different, so test tests correct things
      user_details.each do |key, value|
        expect(user.public_send(key)).not_to eq(value)
      end

      put :update, params: { id: user.id, user: user_details, button_submit_profile: true }
      expect(response).to redirect_to(user_url(user))
      expect(flash[:success]).to eq('Changes saved.')

      user.reload
      user_details.each do |key, value|
        expect(user.public_send(key)).to eq(value)
      end
    end

    it "updates username and still allows login" do
      pass = 'password123'
      user = create(:user, username: 'user123', password: pass)
      expect(user.authenticate(pass)).to eq(true)
      login_as(user)
      put :update, params: { id: user.id, user: { username: 'user124' } }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved.')

      user.reload
      expect(user.username).to eq('user124')
      expect(user.authenticate(pass)).to eq(true)
      expect(user.authenticate(pass + '1')).not_to eq(true)
    end

    context "tos" do
      it "saves update" do
        user = create(:user, tos_version: nil)
        login_as(user)
        put :update, params: { id: user.id, tos_check: true }
        expect(user.reload.tos_version).to eq(User::CURRENT_TOS_VERSION)
        expect(flash[:success]).to eq('Acceptance saved. Thank you.')
        expect(response).to redirect_to(root_url)
      end

      it "handles failures" do
        user = create(:user, tos_version: nil)
        login_as(user)
        user.update_columns(username: 'a') # too short to validate # rubocop:disable Rails/SkipsModelValidations
        put :update, params: { id: user.id, tos_check: true }
        expect(user.reload.tos_version).to be_nil
        expect(flash[:error][:message]).to eq('There was an error saving your changes. Please try again.')
        expect(flash[:error][:array]).to eq(["Username is too short (minimum is 3 characters)"])
        expect(response).to render_template('about/accept_tos')
      end
    end
  end

  describe "PUT password" do
    it "requires login" do
      put :password, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires own user" do
      user = create(:user)
      login
      put :password, params: { id: user.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq('You do not have permission to modify this account.')
    end

    it "requires correct password" do
      pass = 'testpass'
      fakepass = 'wrongpass'
      newpass = 'newpass'
      user = create(:user, password: 'testpass')
      login_as(user)

      put :password, params: {
        id: user.id,
        old_password: fakepass,
        user: { password: newpass, password_confirmation: newpass },
      }

      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq('Incorrect password entered.')
      user.reload
      expect(user.authenticate(pass)).to eq(true)
      expect(user.authenticate(fakepass)).not_to eq(true)
      expect(user.authenticate(newpass)).not_to eq(true)
    end

    it "requires valid password" do
      pass = 'testpass'
      newpass = 'bad'
      user = create(:user, password: pass)
      login_as(user)

      put :password, params: {
        id: user.id,
        old_password: pass,
        user: { password: newpass, password_confirmation: newpass },
      }

      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq('There was a problem with your changes.')
      expect(user.authenticate(pass)).to eq(true)
      expect(user.authenticate(newpass)).not_to eq(true)
    end

    it "requires valid confirmation" do
      pass = 'testpass'
      newpass = 'newpassword'
      user = create(:user, password: pass)
      login_as(user)

      put :password, params: {
        id: user.id,
        old_password: pass,
        user: { password: newpass, password_confirmation: 'wrongconfirmation' },
      }

      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq('There was a problem with your changes.')
      user.reload
      expect(user.authenticate(pass)).to eq(true)
      expect(user.authenticate(newpass)).not_to eq(true)
    end

    it "succeeds" do
      pass = 'testpass'
      newpass = 'newpassword'
      user = create(:user, password: pass)
      login_as(user)

      put :password, params: {
        id: user.id,
        old_password: pass,
        user: { password: newpass, password_confirmation: newpass },
      }

      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved.')
      user.reload
      expect(user.authenticate(pass)).not_to eq(true)
      expect(user.authenticate(newpass)).to eq(true)
    end

    it "has more tests" do
      skip
    end
  end

  describe "PUT upgrade" do
    it "requires login" do
      put :upgrade, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires own user" do
      user = create(:user)
      login
      put :upgrade, params: { id: user.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to modify this account.")
    end

    it "requires reader account" do
      user = create(:user, role_id: Permissible::ADMIN)
      login_as(user)
      put :upgrade, params: { id: user.id, secret: 'chocolate' }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:error]).to eq("This account does not need to be upgraded.")
    end

    it "can be disabled" do
      allow(ENV).to receive(:fetch).with('UPGRADES_LOCKED', nil).and_return('yep')
      user = create(:user, role_id: Permissible::READONLY)
      login_as(user)
      put :upgrade, params: { id: user.id, secret: 'chocolate' }
      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq("We're sorry, upgrades are currently disabled.")
    end

    it "requires valid secret" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('chocolate')
      user = create(:user, role_id: Permissible::READONLY)
      login_as(user)
      put :upgrade, params: { id: user.id, secret: 'vanilla' }
      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq("That is not the correct secret. Please ask someone in the community for help.")
    end

    it "handles update failures" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('chocolate')
      user = create(:user, role_id: Permissible::READONLY)

      allow(User).to receive(:find_by_id).and_call_original
      allow(User).to receive(:find_by_id).with(user.id).and_return(user)
      allow(user).to receive(:update).and_return(false)
      expect(user).to receive(:update)

      login_as(user)
      put :upgrade, params: { id: user.id, secret: 'chocolate' }
      expect(flash[:error]).to eq("There was a problem updating your account.")
      expect(response).to render_template(:edit)
    end

    it "works" do
      allow(ENV).to receive(:[]).with('ACCOUNT_SECRET').and_return('chocolate')
      user = create(:user, role_id: Permissible::READONLY)
      login_as(user)
      put :upgrade, params: { id: user.id, secret: 'chocolate' }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq("Changes saved successfully.")
      expect(user.reload).not_to be_read_only
    end
  end

  describe "GET search" do
    it "works logged in" do
      login
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:search_results)).to be_nil
    end

    it "works logged out" do
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:search_results)).to be_nil
    end

    it "subsearches correctly" do
      create(:user, username: 'baa') # firstuser
      create(:user, username: 'aba') # miduser
      create(:user, username: 'aab') # enduser
      create(:user, username: 'aaa') # notuser
      User.find_each do |user|
        create(:user, username: user.username.upcase + 'c')
      end
      get :search, params: { commit: 'Search', username: 'b' }
      expect(response).to have_http_status(200)
      expect(assigns(:search_results)).to be_present
      expect(assigns(:search_results).count).to eq(6)
    end

    it "orders users correctly" do
      create(:user, username: 'baa')
      create(:user, username: 'aba')
      create(:user, username: 'aab')
      get :search, params: { commit: 'Search', username: 'b' }
      expect(assigns(:search_results).map(&:username)).to eq(['aab', 'aba', 'baa'])
    end

    it "does not include deleted users" do
      user = create(:user, deleted: true)
      create_list(:user, 4)
      get :search, params: { commit: 'Search', username: 'Doe' }
      expect(assigns(:search_results).length).to eq(4)
      expect(assigns(:search_results)).not_to include(user)
    end

    it "does not include deleted users even on exact match" do
      create(:user, username: "testUser", deleted: true)
      create_list(:user, 4)
      get :search, params: { commit: 'Search', username: "testUser" }
      expect(assigns(:search_results)).to be_empty
    end
  end

  describe "GET output" do
    let(:user) { create(:user) }

    it "requires login" do
      get :output, params: { id: user.id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "handles invalid date" do
      login_as(user)
      get :output, params: { id: user.id, day: 'asdf' }
      expect(response).to have_http_status(200)
      expect(flash[:error]).to eq('Please note that this page does not include edit history.')
      expect(assigns(:total)).to eq(0)
    end

    it "handles out of range date" do
      login_as(user)
      get :output, params: { id: user.id, day: '2018-28-10' }
      expect(response).to have_http_status(200)
      expect(flash[:error]).to eq('Please note that this page does not include edit history.')
      expect(assigns(:total)).to eq(0)
    end

    context "with views" do
      render_views
      it "works for default of today" do
        login_as(user)

        Timecop.freeze(Time.zone.now) do
          post = create(:post, user: user, content: 'two words')
          create_list(:reply, 2, user: user, post: post, content: 'three words each')
          get :output, params: { id: user.id }
        end

        expect(response).to have_http_status(200)
        expect(flash[:error]).to eq('Please note that this page does not include edit history.')
        expect(assigns(:total)).to eq(8)

        expect(response.body).not_to include("Next Day")
        expect(response.body).to include("Your Daily Output: 8 words")
        expect(response.body).to include("two words")
        expect(response.body).to match(/three words each.*three words each/m)
      end

      it "works for previous days" do
        login_as(user)

        day = Time.zone.now.to_date - 1.day
        Timecop.freeze(day) do
          post = create(:post, user: user, content: 'two words')
          create_list(:reply, 2, user: user, post: post, content: 'three words each')
        end
        create(:post, user: user, content: 'not in word count')

        get :output, params: { id: user.id, day: day.to_s }
        expect(response).to have_http_status(200)
        expect(flash[:error]).to eq('Please note that this page does not include edit history.')
        expect(assigns(:total)).to eq(8)

        expect(response.body).to include("Next Day")
        expect(response.body).to include("Your Daily Output: 8 words")
        expect(response.body).to include("two words")
        expect(response.body).to match(/three words each.*three words each/m)
      end
    end
  end
end
