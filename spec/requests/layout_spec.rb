RSpec.describe "Layout" do
  it "declares the page language" do
    get "/login"
    expect(response.body).to include('<html lang=')
  end
end
