require "spec_helper"

RSpec.describe News do
  describe "#mark_read" do
    it "works for never reads" do
      news = create(:news)
      expect(NewsView.count).to eq(0)
      news.mark_read(news.user)
      expect(NewsView.count).to eq(1)
      expect(NewsView.last.news).to eq(news)
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
    it "handles no user" do
      expect(News.num_unread_for(nil)).to eq(0)
    end

    it "returns correct number for partially read" do
      news = create(:news)
      news.mark_read(news.user)
      create_list(:news, 5)
      expect(News.num_unread_for(news.user)).to eq(5)
    end

    it "returns correct number for unread" do
      news = create(:news)
      create_list(:news, 5)
      expect(News.num_unread_for(news.user)).to eq(6)
    end
  end
end
