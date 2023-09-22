RSpec.describe PostsController, 'POST warnings' do
  let(:warn_post) { create(:post) }
  let(:user) { create(:user) }

  it "requires a valid post" do
    post :warnings, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires permission" do
    warn_post.update!(privacy: :private)
    post :warnings, params: { id: warn_post.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "works for logged out" do
    expect(session[:ignore_warnings]).to be_nil
    post :warnings, params: { id: warn_post.id, per_page: 10, page: 2 }
    expect(response).to redirect_to(post_url(warn_post, per_page: 10, page: 2))
    expect(flash[:success]).to eq("All content warnings have been hidden. Proceed at your own risk.")
    expect(session[:ignore_warnings]).to eq(true)
  end

  it "works for logged in" do
    expect(session[:ignore_warnings]).to be_nil
    expect(warn_post.send(:view_for, user)).to be_a_new_record
    login_as(user)
    post :warnings, params: { id: warn_post.id }
    expect(response).to redirect_to(post_url(warn_post))
    expect(flash[:success]).to start_with("Content warnings have been hidden for this thread. Proceed at your own risk.")
    expect(session[:ignore_warnings]).to be_nil
    view = warn_post.reload.send(:view_for, user)
    expect(view).not_to be_a_new_record
    expect(view.warnings_hidden).to eq(true)
  end

  it "works for reader accounts" do
    login_as(user)
    expect(session[:ignore_warnings]).to be_nil
    expect(warn_post.send(:view_for, user)).to be_a_new_record
    post :warnings, params: { id: warn_post.id }
    expect(response).to redirect_to(post_url(warn_post))
    expect(flash[:success]).to start_with("Content warnings have been hidden for this thread. Proceed at your own risk.")
  end
end
