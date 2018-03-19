module SpecFeatureHelper
  # if given a user, the password must be 'known' or given as a parameter
  # otherwise, the helper will create a user with a given password
  # returns the user it logs in as, navigates to root_path
  def login(user = nil, password = 'known')
    user ||= create(:user, password: password)
    visit root_path
    fill_in "Username", with: user.username
    fill_in "Password", with: password
    click_button "Log in"
    if page.all('.flash.error').present?
      raise(RuntimeError, "Failed to log in as '#{user.username}':\n" + page.find('.flash.error').text)
    end
    user
  end

  def row_for(title)
    find('tr') { |x| x.has_selector?('th', text: title) }
  end
end
