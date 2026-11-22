RSpec.describe RepliesController, 'GET edit (rendered)' do
  render_views

  # Controller specs stub templates by default; this compiles and renders the reply edit form and editor partial.
  it "renders the edit form for your reply" do
    user = create(:user)
    char = create(:character, user: user, name: 'renderchar')
    reply = create(:reply, user: user, character: char)
    login_as(user)

    get :edit, params: { id: reply.id }

    expect(response).to have_http_status(200)
    expect(response.body).to include('post-editor')
    expect(response.body).to include('renderchar')
  end
end
