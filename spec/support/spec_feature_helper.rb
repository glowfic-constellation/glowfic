module SpecFeatureHelper
  def login
    user = create(:user, password: 'known')
    visit root_path
    fill_in "username", with: user.username
    fill_in "password", with: 'known'
    click_button "Log in"
    user
  end
end
