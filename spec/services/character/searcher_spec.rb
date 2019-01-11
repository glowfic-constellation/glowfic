RSpec.describe Character::Searcher do
  let!(:name) { create(:character, name: 'a', screenname: 'b', nickname: 'c') }
  let!(:nickname) { create(:character, name: 'b', screenname: 'c', nickname: 'a') }
  let!(:screenname) { create(:character, name: 'c', screenname: 'a', nickname: 'b') }

  it "searches names correctly" do
    params = { name: 'a', search_name: true }
    results = Character::Searcher.new(templates: []).search(params: params)
    expect(results).to match_array([name])
  end

  it "searches screenname correctly" do
    params = { name: 'a', search_screenname: true }
    results = Character::Searcher.new(templates: []).search(params: params)
    expect(results).to match_array([screenname])
  end

  it "searches nickname correctly" do
    params = { name: 'a', search_nickname: true }
    results = Character::Searcher.new(templates: []).search(params: params)
    expect(results).to match_array([nickname])
  end

  it "searches name + screenname correctly" do
    params = { name: 'a', search_name: true, search_screenname: true }
    results = Character::Searcher.new(templates: []).search(params: params)
    expect(results).to match_array([name, screenname])
  end

  it "searches name + nickname correctly" do
    params = { name: 'a', search_name: true, search_nickname: true }
    results = Character::Searcher.new(templates: []).search(params: params)
    expect(results).to match_array([name, nickname])
  end

  it "searches nickname + screenname correctly" do
    params = { name: 'a', search_nickname: true, search_screenname: true }
    results = Character::Searcher.new(templates: []).search(params: params)
    expect(results).to match_array([nickname, screenname])
  end

  it "searches all correctly" do
    searcher = Character::Searcher.new(templates: [])
    results = searcher.search(params: {
      name: 'a',
      search_name: true,
      search_screenname: true,
      search_nickname: true,
    })
    expect(results).to match_array([name, screenname, nickname])
  end

  it "orders results correctly" do
    template = create(:template)
    user = template.user
    char4 = create(:character, user: user, template: template, name: 'd')
    char2 = create(:character, user: user, name: 'b')
    char1 = create(:character, user: user, template: template, name: 'a')
    char5 = create(:character, user: user, name: 'e')
    char3 = create(:character, user: user, name: 'c')
    results = Character::Searcher.new(templates: []).search(params: { author_id: user.id })
    expect(results).to eq([char1, char2, char3, char4, char5])
  end

  it "paginates correctly" do
    user = create(:user)
    26.times do |i|
      create(:character, user: user, name: "character#{i}")
    end
    results = Character::Searcher.new(templates: []).search(params: { author_id: user.id })
    expect(results.length).to eq(25)
  end
end