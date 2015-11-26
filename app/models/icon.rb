class Icon < ActiveRecord::Base
  belongs_to :user
  belongs_to :template
  has_and_belongs_to_many :galleries

  validates_presence_of :url, :user, :keyword

  def to_json
    { id: id, url: url, keyword: keyword }
  end
end
