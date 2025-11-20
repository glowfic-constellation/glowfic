RSpec.describe News do
  describe "#mark_read" do
    it "works for never reads" do
      news = create(:news)
      expect(NewsView.count).to eq(0)
      news.mark_read(news.user)

      aggregate_failures do
        expect(NewsView.count).to eq(1)
        expect(NewsView.last.news).to eq(news)
      end
    end

    it "works for subsequent reads" do
      news = create(:news)
      news.mark_read(news.user)
      view = NewsView.last
      new_news = create(:news)
      new_news.mark_read(news.user)
      expect(view.reload.news).to eq(new_news)
    end

    it "does nothing for historical reads" do
      news = create(:news)
      new_news = create(:news)
      new_news.mark_read(news.user)
      expect(NewsView.last.news).to eq(new_news)
      news.mark_read(news.user)
      expect(NewsView.last.news).to eq(new_news)
    end
  end

  describe "#num_unread_for" do
    let(:user) { create(:user) }
    let!(:news) { create(:news) }

    it "handles no user" do
      expect(News.num_unread_for(nil)).to eq(0)
    end

    it "returns correct number for partially read" do
      news.mark_read(user)
      create_list(:news, 5)
      expect(News.num_unread_for(user)).to eq(5)
    end

    it "returns correct number for unread" do
      create_list(:news, 5)
      expect(News.num_unread_for(user)).to eq(6)
    end

    context "caching" do
      it "creates cache when num_unread_for is called" do
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(false)
        expect(News.num_unread_for(user)).to eq(1)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(true)
      end

      it "deletes cache when NewsView is created" do
        expect(NewsView.count).to eq(0)
        news.mark_read(user)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(false)
      end

      it "deletes cache when NewsView is updated" do
        news.mark_read(user)
        expect(NewsView.count).to eq(1)
        create(:news)
        News.num_unread_for(user)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(true)
        news.mark_read(user)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(false)
      end

      it "deletes cache when News is created" do
        expect(News.num_unread_for(user)).to eq(1)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(true)
        create(:news)
        expect(Rails.cache.exist?(NewsView.cache_string_for(user.id))).to eq(false)
      end
    end
  end
end
