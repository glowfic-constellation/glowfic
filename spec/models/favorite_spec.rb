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

      expect(f).to be_valid
      expect(f2).to be_valid
      expect(f.save).to eq(true)
      expect(f2).not_to be_valid
    end

    it "should allow you to favorite something someone else did" do
      f = Favorite.new
      f2 = Favorite.new
      f.user = create(:user)
      f2.user = create(:user)
      f.favorite = f2.favorite = create(:post)

      expect(f).to be_valid
      expect(f2).to be_valid
      expect(f.save).to eq(true)
      expect(f2.save).to eq(true)
    end

    it "should allow you to favorite multiple things" do
      user = create(:user)
      favorites = [create(:post), create(:user), create(:board)].map do |favorite|
        Favorite.new(user: user, favorite: favorite)
      end

      expect(favorites).to all(be_valid)
      expect(favorites.map(&:save)).to all(eq(true))
      expect(user.favorites.count).to eq(3)
    end
  end
end
