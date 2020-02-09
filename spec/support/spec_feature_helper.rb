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

  def select2(finder, *options)
    options.each do |option|
      page.find(finder).sibling('.select2-container').click
      within page.find('.select2-results') { page.find('li', text: option, exact_text: true).click }
    end
  end

  RSpec::Matchers.define :have_multiselect do |finder, **args|
    match do |page|
      raise ArgumentError, "Missing matcher argument" unless args.key?(:selected)
      choices = Array(args[:selected]).map{ |choice| '×' + choice }
      xpath = SpecFeatureHelper.locate_field(:select2, finder)
      nodes = page.find(:xpath, xpath).find_all('.select2-selection__choice')
      expect(nodes.map(&:text)).to match_array(choices)
    end
  end

  RSpec::Matchers.define :have_select2 do |finder, **args|
    match do |page|
      raise ArgumentError, "Missing matcher argument" unless args.key?(:selected)
      xpath = SpecFeatureHelper.locate_field(:select2, finder)
      node = page.find(:xpath, xpath).find('.select2-selection__rendered')
      expect(node.text).to eq(args[:selected])
    end
  end

  private

  # modified from https://github.com/teamcapybara/capybara/blob/3.29_stable/lib/capybara/selector/selector.rb#L116
  def self.locate_field(tag, locator)
    xpath = XPath.descendant(tag)
    return xpath if locator.nil?

    locate_xpath = xpath
    locator = locator.to_s
    attr_matchers = [XPath.attr(:id) == locator,
                     XPath.attr(:name) == locator,
                     XPath.attr(:placeholder) == locator,
                     XPath.attr(:id) == XPath.anywhere(:label)[XPath.string.n.is(locator)].attr(:for)].reduce(:|)

    locate_xpath = locate_xpath[attr_matchers]
    locate_xpath + XPath.descendant(:label)[XPath.string.n.is(locator)].descendant(xpath)
  end
end
