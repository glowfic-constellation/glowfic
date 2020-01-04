module SpecFeatureHelper
  # if given a user, the password must be 'known' or given as a parameter
  # otherwise, the helper will create a user with a given password
  # returns the user it logs in as, navigates to root_path
  def login(user=nil, password='known')
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

  def table_titled(title)
    find('table') { |x| x.has_selector?('.table-title', text: title) }
  end

  def select2(finder, text)
    page.find(finder).sibling('.select2-container').click
    within page.find('.select2-results') do
      page.find('li', text: text).click
    end
  end

  RSpec::Matchers.define :have_multiselect do |finder, **args|
    match do |page|
      raise ArgumentError, "Missing matcher argument" unless args.key?(:with)
      choices = Array(args[:with])
      nodes = page.find(finder).sibling('.select2-container').find_all('.select2-selection__choice')
      choices.map!{ |choice| '×' + choice }
      expect(nodes.map(&:text)).to match_array(choices)
    end
  end
end
