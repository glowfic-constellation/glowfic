class Post < ActiveRecord::Base
  include Writable

  PRIVACY_PUBLIC = 0
  PRIVACY_PRIVATE = 1
  PRIVACY_LIST = 2

  belongs_to :board
  has_many :replies, inverse_of: :post, dependent: :destroy
  has_many :post_viewers

  attr_accessible :board, :board_id, :subject, :privacy, :post_viewer_ids, :updated_at
  attr_accessor :post_viewer_ids

  validates_presence_of :board, :subject

  after_save :update_access_list

  audited
  has_associated_audits

  def visible_to?(user)
    return true if privacy == PRIVACY_PUBLIC
    return false unless user
    return user.id == user_id if privacy == PRIVACY_PRIVATE
    (post_viewers.map(&:user_id) + [user_id]).include?(user.id)
  end

  def last_post
    replies.order('updated_at desc').limit(1).first || self
  end

  def self.privacy_settings
    { 'Public'      => PRIVACY_PUBLIC,
      'Access List' => PRIVACY_LIST,
      'Private'     => PRIVACY_PRIVATE }
  end

  private

  def update_access_list
    return unless privacy == PRIVACY_LIST
    return unless post_viewer_ids

    updated_ids = (post_viewer_ids - [""]).map(&:to_i)
    existing_ids = post_viewers.map(&:user_id)

    PostViewer.where(post_id: id, user_id: (existing_ids - updated_ids)).destroy_all
    (updated_ids - existing_ids).each do |new_id|
      PostViewer.create(post_id: id, user_id: new_id)
    end
  end
end
