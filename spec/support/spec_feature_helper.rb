module SpecSystemHelper
  # constant as a method to allow it to be .included by RSpec
  def known_test_password
    'knownpass'
  end

  # if given a user, the password must be known_test_password or given as a parameter
  # otherwise, the helper will create a user with a given password
  # returns the user it logs in as, navigates to root_path
  def login(user=nil, password=known_test_password)
    user ||= create(:user, password: password)
    visit root_path
    fill_in "Username", with: user.username
    fill_in "Password", with: password
    click_button "Log in"
    raise(RuntimeError, "Failed to log in as '#{user.username}':\n" + page.find('.flash.error').text) if page.all('.flash.error').present?
    user
  end

  def row_for(title, **args)
    find('tr') { |x| x.has_selector?('th', text: title, **args) }
  end

  def table_titled(title)
    find('table') { |x| x.has_selector?('.table-title', text: title) }
  end
end
