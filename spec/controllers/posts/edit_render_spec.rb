RSpec.describe PostsController, 'GET edit (rendered)' do
  render_views

  # Controller specs stub templates by default; this compiles and renders the edit form and its editor partial.
  it "renders the edit form for your post" do
    user = create(:user)
    char = create(:character, user: user, name: 'renderchar')
    post = create(:post, user: user, character: char)
    login_as(user)

    get :edit, params: { id: post.id }

    expect(response).to have_http_status(200)
    expect(response.body).to include('post-editor')
    expect(response.body).to include('renderchar')
  end
end
