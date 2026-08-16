RSpec.describe ClientApplication do
  let(:user) { create(:user) }
  let(:application) { ClientApplication.create! name: "Agree2", url: "http://agree2.com", user: user, callback_url: "http://test.com/callback" }

  it "should be valid" do
    expect(application).to be_valid
  end

  it "should not have errors" do
    expect(application.errors.full_messages).to eq []
  end

  it "should have key and secret" do
    expect(application.key).not_to be_nil
    expect(application.secret).not_to be_nil
  end

  it "should generate unique key and secret" do
    expect(application.key).not_to eq application.secret
  end
end
