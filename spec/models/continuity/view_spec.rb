RSpec.describe Continuity::View do
  describe "validations" do
    it "requires board" do
      view = build(:continuity_view, continuity: nil)
      expect(view).not_to be_valid
      expect(view.save).to eq(false)
    end

    it "requires user" do
      view = build(:continuity_view, user: nil)
      expect(view).not_to be_valid
      expect(view.save).to eq(false)
    end

    it "works with both user and board" do
      view = build(:continuity_view)
      user = view.user
      board = view.continuity
      expect(view).to be_valid
      expect(view.save).to eq(true)
      view.reload
      expect(view.user).to eq(user)
      expect(view.continuity).to eq(board)
    end

    it "is unique by board and user" do
      view = create(:continuity_view)
      new_view = build(:continuity_view, user: view.user, continuity: view.continuity)
      expect(new_view).not_to be_valid
      expect(new_view.save).to eq(false)
      expect {
        new_view.save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows one user to have multiple board views" do
      user = create(:user)
      view = create(:continuity_view, user: user)
      new_view = build(:continuity_view, user: user)
      expect(new_view.continuity).not_to eq(view.continuity)
      expect(new_view).to be_valid
      expect(new_view.save).to eq(true)
    end

    it "allows one board to have multiple users in board views" do
      board = create(:board)
      view = create(:continuity_view, continuity: board)
      new_view = build(:continuity_view, continuity: board)
      expect(new_view.user).not_to eq(view.user)
      expect(new_view).to be_valid
      expect(new_view.save).to eq(true)
    end
  end
end
