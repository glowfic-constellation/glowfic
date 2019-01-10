RSpec.describe Reply::Searcher do
  it "finds all when no arguments given" do
    create_list(:reply, 4)
    get :search, params: { commit: true }
    expect(assigns(:search_results)).to match_array(Reply.all)
  end

  it "filters by author" do
    replies = create_list(:reply, 4)
    filtered_reply = replies.last
    get :search, params: { commit: true, author_id: filtered_reply.user_id }
    expect(assigns(:search_results)).to match_array([filtered_reply])
  end

  it "filters by icon" do
    create(:reply, with_icon: true)
    reply = create(:reply, with_icon: true)
    get :search, params: { commit: true, icon_id: reply.icon_id }
    expect(assigns(:search_results)).to match_array([reply])
  end

  it "filters by character" do
    create(:reply, with_character: true)
    reply = create(:reply, with_character: true)
    get :search, params: { commit: true, character_id: reply.character_id }
    expect(assigns(:search_results)).to match_array([reply])
  end

  it "filters by string" do
    reply = create(:reply, content: 'contains seagull')
    cap_reply = create(:reply, content: 'Seagull is capital')
    create(:reply, content: 'nope')
    get :search, params: { commit: true, subj_content: 'seagull' }
    expect(assigns(:search_results)).to match_array([reply, cap_reply])
  end

  it "filters by exact match case insensitively" do
    create(:reply, content: 'contains forks')
    create(:reply, content: 'Forks is capital')
    reply1 = create(:reply, content: 'Forks High is capital')
    reply2 = create(:reply, content: 'Forks high is kinda capital')
    reply3 = create(:reply, content: 'forks High is different capital')
    reply4 = create(:reply, content: 'forks high is not capital')
    create(:reply, content: 'Forks is split from High')
    create(:reply, content: 'nope')
    get :search, params: { commit: true, subj_content: '"Forks High"' }
    expect(assigns(:search_results)).to match_array([reply1, reply2, reply3, reply4])
  end

  it "filters by post" do
    replies = create_list(:reply, 4)
    filtered_reply = replies.last
    get :search, params: { commit: true, post_id: filtered_reply.post_id }
    expect(assigns(:search_results)).to match_array([filtered_reply])
  end

  it "filters by continuity" do
    continuity_post = create(:post, num_replies: 1)
    create(:post, num_replies: 1) # wrong post
    filtered_reply = continuity_post.replies.last
    get :search, params: { commit: true, board_id: continuity_post.board_id }
    expect(assigns(:search_results)).to match_array([filtered_reply])
  end

  it "filters by template" do
    character = create(:template_character)
    templateless_char = create(:character)
    reply = create(:reply, character: character, user: character.user)
    create(:reply, character: templateless_char, user: templateless_char.user)
    get :search, params: { commit: true, template_id: character.template_id }
    expect(assigns(:search_results)).to match_array([reply])
  end

  it "sorts by created desc" do
    reply = create(:reply)
    reply2 = Timecop.freeze(reply.created_at + 2.minutes) do
      create(:reply)
    end
    get :search, params: { commit: true, sort: 'created_new' }
    expect(assigns(:search_results)).to eq([reply2, reply])
  end

  it "sorts by created asc" do
    reply = create(:reply)
    reply2 = Timecop.freeze(reply.created_at + 2.minutes) do
      create(:reply)
    end
    get :search, params: { commit: true, sort: 'created_old' }
    expect(assigns(:search_results)).to eq([reply, reply2])
  end
end
