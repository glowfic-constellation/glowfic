class ProviderAuthorizer
  attr_accessor :user, :params, :app

  def initialize(user, authorized, params = {})
    @user = user
    @params = params
    @authorized = authorized
  end

  def app
    @app ||= ::ClientApplication.find_by_key!(params[:client_id])
  end

  def code
    @code ||= ::Oauth2Verifier.create! :client_application => app,
      :user => @user,
      :scope => @params[:scope],
      :callback_url => @params[:redirect_uri]
  end

  def token
    @token ||= ::Oauth2Token.create! :client_application => app,
      :user => @user,
      :scope => @params[:scope],
      :callback_url => @params[:redirect_uri]
  end

  def authorized?
    @authorized == true
  end

  def redirect_uri
    uri = base_uri
    if params[:response_type] == 'code'
      if uri.query
        uri.query << '&'
      else
        uri.query = ''
      end
      uri.query << encode_response
    else
      uri.fragment = encode_response
    end
    uri.to_s
  end

  def response
    r = {:state: params[:state]}
    unless authorized?
      r[:error] = 'access_denied'
    unless ['token','code'].include? params[:response_type]
      r[:error] = 'unsupported_response_type'
    if not r[:error]?
      if params[:response_type] == 'code'
        r[:code] = code.token
      else
        r[:access_token] = token.token
    r
  end

  def encode_response
    response.map do |k, v|
      [URI.escape(k.to_s),URI.escape(v)] * "="
    end * "&"
  end

  protected

  def base_uri
    URI.parse(params[:redirect_uri] || app.callback_url)
  end
end
