RSpec.describe RepliesController, 'GET history' do
  let(:reply) { create(:reply) }

  it "requires valid reply" do
    get :history, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post access" do
    reply.post.update!(privacy: :private)
    reply.reload
    login_as(reply.user)
    get :history, params: { id: reply.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "works when logged out" do
    get :history, params: { id: reply.id }
    expect(response.status).to eq(200)
  end

  it "works for reader accounts" do
    login_as(create(:reader_user))
    get :history, params: { id: reply.id }
    expect(response).to have_http_status(200)
  end

  it "works when logged in" do
    login
    get :history, params: { id: reply.id }
    expect(response.status).to eq(200)
  end
end
