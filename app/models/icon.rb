class Icon < ActiveRecord::Base
  belongs_to :user
  belongs_to :template
  has_and_belongs_to_many :galleries

  validates_presence_of :url, :user, :keyword
  validate :url_is_url
  nilify_blanks

  def to_json
    { id: id, url: url, keyword: keyword }
  end

  private

  def url_is_url
    return true if url.starts_with?('http')
    errors.add(:url, "must be an actual fully qualified url (http://www.example.com)")
  end
end
