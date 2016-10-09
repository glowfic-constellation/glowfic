class BoardView < ActiveRecord::Base
  belongs_to :board
  belongs_to :user

  validates_presence_of :user, :board

  def timestamp_attributes_for_create
    super + [:read_at]
  end
end
