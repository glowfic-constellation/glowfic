class Post < ActiveRecord::Base
  include Writable
  include Viewable

  PRIVACY_PUBLIC = 0
  PRIVACY_PRIVATE = 1
  PRIVACY_LIST = 2

  STATUS_ACTIVE = 0
  STATUS_COMPLETE = 1

  belongs_to :board
  belongs_to :section, class_name: BoardSection
  has_many :replies, inverse_of: :post, dependent: :destroy
  has_many :post_viewers

  attr_accessible :board, :board_id, :subject, :privacy, :post_viewer_ids, :description
  attr_accessor :post_viewer_ids

  validates_presence_of :board, :subject

  after_save :update_access_list

  audited
  has_associated_audits

  def visible_to?(user)
    return true if privacy == PRIVACY_PUBLIC
    return false unless user
    return user.id == user_id if privacy == PRIVACY_PRIVATE
    @visible ||= (post_viewers.map(&:user_id) + [user_id]).include?(user.id)
  end

  def authors
    return @authors if @authors
    return @authors = [user] if author_ids.count == 1
    @authors = User.where(id: author_ids).to_a
  end

  def author_ids
    @author_ids ||= (replies.select(:user_id).group(:user_id).map(&:user_id) + [user_id]).uniq
  end

  def last_post
    @last_post ||= (replies.order('updated_at desc').limit(1).first || self)
  end

  def last_character_for(user)
    ordered_replies = replies.where(user_id: user.id).order('id asc')
    if ordered_replies.present?
      ordered_replies.last.character
    elsif self.user == user
      self.character
    else
      user.active_character
    end
  end

  def first_unread_for(user)
    return @first_unread if @first_unread
    viewed_at = last_read(user) || board.last_read(user)
    return @first_unread = self unless viewed_at
    return unless replies.present?
    @first_unread ||= replies.order('updated_at asc').detect { |reply| viewed_at < reply.updated_at }
  end

  def completed?
    status == STATUS_COMPLETE
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
