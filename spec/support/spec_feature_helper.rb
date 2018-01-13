module SpecFeatureHelper
  def login
    user = create(:user, password: 'known')
    visit root_path
    fill_in "username", with: user.username
    fill_in "password", with: 'known'
    click_button "Log in"
    user
  end

  def row_for(title)
    find('tr') { |x| x.has_selector?('th', text: title) }
  end
end
