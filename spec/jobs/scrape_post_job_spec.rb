require Rails.root.join("app", "services", "post_scraper.rb")

RSpec.describe ScrapePostJob do
  include ActiveJob::TestHelper
  before(:each) do
    clear_enqueued_jobs
    allow(STDOUT).to receive(:puts).with("Importing thread 'linear b'")
  end

  it "creates the correct objects" do
    Post.auditing_enabled = true
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    stub_fixture(url, 'scrape_no_replies')
    board = create(:board)
    create(:character, screenname: 'wild_pegasus_appeared')
    params = {
      board_id: board.id,
      status: Post.statuses[:complete],
    }
    ScrapePostJob.perform_now(url, params, user: board.creator)
    expect(Message.count).to eq(1)
    expect(Message.first.subject).to eq("Post import succeeded")
    expect(Post.count).to eq(1)
    expect(Post.first.authors_locked).to eq(true)
    expect(Audited::Audit.count).to eq(2)
    expect(Audited::Audit.first.user_id).to eq(Post.last.user_id)
    expect(Audited::Audit.last.audited_changes.keys).to eq(['authors_locked'])
    Post.auditing_enabled = false
  end

  it "sends messages on username exceptions" do
    url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
    stub_fixture(url, 'scrape_no_replies')
    board = create(:board)

    params = {
      board_id: board.id,
      status: Post.statuses[:complete],
    }

    expect(ScrapePostJob).to receive(:notify_exception).with(
      an_instance_of(UnrecognizedUsernameError),
      url, params, user: board.creator,
    ).and_call_original

    begin
      ScrapePostJob.perform_now(url, params, user: board.creator)
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
    stub_fixture(url, 'scrape_no_replies')
    board = create(:board)
    create(:character, screenname: 'wild_pegasus_appeared', user: board.creator)
    scraper = PostScraper.new(url, board_id: board.id)
    scraper.scrape!

    params = {
      board_id: board.id,
      status: Post.statuses[:complete],
    }

    expect(ScrapePostJob).to receive(:notify_exception).with(
      an_instance_of(AlreadyImportedError),
      url, params, user: board.creator,
    ).and_call_original

    begin
      ScrapePostJob.perform_now(url, params, user: board.creator)
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
