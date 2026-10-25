module SpecRequestHelper
  # constant as a method to allow it to be .included by RSpec
  def known_test_password
    'knownpass'
  end

  # same as in our SpecFeatureHelper, but using IntegrationTest request format:
  # if given a user, the password must be known_test_password or given as a parameter
  # otherwise, the helper will create a user with a given password
  # returns the user it logs in as, navigates to root_path
  def login(user=nil, password=known_test_password)
    user ||= create(:user, password: password)
    post login_path, params: { username: user.username, password: password }

    aggregate_failures do
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to include("You are now logged in")
    end

    user
  end

  def text_clean(text)
    text = text.text if text.is_a?(Nokogiri::XML::Element)
    text.strip.gsub(/[\s\n]+/, " ").strip
  end
end
