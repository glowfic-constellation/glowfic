module OAuthControllerSpecHelper
  include ActiveJob::TestHelper
  def login_as_application_owner
    @user = User.find_by_id(1) || create(:user)
    @user.save!
    login_as(@user)
  end
  
  def setup_oauth
    @server=OAuth::Server.new "http://localhost:3000"
    @client_application = ClientApplication.create! :user => @user, :name => "Client Application name", :url => "http://localhost/", :callback_url => "http://localhost:3000/callback"
    @consumer=OAuth::Consumer.new(@client_application.key,@client_application.secret,{:site=>"http://localhost:3000"})

    @client_applications=[@client_application]
    @current_client_application = @client_application
    @current_client_applications = @client_applications
    @request_token = RequestToken.create :user => @user, :client_application => @client_application, :callback_url=>@client_application.callback_url
    
    @access_token = AccessToken.create :user => @user, :client_application => @client_application
  end
  
  def setup_oauth_for_user
    login_as_application_owner
    setup_oauth
    @tokens=[@request_token]
    @user.reload
    @current_user = @user
    # @user.tokens = @tokens
  end
  
  def sign_request_with_oauth(token=nil)
    ActionController::TestRequest.use_oauth=true
    @request.configure_oauth(@consumer,token)
  end
    
  def setup_to_authorize_request
    setup_oauth
  end
end
