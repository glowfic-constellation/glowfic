# frozen_string_literal: true
class Authentication < Object
  EXPIRY = 30.days

  KEY_API_DEVELOPMENT =
    "7eb344b36d448da51c98879c76a393612146d49d57e5a168daab980681d62737" \
    "3d77fb35e9748fc5f4765ba83ffc88fd10ca2b3e9a47712a916cb1485dff0717"

  attr_reader :user, :error

  def authenticate(username, password)
    user = User.find_by(username: username)
    return false unless valid_user?(user)

    if user.password_resets.active.unused.exists?
      @error = "The password for this account has been reset. Please check your email."
      return false
    end

    unless user.authenticate(password)
      @error = "You have entered an incorrect password."
      return false
    end

    ensure_uuid_set(user, password)
    @user = user
  end

  def api_token
    Authentication.generate_api_token(@user)
  end

  def self.generate_api_token(user)
    payload = {
      user_id: user.id,
      exp: Authentication::EXPIRY.from_now.to_i,
    }
    JWT.encode(payload, Authentication.secret_key_api)
  end

  def self.read_api_token(value)
    JWT.decode(value, Authentication.secret_key_api)[0]
  end

  def self.secret_key_api
    return KEY_API_DEVELOPMENT unless Rails.env.production?
    ENV.fetch("SECRET_KEY_API")
  end

  private

  def valid_user?(user)
    if !user || user.deleted?
      @error = "That username does not exist."
      return false
    end

    if user.suspended?
      @error = "You could not be logged in."
      notify_admins_of_blocked_login(user)
      return false
    end

    true
  end

  def notify_admins_of_blocked_login(user)
    raise NameError.new("Login attempt by suspended user #{user.id}")
  rescue NameError => e
    ExceptionNotifier.notify_exception(e)
  end

  def ensure_uuid_set(user, password)
    return if user.salt_uuid.present?

    user.salt_uuid = SecureRandom.uuid
    user.crypted = user.send(:crypted_password, password)
    user.save!
  end
end
