require "spec_helper"

RSpec.describe ContinuitiesController do
  include ActiveJob::TestHelper

  describe "GET index" do
    context "without a user_id" do
      it "succeeds when logged out" do
        get :index
        expect(response.status).to eq(200)
      end

      it "succeeds when logged in" do
        login
        get :index
        expect(response.status).to eq(200)
      end

      it "sets correct variables" do
        user = create(:user)
        continuity1 = create(:continuity, creator_id: user.id)
        continuity2 = create(:continuity, creator_id: user.id)

        get :index
        expect(assigns(:continuities)).to match_array([continuity1, continuity2])
        expect(assigns(:page_title)).to eq('Continuities')
      end
    end

    context "with a user_id" do
      it "does not require login" do
        user = create(:user)
        get :index, params: { user_id: user.id }
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq("#{user.username}'s Continuities")
      end

      it "displays error if user id invalid and logged out" do
        get :index, params: { user_id: -1 }
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end

      it "displays error if user id invalid and logged in" do
        login
        get :index, params: { user_id: -1 }
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end

      it "does not use logged in user's username" do
        continuity = create(:continuity)
        login_as(continuity.creator)
        get :index, params: { user_id: continuity.creator_id }
        expect(assigns(:page_title)).to eq('Your Continuities')
      end

      it "sets correct variables" do
        user = create(:user)
        owned_continuity = create(:continuity, creator_id: user.id)

        get :index, params: { user_id: user.id }
        expect(assigns(:continuities)).to match_array([owned_continuity])

        coauthor = create(:user)
        owned_continuity2 = create(:continuity, creator: user, writers: [coauthor])
        owned_continuity3 = create(:continuity, creator: user, cameos: [coauthor])

        get :index, params: { user_id: coauthor.id }
        expect(assigns(:continuities)).to match_array([owned_continuity2])
        expect(assigns(:cameo_continuities)).to match_array([owned_continuity3])
      end

      it "orders continuities correctly" do
        user = create(:user)
        owned_continuity1 = create(:continuity, creator_id: user.id, name: 'da')
        owned_continuity2 = create(:continuity, creator_id: user.id, name: 'ba')
        author_continuity1 = create(:continuity, writers: [user], name: 'aa')
        author_continuity2 = create(:continuity, writers: [user], name: 'ca')
        cameo_continuity1 = create(:continuity, cameos: [user], name: 'bb')
        cameo_continuity2 = create(:continuity, cameos: [user], name: 'ab')
        cameo_continuity3 = create(:continuity, cameos: [user], name: 'cb')

        get :index, params: { user_id: user.id }
        expect(assigns(:continuities)).to eq([author_continuity1, owned_continuity2, author_continuity2, owned_continuity1])
        expect(assigns(:cameo_continuities)).to eq([cameo_continuity2, cameo_continuity1, cameo_continuity3])
      end
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end

    it "sets correct variables" do
      user_id = login
      current_user = User.find(user_id)
      other_users = Array.new(3) { create(:user) }

      get :new

      expect(assigns(:continuity)).to be_an_instance_of(Continuity)
      expect(assigns(:continuity)).to be_a_new_record
      expect(assigns(:continuity).creator_id).to eq(user_id)
      expect(assigns(:page_title)).to eq("New Continuity")

      expect(assigns(:coauthors).size).to eq(3)
      expect(assigns(:coauthors)).to match_array(other_users)
      expect(assigns(:coauthors)).not_to include(current_user)
      expect(assigns(:coauthors).sort_by(&:username)).to eq(assigns(:coauthors))

      expect(assigns(:cameos).size).to eq(3)
      expect(assigns(:cameos)).to match_array(other_users)
      expect(assigns(:cameos)).not_to include(current_user)
      expect(assigns(:cameos).sort_by(&:username)).to eq(assigns(:cameos))
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Continuity could not be created.")
      expect(flash[:error][:array]).to be_present
      expect(response).to render_template('new')
    end

    it "sets correct variables on failure" do
      login
      other_users = Array.new(3) { create(:user) }

      post :create

      expect(assigns(:continuity)).to be_an_instance_of(Continuity)
      expect(assigns(:continuity)).to be_a_new_record
      expect(assigns(:continuity)).not_to be_valid
      expect(assigns(:continuity).creator).to eq(assigns(:current_user))
      expect(assigns(:page_title)).to eq("New Continuity")

      expect(assigns(:coauthors).size).to eq(3)
      expect(assigns(:coauthors)).to match_array(other_users)
      expect(assigns(:coauthors)).not_to include(assigns(:current_user))
      expect(assigns(:coauthors).sort_by(&:username)).to eq(assigns(:coauthors))

      expect(assigns(:cameos).size).to eq(3)
      expect(assigns(:cameos)).to match_array(other_users)
      expect(assigns(:cameos)).not_to include(assigns(:current_user))
      expect(assigns(:cameos).sort_by(&:username)).to eq(assigns(:cameos))
    end

    it "successfully makes a continuity" do
      expect(Continuity.count).to eq(0)
      creator = create(:user)
      login_as(creator)
      user2 = create(:user)
      user3 = create(:user)

      post :create, params: {
        continuity: {
          name: 'TestCreateContinuity',
          description: 'Test description',
          coauthor_ids: [user2.id],
          cameo_ids: [user3.id]
        }
      }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:success]).to eq("Continuity created!")
      expect(Continuity.count).to eq(1)

      continuity = Continuity.first
      expect(continuity.name).to eq('TestCreateContinuity')
      expect(continuity.creator).to eq(creator)
      expect(continuity.description).to eq('Test description')
      expect(continuity.writers).to match_array([creator, user2])
      expect(continuity.cameos).to match_array([user3])
    end
  end

  describe "GET show" do
    it "requires valid continuity" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "succeeds with valid continuity" do
      continuity = create(:continuity)
      get :show, params: { id: continuity.id }
      expect(response.status).to eq(200)
    end

    it "succeeds for logged in users with valid continuity" do
      login
      continuity = create(:continuity)
      get :show, params: { id: continuity.id }
      expect(response.status).to eq(200)
    end

    it "only fetches the continuity's first 25 posts" do
      continuity = create(:continuity)
      create_list(:post, 26, continuity: continuity)
      get :show, params: { id: continuity.id }
      expect(assigns(:posts).size).to eq(25)
    end

    it "orders the posts by tagged_at in unordered continuities" do
      continuity = create(:continuity)
      Array.new(3) { create(:post, continuity: continuity, tagged_at: Time.zone.now + rand(5..30).hours) }
      get :show, params: { id: continuity.id }
      expect(assigns(:posts)).to eq(assigns(:posts).sort_by(&:tagged_at).reverse)
    end

    it "orders the posts correctly in ordered continuities" do
      continuity = create(:continuity)
      section2 = create(:subcontinuity, continuity: continuity)
      section1 = create(:subcontinuity, continuity: continuity)
      section1.update!(section_order: 0)
      section2.update!(section_order: 1)
      post1, post2, post3 = create_list(:post, 3, continuity: continuity, section: section1)
      post4, post5, post6 = create_list(:post, 3, continuity: continuity, section: section2)
      post7, post8, post9 = create_list(:post, 3, continuity: continuity)
      continuity.posts.each do |post|
        # skip callbacks so we truly override tagged_at
        post.update_columns(tagged_at: Time.zone.now + rand(5..30).hours)
      end
      post1.update!(section_order: 0)
      post2.update!(section_order: 1)
      post3.update!(section_order: 2)
      post4.update!(section_order: 0)
      post5.update!(section_order: 1)
      post6.update!(section_order: 2)
      post7.update!(section_order: 0)
      post8.update!(section_order: 1)
      post9.update!(section_order: 2)
      get :show, params: { id: continuity.id }
      # we only order continuity section posts in the HAML, so manually order them here
      expect(assigns(:subcontinuities).map(&:posts).map(&:ordered_in_section).map(&:to_a)).to eq([[post1, post2, post3], [post4, post5, post6]])
      expect(assigns(:posts)).to eq([post7, post8, post9])
    end

    it "calculates OpenGraph meta" do
      user = create(:user, username: 'John Doe')
      continuity = create(:continuity, name: 'continuity', creator: user, writers: [create(:user, username: 'Jane Doe')], description: 'sample continuity')
      create(:post, subject: 'title', user: user, continuity: continuity)
      get :show, params: { id: continuity.id }

      meta_og = assigns(:meta_og)
      expect(meta_og.keys).to match_array([:url, :title, :description])
      expect(meta_og[:url]).to eq(continuity_url(continuity))
      expect(meta_og[:title]).to eq('continuity')
      expect(meta_og[:description]).to eq("Jane Doe, John Doe – 1 post\nsample continuity")
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid continuity" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires continuity permission" do
      user = create(:user)
      login_as(user)
      continuity = create(:continuity)
      expect(continuity).not_to be_editable_by(user)
      get :edit, params: { id: continuity.id }
      expect(response).to redirect_to(continuity_url(continuity))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "succeeds with valid continuity" do
      continuity = create(:continuity)
      login_as(continuity.creator)
      get :edit, params: { id: continuity.id }
      expect(response.status).to eq(200)
    end

    it "sets expected variables" do
      coauthor = create(:user)
      continuity = create(:continuity, writers: [coauthor])
      sections = [create(:subcontinuity, continuity: continuity), create(:subcontinuity, continuity: continuity)]
      posts = [create(:post, continuity: continuity, user: continuity.creator, tagged_at: Time.zone.now + 5.minutes), create(:post, user: coauthor, continuity: continuity)]
      sections[0].update!(section_order: 1)
      sections[1].update!(section_order: 0)
      login_as(continuity.creator)
      get :edit, params: { id: continuity.id }
      expect(assigns(:subcontinuities)).to eq(sections.reverse)
      expect(assigns(:unsectioned_posts)).to eq(posts)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid continuity" do
      login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires continuity permission" do
      user = create(:user)
      login_as(user)
      continuity = create(:continuity)
      expect(continuity).not_to be_editable_by(user)
      put :update, params: { id: continuity.id }
      expect(response).to redirect_to(continuity_url(continuity))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "requires valid params" do
      user = create(:user)
      continuity = create(:continuity, creator: user)
      login_as(user)
      put :update, params: { id: continuity.id, continuity: {name: ''} }
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("Continuity could not be created.")
      expect(flash[:error][:array]).to be_present
    end

    it "succeeds" do
      user = create(:user)
      continuity = create(:continuity, creator: user)
      name = continuity.name
      login_as(user)
      user2 = create(:user)
      user3 = create(:user)
      put :update, params: {
        id: continuity.id,
        continuity: {
          name: name + 'edit',
          description: 'New description',
          coauthor_ids: [user2.id],
          cameo_ids: [user3.id]
        }
      }
      expect(response).to redirect_to(continuity_url(continuity))
      expect(flash[:success]).to eq("Continuity saved!")
      continuity.reload
      expect(continuity.name).to eq(name + 'edit')
      expect(continuity.description).to eq('New description')
      expect(continuity.writers).to match_array([user, user2])
      expect(continuity.cameos).to match_array([user3])
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid continuity" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires continuity permission" do
      user = create(:user)
      login_as(user)
      continuity = create(:continuity)
      expect(continuity).not_to be_editable_by(user)
      delete :destroy, params: { id: continuity.id }
      expect(response).to redirect_to(continuity_url(continuity))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "succeeds" do
      continuity = create(:continuity)
      login_as(continuity.creator)
      delete :destroy, params: { id: continuity.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:success]).to eq("Continuity deleted.")
    end

    it "moves posts to sandboxes" do
      continuity = create(:continuity)
      create(:continuity, id: 3) # sandbox
      section = create(:subcontinuity, continuity: continuity)
      post = create(:post, continuity: continuity, section: section)
      login_as(continuity.creator)
      perform_enqueued_jobs(only: UpdateModelJob) do
        delete :destroy, params: { id: continuity.id }
      end
      expect(response).to redirect_to(continuities_url)
      expect(flash[:success]).to eq('Continuity deleted.')
      post.reload
      expect(post.continuity_id).to eq(3)
      expect(post.section).to be_nil
      expect(Subcontinuity.find_by_id(section.id)).to be_nil
    end

    it "handles destroy failure" do
      continuity = create(:continuity)
      post = create(:post, user: continuity.creator, continuity: continuity)
      login_as(continuity.creator)
      expect_any_instance_of(Continuity).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: continuity.id }
      expect(response).to redirect_to(continuity_url(continuity))
      expect(flash[:error]).to eq({message: "Continuity could not be deleted.", array: []})
      expect(post.reload.continuity).to eq(continuity)
    end
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires continuity id" do
      login
      post :mark
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires valid continuity id" do
      login
      post :mark, params: { continuity_id: -1 }
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires valid action" do
      login
      post :mark, params: { continuity_id: create(:continuity).id }
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Please choose a valid action.")
    end

    it "successfully marks continuity read" do
      continuity = create(:continuity)
      user = create(:user)
      login_as(user)
      now = Time.zone.now
      expect(continuity.last_read(user)).to be_nil
      post :mark, params: { continuity_id: continuity.id, commit: "Mark Read" }
      expect(Continuity.find(continuity.id).last_read(user)).to be >= now # reload to reset cached @view
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("#{continuity.name} marked as read.")
    end

    it "marks extant post views read" do
      now = Time.zone.now
      continuity = create(:continuity)
      user = create(:user)
      read_post = create(:post, user: user, continuity: continuity)
      read_post.mark_read(user, now - 1.day, true)
      unread_post = create(:post, user: user, continuity: continuity)
      unread_post.mark_read(create(:user), now - 1.day, true)

      expect(Continuity.find(continuity.id).last_read(user)).to be_nil # reload to reset cached @view
      expect(Post.find(read_post.id).last_read(user)).to be_the_same_time_as(now - 1.day)
      expect(Post.find(unread_post.id).last_read(user)).to be_nil

      login_as(user)
      post :mark, params: { continuity_id: continuity.id, commit: "Mark Read" }

      expect(Continuity.find(continuity.id).last_read(user)).to be >= now # reload to reset cached @view
      expect(Post.find(read_post.id).last_read(user)).to be >= now
      expect(Post.find(unread_post.id).last_read(user)).to be_nil
    end

    it "successfully ignores continuity" do
      continuity = create(:continuity)
      user = create(:user)
      login_as(user)
      expect(continuity).not_to be_ignored_by(user)
      post :mark, params: { continuity_id: continuity.id, commit: "Hide from Unread" }
      expect(Continuity.find(continuity.id)).to be_ignored_by(user) # reload to reset cached @view
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("#{continuity.name} hidden from this page.")
    end
  end

  describe "GET search" do
    context "no search" do
      it "works logged out" do
        get :search
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Search Continuities')
        expect(assigns(:search_results)).to be_nil
      end

      it "works logged in" do
        login
        get :search
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Search Continuities')
        expect(assigns(:search_results)).to be_nil
      end
    end

    context "searching" do
      it "finds all when no arguments given" do
        create_list(:continuity, 4)
        get :search, params: { commit: true }
        expect(assigns(:search_results)).to match_array(Continuity.all)
      end

      it "filters by name" do
        continuity1 = create(:continuity, name: 'contains stars')
        continuity2 = create(:continuity, name: 'contains Stars cased')
        create(:continuity, name: 'unrelated')
        get :search, params: { commit: true, name: 'stars' }
        expect(assigns(:search_results)).to match_array([continuity1, continuity2])
      end

      it "filters by authors" do
        user = create(:user)
        continuity1 = create(:continuity, creator: user)
        create_list(:continuity, 2)
        continuity4 = create(:continuity, coauthors: [user])
        get :search, params: { commit: true, author_id: [user.id] }
        expect(assigns(:search_results)).to match_array([continuity1, continuity4])
      end

      it "filters by multiple authors" do
        author1 = create(:user)
        author2 = create(:user)

        create(:continuity, creator: author1) # one author but not the other
        create(:continuity, coauthors: [author2]) # one author but not the other, coauthor

        continuities = [create(:continuity, creator: author1, coauthors: [author2])] # both authors
        continuities << create(:continuity, coauthors: [author1, author2]) # both authors coauthors
        continuities << create(:continuity, coauthors: [author1], cameos: [author2]) # both authors, one cameo

        get :search, params: { commit: true, author_id: [author1.id, author2.id] }
        expect(assigns(:search_results)).to match_array(continuities)
      end

      it "orders continuities by name" do
        ['baa', 'aab', 'aba'].each { |name| create(:continuity, name: name) }
        get :search, params: { commit: 'Search', name: 'b' }
        expect(assigns(:search_results).map(&:name)).to eq(['aab', 'aba', 'baa'])
      end
    end
  end

  describe "#set_available_cowriters" do
    it "gets the correct set of available cowriters" do
      login
      users = Array.new(3) { create(:user) }
      controller.send(:set_available_cowriters)
      expect(assigns(:cameos)).to match_array(users)
      expect(assigns(:coauthors)).to match_array(users)
    end

    it "gets the correct set of available cowriters on an existing continuity" do
      users = Array.new(3) { create(:user) }
      coauthors = [create(:user)]
      cameos = [create(:user), create(:user)]
      continuity = create(:continuity, writers: coauthors, cameos: cameos)
      login_as(continuity.creator)
      continuity.reload
      controller.instance_variable_set(:@continuity, continuity)
      controller.send(:set_available_cowriters)
      expect(assigns(:cameos)).to match_array(users + cameos)
      expect(assigns(:coauthors)).to match_array(users + coauthors)
    end

    it "orders them correctly" do
      login
      user2 = create(:user, username: 'user2')
      user1 = create(:user, username: 'user1')
      user3 = create(:user, username: 'user3')
      controller.send(:set_available_cowriters)
      expect(assigns(:cameos)).to eq([user1, user2, user3])
      expect(assigns(:coauthors)).to eq([user1, user2, user3])
    end
  end
end
