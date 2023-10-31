module SpecRequestHelper
  # same as in our SpecFeatureHelper, but using IntegrationTest request format:
  # if given a user, the password must be 'known' or given as a parameter
  # otherwise, the helper will create a user with a given password
  # returns the user it logs in as, navigates to root_path
  def login(user=nil, password='known')
    user ||= create(:user, password: password)
    post login_path, params: { username: user.username, password: password }
    user
  end
end
