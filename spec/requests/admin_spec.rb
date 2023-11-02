RSpec.describe 'Admin panel' do
  let(:admin) { create(:admin_user, password: 'known') }

  before(:each) do
    login(admin)
  end

  it 'renders the admin root' do
    get '/admin'
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:index)
      expect(response.body).to include('Admin Tools')
    end
  end

  it 'renders the post split form' do
    target = create(:post)
    reply = create(:reply, post: target)

    get '/admin/posts/split'
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:split)
      expect(response.body).to include('Split Post')
    end

    update_params = {
      reply_id: reply.id,
      subject: 'test',
    }
    post '/admin/posts/do_split', params: {
      **update_params,
      button_preview: true,
    }
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:preview_split)
      expect(response.body).to match(/Splitting.*at reply id #/m)
    end

    expect {
      post '/admin/posts/do_split', params: update_params
    }.to have_enqueued_job(SplitPostJob).with(reply.id.to_s, 'test')
    aggregate_failures do
      expect(response).to redirect_to(admin_url)
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to eq('Post will be split.')
    end
    expect {
      perform_enqueued_jobs
    }.to change { Post.count }.by(1).and change { Reply.count }.by(-1)
  end

  it 'renders the post flat post regeneration form' do
    get '/admin/posts/regenerate_flat'
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:regenerate_flat)
    end
  end

  it 'renders the character relocate form' do
    old_user = create(:user, username: "Old")
    char = create(:character, user: old_user)
    new_user = create(:user, username: "New")

    get '/admin/characters/relocate'
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:relocate)
      expect(response.body).to include('Relocate Characters')
    end

    update_params = {
      character_id: char.id,
      user_id: new_user.id,
      include_templates: false,
    }
    post '/admin/characters/do_relocate', params: {
      **update_params,
      button_preview: true,
    }
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response).to render_template(:preview_relocate)
      expect(response.body).to include('Transferring the following characters from Old to New')
      expect(char.reload.user_id).not_to eq(new_user.id)
    end

    expect {
      post '/admin/characters/do_relocate', params: update_params
    }.to have_enqueued_job(UpdateModelJob).exactly(3).times
    aggregate_failures do
      expect(response).to redirect_to(admin_url)
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to eq('Characters relocated.')
    end
    perform_enqueued_jobs
    expect(char.reload.user_id).to eq(new_user.id)
  end
end
