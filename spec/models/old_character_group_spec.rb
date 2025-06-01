RSpec.describe OldCharacterGroup do
  it "loads" do
    group = create(:old_character_group)
    expect(group).to be_valid
  end
end
