RSpec.describe RepliesController, 'GET edit' do
  it "requires login" do
    get :edit, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    skip "TODO Currently relies on inability to create replies"
  end

  it "requires valid reply" do
    login
    get :edit, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post access" do
    reply = create(:reply)
    reply.post.update!(privacy: :private)
    reply.reload
    login_as(reply.user)
    get :edit, params: { id: reply.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "requires reply access" do
    reply = create(:reply)
    login
    get :edit, params: { id: reply.id }
    expect(response).to redirect_to(post_url(reply.post))
    expect(flash[:error]).to eq("You do not have permission to modify this reply.")
  end

  it "works" do
    user = create(:user)
    reply = create(:reply, user: user)
    login_as(user)
    char1 = create(:character, user: user)
    char2 = create(:template_character, user: user)
    expect(controller).to receive(:build_template_groups).and_call_original
    expect(controller).to receive(:setup_layout_gon).and_call_original

    get :edit, params: { id: reply.id }
    expect(response).to render_template(:edit)
    expect(assigns(:page_title)).to eq(reply.post.subject)
    expect(assigns(:reply)).to eq(reply)
    expect(assigns(:post)).to eq(reply.post)

    # build_template_groups:
    expect(controller.gon.editor_user[:username]).to eq(user.username)
    # templates
    templates = assigns(:templates)
    expect(templates.length).to eq(2)
    template_chars = templates.first
    expect(template_chars).to eq(char2.template)
    templateless = templates.last
    expect(templateless.name).to eq('Templateless')
    expect(templateless.plucked_characters).to eq([[char1.id, char1.name]])
  end
end
