class ClientApplication < ApplicationRecord
  belongs_to :user
  has_many :tokens, class_name: "OauthToken", dependent: :destroy
  has_many :access_tokens, dependent: :destroy
  has_many :oauth2_verifiers, dependent: :destroy
  has_many :oauth_tokens, dependent: :destroy
  validates :name, presence: true
  validates :url, presence: true
  validates :key, presence: true
  validates :secret, presence: true
  validates :key, uniqueness: true
  before_validation :generate_keys, on: :create

  validates :url, format: { with: /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@\-\/]))?\z/i }
  validates :support_url, format: { with: /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@\-\/]))?\z/i, allow_blank: true }
  validates :callback_url,
    format: { with: /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@\-\/]))?\z/i, allow_blank: false }

  attr_accessor :token_callback_url

  protected

  def generate_keys
    self.key = SecureRandom.hex(20)
    self.secret = SecureRandom.hex(20)
  end
end
