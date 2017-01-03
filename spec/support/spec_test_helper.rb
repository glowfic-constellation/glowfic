module SpecTestHelper  
  def login_as(user)
    request.session[:user_id] = user.id
  end

  def login
    login_as(create(:user))
  end
end

module BackgroundJobs
  def run_background_jobs_immediately(&block)
    inline = Resque.inline
    Resque.inline = true
    yield
    Resque.inline = inline
  end
end
