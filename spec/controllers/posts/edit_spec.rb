RSpec.describe PostsController, 'GET edit' do
  it "requires login" do
    get :edit, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    skip "TODO Currently relies on inability to create posts"
  end

  it "requires post" do
    login
    get :edit, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires your post" do
    login
    post = create(:post)
    get :edit, params: { id: post.id }
    expect(response).to redirect_to(post_url(post))
    expect(flash[:error]).to eq("You do not have permission to modify this post.")
  end

  it "sets relevant fields" do
    user = create(:user)
    char1 = create(:character, user: user)
    char2 = create(:character, user: user)
    char3 = create(:template_character, user: user)
    setting = create(:setting)
    warning = create(:content_warning)
    label = create(:label)
    font = create(:font)
    unjoined = create(:user)
    post = create(:post,
      user: user,
      character: char1,
      settings: [setting],
      content_warnings: [warning],
      labels: [label],
      fonts: [font],
      unjoined_authors: [unjoined],
    )
    expect(post.icon).to be_nil

    create(:reply, user: user, post: post, character: char2) # reply1

    coauthor = create(:user)
    create(:reply, user: coauthor, post: post) # other user's post

    ignored_author = create(:user)
    create(:reply, user: ignored_author, post: post) # ignored user's post
    post.opt_out_of_owed(ignored_author)

    login_as(user)

    # extras to not be in the array
    create(:setting)
    create(:content_warning)
    create(:label)
    create(:font)
    create(:user)

    expect(controller).to receive(:editor_setup).and_call_original
    expect(controller).to receive(:setup_layout_gon).and_call_original

    get :edit, params: { id: post.id }

    expect(response.status).to eq(200)
    expect(assigns(:post)).to eq(post)
    expect(assigns(:post).character).to eq(char1)
    expect(assigns(:post).icon).to be_nil

    # editor_setup:
    expect(assigns(:javascripts)).to include('posts/editor')
    expect(controller.gon.editor_user[:username]).to eq(user.username)
    expect(assigns(:author_ids)).to match_array([unjoined.id])

    # templates
    templates = assigns(:templates)
    expect(templates.length).to eq(3)
    thread_chars = templates.first
    expect(thread_chars.name).to eq('Post characters')
    expected = [char1, char2].sort_by { |c| c.name.downcase }.map { |c| [c.id, c.name] }
    expect(thread_chars.plucked_characters).to eq(expected)
    template_chars = templates[1]
    expect(template_chars).to eq(char3.template)
    templateless = templates.last
    expect(templateless.name).to eq('Templateless')
    expect(templateless.plucked_characters).to eq(expected)

    # tags
    expect(assigns(:post).settings.map(&:id_for_select)).to match_array([setting.id])
    expect(assigns(:post).content_warnings.map(&:id_for_select)).to match_array([warning.id])
    expect(assigns(:post).labels.map(&:id_for_select)).to match_array([label.id])

    expect(assigns(:post).fonts.map(&:id_for_select)).to match_array([font.id])
  end
end
