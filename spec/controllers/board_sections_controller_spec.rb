RSpec.describe BoardSectionsController do
  describe "GET new" do
    let(:continuity) { create(:continuity) }

    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      get :new
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires permission" do
      login
      get :new, params: { board_id: continuity.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works with continuity_id" do
      login_as(continuity.creator)
      get :new, params: { board_id: continuity.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Section")
    end

    it "works without continuity_id" do
      login
      get :new
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Section")
    end
  end

  describe "POST create" do
    let(:continuity) { create(:continuity) }

    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      post :create
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires permission" do
      login
      post :create, params: { board_section: { board_id: continuity.id } }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "requires valid section" do
      login_as(continuity.creator)
      post :create, params: { board_section: { board_id: continuity.id } }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Section could not be created.")
    end

    it "requires valid continuity for section" do
      login_as(continuity.creator)
      post :create, params: { board_section: { name: 'fake' } }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Section could not be created.")
    end

    it "succeeds" do
      login_as(continuity.creator)
      section_name = 'ValidSection'
      post :create, params: { board_section: { board_id: continuity.id, name: section_name } }
      expect(response).to redirect_to(edit_continuity_url(continuity))
      expect(flash[:success]).to eq("New section, #{section_name}, has successfully been created for #{continuity.name}.")
      expect(assigns(:board_section).name).to eq(section_name)
    end
  end

  describe "GET show" do
    let(:continuity) { create(:continuity) }
    let(:section) { create(:board_section, board: continuity) }
    let(:posts) { create_list(:post, 2, board: continuity, section: section) }

    it "requires valid section" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "does not require login" do
      posts
      create(:post)
      create(:post, board: continuity)
      get :show, params: { id: section.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq(section.name)
      expect(assigns(:posts)).to match_array(posts)
    end

    it "works for reader accounts" do
      login_as(create(:reader_user))
      get :show, params: { id: section.id }
      expect(response).to have_http_status(200)
    end

    it "works with login" do
      login
      posts
      create(:post)
      create(:post, board: continuity)
      get :show, params: { id: section.id }
      expect(response).to have_http_status(200)
    end

    it "orders posts correctly" do
      post5 = create(:post, board: continuity, section: section)
      post1 = create(:post, board: continuity, section: section)
      post4 = create(:post, board: continuity, section: section)
      post3 = create(:post, board: continuity, section: section)
      post2 = create(:post, board: continuity, section: section)
      post1.update!(section_order: 1)
      post2.update!(section_order: 2)
      post3.update!(section_order: 3)
      post4.update!(section_order: 4)
      post5.update!(section_order: 5)
      get :show, params: { id: section.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq(section.name)
      expect(assigns(:posts)).to eq([post1, post2, post3, post4, post5])
    end

    it "calculates OpenGraph data" do
      user = create(:user, username: 'John Doe')
      continuity = create(:continuity, name: 'continuity', creator: user, writers: [create(:user, username: 'Jane Doe')])
      section = create(:board_section, name: 'section', board: continuity, description: "test description")
      create(:post, subject: 'title', user: user, board: continuity, section: section)
      get :show, params: { id: section.id }

      meta_og = assigns(:meta_og)
      expect(meta_og.keys).to match_array([:url, :title, :description])
      expect(meta_og[:url]).to eq(board_section_url(section))
      expect(meta_og[:title]).to eq('continuity » section')
      expect(meta_og[:description]).to eq("Jane Doe, John Doe – 1 post\ntest description")
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid section" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "requires permission" do
      section = create(:board_section)
      login
      get :edit, params: { id: section.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works" do
      section = create(:board_section)
      login_as(section.board.creator)
      get :edit, params: { id: section.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq("Edit #{section.name}")
      expect(assigns(:board_section)).to eq(section)
    end
  end

  describe "PUT update" do
    let(:section) { create(:board_section) }

    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      put :update, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires continuity permission" do
      login
      put :update, params: { id: section.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "requires valid params" do
      login_as(section.board.creator)
      put :update, params: { id: section.id, board_section: { name: '' } }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq("Section could not be updated.")
    end

    it "succeeds" do
      section = create(:board_section, name: 'TestSection1')
      login_as(section.board.creator)
      section_name = 'TestSection2'
      put :update, params: { id: section.id, board_section: { name: section_name } }
      expect(response).to redirect_to(board_section_path(section))
      expect(section.reload.name).to eq(section_name)
      expect(flash[:success]).to eq("#{section_name} has been successfully updated.")
    end
  end

  describe "DELETE destroy" do
    let(:section) { create(:board_section) }

    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    it "requires valid section" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "requires permission" do
      login
      delete :destroy, params: { id: section.id }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works" do
      login_as(section.board.creator)
      delete :destroy, params: { id: section.id }
      expect(response).to redirect_to(edit_continuity_url(section.board))
      expect(flash[:success]).to eq("Section deleted.")
      expect(BoardSection.find_by_id(section.id)).to be_nil
    end

    it "handles destroy failure" do
      post = create(:post, user: section.board.creator, board: section.board, section: section)
      login_as(section.board.creator)

      allow(BoardSection).to receive(:find_by).and_call_original
      allow(BoardSection).to receive(:find_by).with(id: section.id.to_s).and_return(section)
      allow(section).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      expect(section).to receive(:destroy!)

      delete :destroy, params: { id: section.id }

      expect(response).to redirect_to(board_section_url(section))
      expect(flash[:error]).to eq({ message: "Section could not be deleted.", array: [] })
      expect(post.reload.section).to eq(section)
    end
  end
end
