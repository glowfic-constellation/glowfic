require "spec_helper"

RSpec.describe ScrapePostJob do
  it "creates the correct objects" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    board = create(:board)
    create(:character, screenname: 'wild_pegasus_appeared')
    ScrapePostJob.process(url, board.id, nil, Post::STATUS_COMPLETE, board.creator_id)
    expect(Message.count).to eq(1)
    expect(Message.first.subject).to eq("Post import succeeded")
    expect(Post.count).to eq(1)
  end

  it "sends messages on username exceptions" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    board = create(:board)

    begin
      Resque.enqueue(ScrapePostJob, url, board.id, nil, Post::STATUS_COMPLETE, board.creator_id)
      ResqueSpec.perform_next(ScrapePostJob.queue)
    rescue UnrecognizedUsernameError => e
      ScrapePostJob.notify_exception(e, url, board.id, nil, Post::STATUS_COMPLETE, board.creator_id)
      expect(Message.count).to eq(1)
      expect(Message.first.subject).to eq("Post import failed")
      expect(Message.first.message).to include("wild_pegasus_appeared")
      expect(Post.count).to eq(0)
    else
      raise "Error should be handled"
    end
  end

  it "sends messages on imported exceptions" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = File.join(Rails.root, 'spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    board = create(:board)
    create(:character, screenname: 'wild_pegasus_appeared', user: board.creator)
    scraper = PostScraper.new(url, board.id)
    scraper.scrape!

    begin
      Resque.enqueue(ScrapePostJob, url, board.id, nil, Post::STATUS_COMPLETE, board.creator_id)
      ResqueSpec.perform_next(ScrapePostJob.queue)
    rescue AlreadyImportedError => e
      ScrapePostJob.notify_exception(e, url, board.id, nil, Post::STATUS_COMPLETE, board.creator_id)
      expect(Message.count).to eq(1)
      expect(Message.first.subject).to eq("Post import failed")
      expect(Message.first.message).to include("already imported")
      expect(Post.count).to eq(1)
    else
      raise "Error should be handled"
    end
  end
end
