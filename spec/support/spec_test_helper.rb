module SpecTestHelper  
  def login_as(user)
    request.session[:user_id] = user.id
  end

  def login
    login_as(create(:user))
  end
end
