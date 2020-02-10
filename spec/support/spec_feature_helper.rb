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

  def select2(value, from:)
    SpecFeatureHelper.find_select2(page, from).click
    within page.find('.select2-results') do
      node = page.find('li', text: value, exact_text: true)
      node.click
    end
  end
  alias unselect2 select2

  RSpec::Matchers.define :have_multiselect do |finder, **args|
    match do |page|
      raise ArgumentError, "Missing matcher argument" unless args.key?(:selected)
      choices = Array(args[:selected]).map{ |choice| '×' + choice }
      nodes = SpecFeatureHelper.find_select2(page, finder).find_all('.select2-selection__choice')
      expect(nodes.map(&:text)).to match_array(choices)
    end
    failure_message do |page|
      choices = Array(args[:selected]).map{ |choice| '×' + choice }
      nodes = SpecFeatureHelper.find_select2(page, finder).find_all('.select2-selection__choice')
      matcher = RSpec::Matchers::BuiltIn::ContainExactly.new(choices)
      matcher.matches?(nodes.map(&:text))
      matcher.failure_message
    end
  end

  RSpec::Matchers.define :have_select2 do |finder, **args|
    match do |page|
      raise ArgumentError, "Missing matcher argument" unless args.key?(:selected)
      node = SpecFeatureHelper.find_select2(page, finder).find('.select2-selection__rendered')
      node.text == args[:selected]
    end
  end

  private

  def self.find_select2(page, finder)
    original = page.find_field(finder)
    original.first(:xpath, './following-sibling::span')
  end
end
