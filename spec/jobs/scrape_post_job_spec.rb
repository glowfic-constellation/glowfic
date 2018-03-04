require "spec_helper"

RSpec.describe ScrapePostJob do
  include ActiveJob::TestHelper
  before(:each) do
    clear_enqueued_jobs
    allow(STDOUT).to receive(:puts).with("Importing thread 'linear b'")
  end

  it "creates the correct objects" do
    Post.auditing_enabled = true
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = Rails.root.join('spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    board = create(:board)
    create(:character, screenname: 'wild_pegasus_appeared')
    ScrapePostJob.perform_now(url, board.id, nil, Post::STATUS_COMPLETE, false, board.creator_id)
    expect(Message.count).to eq(1)
    expect(Message.first.subject).to eq("Post import succeeded")
    expect(Post.count).to eq(1)
    expect(Audited::Audit.count).to eq(1)
    expect(Audited::Audit.last.user_id).to eq(Post.last.user_id)
    Post.auditing_enabled = false
  end

  it "sends messages on username exceptions" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    file = Rails.root.join('spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    board = create(:board)

    expect(ScrapePostJob).to receive(:notify_exception).with(an_instance_of(UnrecognizedUsernameError), url, board.id, nil, Post::STATUS_COMPLETE, false, board.creator_id).and_call_original

    begin
      ScrapePostJob.perform_now(url, board.id, nil, Post::STATUS_COMPLETE, false, board.creator_id)
    rescue UnrecognizedUsernameError
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
    file = Rails.root.join('spec', 'support', 'fixtures', 'scrape_no_replies.html')
    stub_request(:get, url).to_return(status: 200, body: File.new(file))
    board = create(:board)
    create(:character, screenname: 'wild_pegasus_appeared', user: board.creator)
    scraper = PostScraper.new(url, board.id)
    scraper.scrape!

    expect(ScrapePostJob).to receive(:notify_exception).with(an_instance_of(AlreadyImportedError), url, board.id, nil, Post::STATUS_COMPLETE, false, board.creator_id).and_call_original

    begin
      ScrapePostJob.perform_now(url, board.id, nil, Post::STATUS_COMPLETE, false, board.creator_id)
    rescue AlreadyImportedError
      expect(Message.count).to eq(1)
      expect(Message.first.subject).to eq("Post import failed")
      expect(Message.first.message).to include("already imported")
      expect(Post.count).to eq(1)
    else
      raise "Error should be handled"
    end
  end
end
