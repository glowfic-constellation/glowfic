RSpec.describe RepliesController, 'GET show' do
  let(:reply) { create(:reply) }

  it "requires valid reply" do
    get :show, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post access" do
    reply.post.update!(privacy: :private)
    login_as(reply.user)
    get :show, params: { id: reply.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "succeeds when logged out" do
    get :show, params: { id: reply.id }
    expect(response).to have_http_status(200)
    expect(assigns(:javascripts)).to include('posts/show')
  end

  it "works for reader accounts" do
    login_as(create(:reader_user))
    get :show, params: { id: reply.id }
    expect(response).to have_http_status(200)
  end

  it "calculates OpenGraph meta" do
    user = create(:user, username: 'user1')
    user2 = create(:user, username: 'user2')
    board = create(:board, name: 'example board')
    section = create(:board_section, board: board, name: 'example section')
    post = create(:post, board: board, section: section, user: user, subject: 'a post', description: 'Test.')
    create_list(:reply, 25, post: post, user: user)
    reply = create(:reply, post: post, user: user2)
    get :show, params: { id: reply.id }
    expect(response).to have_http_status(200)
    expect(assigns(:javascripts)).to include('posts/show')

    meta_og = assigns(:meta_og)
    expect(meta_og[:url]).to eq(post_url(post, page: 2))
    expect(meta_og[:title]).to eq('a post · example board » example section')
    expect(meta_og[:description]).to eq('Test. (user1, user2 – page 2 of 2)')
  end

  it "succeeds when logged in" do
    login
    get :show, params: { id: reply.id }
    expect(response).to have_http_status(200)
    expect(assigns(:javascripts)).to include('posts/show')
  end

  it "has more tests" do
    skip
  end
end
