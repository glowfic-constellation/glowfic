RSpec.describe PostImporter, :aggregate_failures do
  include ActiveJob::TestHelper

  describe "import" do
    let(:url) { 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat' }

    before(:each) { clear_enqueued_jobs }

    context "when validating url" do
      it "raises error on nil url" do
        importer = PostImporter.new(nil)
        expect { importer.import({}, user: nil) }.to raise_error(InvalidDreamwidthURL)
        expect(ScrapePostJob).not_to have_been_enqueued
      end

      it "raises error on empty url" do
        importer = PostImporter.new('')
        expect { importer.import({}, user: nil) }.to raise_error(InvalidDreamwidthURL)
        expect(ScrapePostJob).not_to have_been_enqueued
      end

      it "raises error without dreamwidth url" do
        importer = PostImporter.new('http://www.google.com')
        expect { importer.import({}, user: nil) }.to raise_error(InvalidDreamwidthURL)
        expect(ScrapePostJob).not_to have_been_enqueued
      end

      it "raises error without dreamwidth.org url" do
        importer = PostImporter.new('http://www.dreamwidth.com')
        expect { importer.import({}, user: nil) }.to raise_error(InvalidDreamwidthURL)
        expect(ScrapePostJob).not_to have_been_enqueued
      end

      it "raises error on malformed url" do
        importer = PostImporter.new('http://localhostdreamwidth:3000index')
        expect { importer.import({}, user: nil) }.to raise_error(InvalidDreamwidthURL)
        expect(ScrapePostJob).not_to have_been_enqueued
      end
    end

    context "when validating duplicate imports" do
      let(:post) { create(:post, subject: 'linear b') }

      before(:each) do
        stub_fixture(url, 'scrape_no_replies')
        create(:character, screenname: 'wild_pegasus_appeared', user: post.user)
      end

      it "does not raise error on threaded imports" do
        importer = PostImporter.new(url)
        params = { board_id: post.board_id, threaded: true }
        expect { importer.import(params, user: nil) }.not_to raise_error
        expect(ScrapePostJob).to have_been_enqueued
      end

      it "does not raise error on different continuity imports" do
        importer = PostImporter.new(url)
        params = { board_id: post.board_id + 1 }
        expect { importer.import(params, user: nil) }.not_to raise_error
        expect(ScrapePostJob).to have_been_enqueued
      end

      it "raises error on duplicate" do
        importer = PostImporter.new(url)
        params = { board_id: post.board_id }
        expect { importer.import(params, user: nil) }.to raise_error(AlreadyImported)
        expect(ScrapePostJob).not_to have_been_enqueued
      end
    end

    context "when validating duplicate usernames" do
      it "requires usernames to exist" do
        stub_fixture(url, 'scrape_no_replies')
        importer = PostImporter.new(url)
        expect { importer.import({}, user: nil) }.to raise_error(MissingUsernames)
        expect(ScrapePostJob).not_to have_been_enqueued
      end

      it "handles usernames with - instead of _" do
        create(:character, screenname: 'wild-pegasus-appeared')
        stub_fixture(url, 'scrape_no_replies')
        importer = PostImporter.new(url)
        expect { importer.import({}, user: nil) }.not_to raise_error
        expect(ScrapePostJob).to have_been_enqueued
      end
    end

    it "should enqueue a job on success" do
      create(:character, screenname: 'wild_pegasus_appeared')
      stub_fixture(url, 'scrape_no_replies')
      importer = PostImporter.new(url)
      params = { board_id: 5, section_id: 3, status: 1, threaded: true }
      user = User.find_by(id: 2)
      expect { importer.import(params, user: user) }.not_to raise_error
      expect(ScrapePostJob).to have_been_enqueued.with(url, params, user: user).on_queue('low')
    end
  end
end
