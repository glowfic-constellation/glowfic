require "spec_helper"
require "#{Rails.root}/lib/post_scraper"

RSpec.describe PostScraper do
  it "should add view to url" do
    scraper = PostScraper.new('http://wild-pegasus-appeared.dreamwidth.org/403.html')
    expect(scraper.url).to include('?view=flat')
  end

  it "should not change url if view is present" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?view=flat'
    scraper = PostScraper.new(url)
    expect(scraper.url.sub('view=flat', '')).not_to include('view=flat')
    expect(scraper.url.gsub("&style=site","").length).to eq(url.length)
  end

  it "should add site style to the url" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?view=flat'
    scraper = PostScraper.new(url)
    expect(scraper.url).to include('&style=site')
  end

  it "should not change url if site style is present" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?view=flat&style=site'
    scraper = PostScraper.new(url)
    expect(scraper.url.length).to eq(url.length)
  end

  it "should scrape properly when nothing is created" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_single_page.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    user = create(:user, username: "Marri")
    board = create(:board, creator: user)

    scraper = PostScraper.new(url, board.id)
    allow(scraper).to receive(:prompt_for_user) { user }
    allow(scraper).to receive(:set_from_icon) { nil }
    expect(scraper).to receive(:puts).with("Importing thread 'linear b'")

    scraper.scrape!

    expect(Post.count).to eq(1)
    expect(Reply.count).to eq(46)
    expect(User.count).to eq(1)
    expect(Icon.count).to eq(0)
    expect(Character.count).to eq(2)
    expect(Character.where(screenname: 'wild_pegasus_appeared').first).not_to be_nil
    expect(Character.where(screenname: 'undercover_talent').first).not_to be_nil
  end

  it "should scrape multiple pages" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    url_page_2 = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat&page=2'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_multi_page.html')
    file_page_2 = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_single_page.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    stub_request(:get, url_page_2).to_return(status: 200, body: File.new(file_page_2))
    user = create(:user, username: "Marri")
    board = create(:board, creator: user)

    scraper = PostScraper.new(url, board.id)
    allow(scraper).to receive(:prompt_for_user) { user }
    allow(scraper).to receive(:set_from_icon) { nil }
    expect(scraper).to receive(:puts).with("Importing thread 'linear b'")

    scraper.scrape!

    expect(Post.count).to eq(1)
    expect(Reply.count).to eq(92)
    expect(User.count).to eq(1)
    expect(Icon.count).to eq(0)
    expect(Character.count).to eq(2)
    expect(Character.where(screenname: 'wild_pegasus_appeared').first).not_to be_nil
    expect(Character.where(screenname: 'undercover_talent').first).not_to be_nil
  end

  it "should raise an error when an unexpected character is found" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    scraper = PostScraper.new(url)
    expect(scraper).to receive(:puts).with("Importing thread 'linear b'")
    expect { scraper.scrape! }.to raise_error(UnrecognizedUsernameError)
  end

  it "should scrape character, user and icon properly" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    user = create(:user, username: "Marri")
    board = create(:board, creator: user)

    scraper = PostScraper.new(url, board.id, nil, nil, true)
    allow(STDIN).to receive(:gets).and_return(user.username)
    expect(scraper).to receive(:puts).with("Importing thread 'linear b'")
    expect(scraper).to receive(:print).with("User ID or username for wild_pegasus_appeared? ")

    scraper.scrape!

    expect(Post.count).to eq(1)
    expect(Reply.count).to eq(0)
    expect(User.count).to eq(1)
    expect(Icon.count).to eq(1)
    expect(Character.count).to eq(1)
    expect(Character.where(screenname: 'wild_pegasus_appeared').first).not_to be_nil
  end

  it "doesn't recreate characters and icons if they exist" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))

    user = create(:user, username: "Marri")
    board = create(:board, creator: user)
    nita = create(:character, user: user, screenname: 'wild_pegasus_appeared', name: 'Juanita')
    icon = create(:icon, keyword: 'sad', url: 'http://v.dreamwidth.org/8517100/2343677', user: user)
    gallery = create(:gallery, user: user)
    gallery.icons << icon
    nita.galleries << gallery

    expect(User.count).to eq(1)
    expect(Icon.count).to eq(1)
    expect(Character.count).to eq(1)

    scraper = PostScraper.new(url, board.id)
    expect(scraper).not_to receive(:print).with("User ID or username for wild_pegasus_appeared? ")
    expect(scraper).to receive(:puts).with("Importing thread 'linear b'") # just to quiet it

    scraper.scrape!
    expect(User.count).to eq(1)
    expect(Icon.count).to eq(1)
    expect(Character.count).to eq(1)
  end

  it "doesn't recreate icons if they already exist for that character with new urls" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))

    user = create(:user, username: "Marri")
    board = create(:board, creator: user)
    nita = create(:character, user: user, screenname: 'wild_pegasus_appeared', name: 'Juanita')
    icon = create(:icon, keyword: 'sad', url: 'http://glowfic.com/uploaded/icon.png', user: user)
    gallery = create(:gallery, user: user)
    gallery.icons << icon
    nita.galleries << gallery

    expect(User.count).to eq(1)
    expect(Icon.count).to eq(1)
    expect(Character.count).to eq(1)

    scraper = PostScraper.new(url, board.id)
    expect(scraper).not_to receive(:print).with("User ID or username for wild_pegasus_appeared? ")
    expect(scraper).to receive(:puts).with("Importing thread 'linear b'") # just to quiet it

    scraper.scrape!
    expect(User.count).to eq(1)
    expect(Icon.count).to eq(1)
    expect(Character.count).to eq(1)
  end
end
