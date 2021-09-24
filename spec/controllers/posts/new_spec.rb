RSpec.describe PostsController, 'GET new' do
  it "requires login" do
    get :new
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    login_as(create(:reader_user))
    get :new
    expect(response).to redirect_to(posts_path)
    expect(flash[:error]).to eq("You do not have permission to create posts.")
  end

  it "sets relevant fields" do
    user = create(:user)
    char1 = create(:character, user: user, name: 'alphafirst')
    user.update!(active_character: char1)
    user.reload
    login_as(user)

    char2 = create(:character, user: user, name: 'alphasecond')
    char3 = create(:template_character, user: user)
    expect(controller).to receive(:editor_setup).and_call_original
    expect(controller).to receive(:setup_layout_gon).and_call_original

    get :new

    expect(response).to have_http_status(200)
    expect(assigns(:post)).to be_new_record
    expect(assigns(:post).character).to eq(char1)
    expect(assigns(:post).authors_locked).to eq(true)

    # editor_setup:
    expect(assigns(:javascripts)).to include('posts/editor')
    expect(controller.gon.editor_user[:username]).to eq(user.username)

    # templates
    templates = assigns(:templates)
    expect(templates.length).to eq(2)
    template_chars = templates.first
    expect(template_chars).to eq(char3.template)
    templateless = templates.last
    expect(templateless.name).to eq('Templateless')
    expect(templateless.plucked_characters).to eq([[char1.id, char1.name], [char2.id, char2.name]])
  end

  context "import" do
    it "requires import permission" do
      login
      get :new, params: { view: :import }
      expect(response).to redirect_to(new_post_path)
      expect(flash[:error]).to eq('You do not have access to this feature.')
    end

    it "works for importer" do
      login_as(create(:importing_user))
      get :new, params: { view: :import }
      expect(response).to have_http_status(200)
    end
  end

  it "defaults authors to be the current user in open boards" do
    user = create(:user)
    login_as(user)
    create(:user) # user not in the board
    board_creator = create(:user) # user in the board
    board = create(:board, creator: board_creator, authors_locked: false)
    get :new, params: { board_id: board.id }
    expect(assigns(:post).continuity).to eq(board)
    expect(assigns(:author_ids)).to eq([])
  end

  it "defaults authors to be board authors in closed boards" do
    user = create(:user)
    login_as(user)
    coauthor = create(:user)
    create(:user) # other_user
    board = create(:board, creator: user, writers: [coauthor])
    get :new, params: { board_id: board.id }
    expect(assigns(:post).continuity).to eq(board)
    expect(assigns(:author_ids)).to match_array([coauthor.id])
  end
end
