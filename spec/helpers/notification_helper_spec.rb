RSpec.describe NotificationHelper do
  include NotificationHelper

  describe "#subject_for_type" do
    it "returns message for import_success" do
      expect(subject_for_type('import_success')).to eq('Post import succeeded')
    end

    it "returns message for import_fail" do
      expect(subject_for_type('import_fail')).to eq('Post import failed')
    end

    it "returns message for new_favorite_post" do
      expect(subject_for_type('new_favorite_post')).to eq('An author you favorited has written a new post')
    end

    it "returns message for joined_favorite_post" do
      expect(subject_for_type('joined_favorite_post')).to eq('An author you favorited has joined a post')
    end

    it "returns nil for unknown type" do
      expect(subject_for_type('unknown')).to be_nil
    end
  end
end
