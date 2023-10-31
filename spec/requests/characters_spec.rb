RSpec.describe "Characters" do
  describe "GET /characters/:id" do
    let(:user) { create(:user, username: 'John Doe') }
    let(:expanded_character) do
      create(:character,
        user: user,
        template: create(:template, name: "A"),
        name: "Alice",
        nickname: "Lis",
        screenname: "player_one",
        settings: [
          create(:setting, name: 'Infosec'),
          create(:setting, name: 'Wander'),
        ],
        description: "Alice is a character",
        with_default_icon: true,
      )
    end
    let(:npc_character) do
      create(:character,
        user: user,
        npc: true,
        name: "John",
        nickname: "first thread",
        with_default_icon: true,
      )
    end

    it "calculates OpenGraph meta for basic character" do
      character = create(:character,
        user: user,
        name: "Alice",
        screenname: "player_one",
        description: "Alice is a character",
      )

      get "/characters/#{character.id}"
      expect(response).to render_template(:show)
      expect(response).to have_http_status(200)

      body = Nokogiri::HTML5::Document.parse(response.body)
      expect(body.at_css("meta[property='og:url']")[:content]).to eq(character_url(character))
      expect(body.at_css("meta[property='og:title']")[:content]).to eq('John Doe » Alice | player_one')
      expect(body.at_css("meta[property='og:description']")[:content]).to eq("Alice is a character")
    end

    it "calculates OpenGraph meta for expanded character" do
      create(:alias, character: expanded_character, name: "Alicia")
      create(:post, character: expanded_character, user: user)
      create(:reply, character: expanded_character, user: user)

      get "/characters/#{expanded_character.id}"
      expect(response).to render_template(:show)
      expect(response).to have_http_status(200)

      body = Nokogiri::HTML5::Document.parse(response.body)
      expect(body.at_css("meta[property='og:url']")[:content]).to eq(character_url(expanded_character))
      expect(body.at_css("meta[property='og:title']")[:content]).to eq('John Doe » A » Alice | player_one')
      desc = "Nicknames: Lis, Alicia. Settings: Infosec, Wander\nAlice is a character\n2 posts"
      expect(body.at_css("meta[property='og:description']")[:content]).to eq(desc)
      expect(body.at_css("meta[property='og:image']")[:content]).to eq(expanded_character.default_icon.url)
      expect(body.at_css("meta[property='og:image:height']")[:content]).to eq('75')
      expect(body.at_css("meta[property='og:image:width']")[:content]).to eq('75')
    end

    it "calculates OpenGraph meta for NPC character" do
      get "/characters/#{npc_character.id}"
      body = Nokogiri::HTML5::Document.parse(response.body)
      expect(body.at_css("meta[property='og:title']")[:content]).to eq('John Doe » John')
      expect(body.at_css("meta[property='og:description']")[:content]).to eq("Original post: first thread")
    end

    it "shows details for a non-NPC character" do
      get "/characters/#{expanded_character.id}"
      expect(response.body).to include('Alice')
      expect(response.body).to match(/character-screenname.*player_<wbr>one/)
      expect(response.body).to match(/character-icon.*img.*src="#{Regexp.quote(expanded_character.default_icon.url)}"/m)
      expect(response.body).not_to include("NPC")
      expect(response.body).to match(/Nickname.*Lis/m)
      expect(response.body).not_to include("Original post")
      expect(response.body).to match(/Setting.*<a[^>]*>Infosec<\/a>/m)
      expect(response.body).to match(/Description.*Alice is a character/m)
      expect(response.body).to match(/Template.*<a[^>]*>A<\/a>/m)
    end

    it "shows details for an NPC character" do
      get "/characters/#{npc_character.id}"
      expect(response.body).to include('John')
      expect(response.body).not_to include('character-screenname')
      expect(response.body).to match(/character-icon.*img.*src="#{Regexp.quote(npc_character.default_icon.url)}"/m)
      expect(response.body).to include('(NPC)')
      expect(response.body).not_to include('Nickname')
      expect(response.body).to match(/Original post.*first thread/m)
      expect(response.body).not_to include("Setting")
      expect(response.body).not_to include("Description")
      expect(response.body).not_to include("Template")
    end
  end
end
