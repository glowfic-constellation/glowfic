RSpec.describe Favorite do
  describe "validations" do
    it "should require a user" do
      f = Favorite.new
      f.favorite = create(:post)
      expect(f).not_to be_valid
    end

    it "should require a favorite" do
      f = Favorite.new
      f.user = create(:user)
      expect(f).not_to be_valid
    end

    it "should not allow you to favorite yourself" do
      f = Favorite.new
      f.user = f.favorite = create(:user)
      expect(f).not_to be_valid
    end

    it "should not allow you to favorite something twice" do
      f = Favorite.new
      f2 = Favorite.new
      f.user = f2.user = create(:user)
      f.favorite = f2.favorite = create(:post)

      aggregate_failures do
        expect(f).to be_valid
        expect(f2).to be_valid
        expect(f.save).to eq(true)
        expect(f2).not_to be_valid
      end
    end

    it "should allow you to favorite something someone else did" do
      f = Favorite.new
      f2 = Favorite.new
      f.user = create(:user)
      f2.user = create(:user)
      f.favorite = f2.favorite = create(:post)

      aggregate_failures do
        expect(f).to be_valid
        expect(f2).to be_valid
        expect(f.save).to eq(true)
        expect(f2.save).to eq(true)
      end
    end

    skip "should allow you to favorite multiple things"
  end
end
