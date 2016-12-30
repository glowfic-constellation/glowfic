class Post < ActiveRecord::Base
  include Writable
  include Viewable
  include PostOrderable
  include PgSearch

  PRIVACY_PUBLIC = 0
  PRIVACY_PRIVATE = 1
  PRIVACY_LIST = 2
  PRIVACY_REGISTERED = 3

  STATUS_ACTIVE = 0
  STATUS_COMPLETE = 1
  STATUS_HIATUS = 2
  STATUS_ABANDONED = 3

  EDITED_ATTRS = %w(subject content icon_id character_id)

  belongs_to :board, inverse_of: :posts
  belongs_to :section, class_name: BoardSection, inverse_of: :posts
  belongs_to :last_user, class_name: User
  belongs_to :last_reply, class_name: Reply
  has_many :replies, inverse_of: :post, dependent: :destroy
  has_many :post_viewers, dependent: :destroy
  has_many :reply_drafts, dependent: :destroy
  has_many :post_tags, inverse_of: :post, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :settings, through: :post_tags, source: :setting
  has_many :content_warnings, through: :post_tags, source: :content_warning
  has_many :favorites, as: :favorite, dependent: :destroy

  attr_accessible :board, :board_id, :subject, :privacy, :post_viewer_ids, :description, :section_id, :tag_ids, :warning_ids, :setting_ids, :section_order
  attr_accessor :post_viewer_ids, :tag_ids, :warning_ids, :setting_ids
  attr_writer :skip_edited

  validates_presence_of :board, :subject

  after_save :update_access_list, :update_tag_list

  audited except: [:last_reply_id, :last_user_id, :edited_at, :tagged_at, :section_id, :section_order]
  has_associated_audits

  pg_search_scope(
    :search,
    against: %i(
      subject
      content
    ),
    using: {tsearch: { dictionary: "english" } }
  )
  scope :no_tests, where('posts.board_id != ?', Board::ID_SITETESTING)

  def visible_to?(user)
    return true if privacy == PRIVACY_PUBLIC
    return false unless user
    return true if privacy == PRIVACY_REGISTERED
    return true if user.admin?
    return user.id == user_id if privacy == PRIVACY_PRIVATE
    @visible ||= (post_viewers.map(&:user_id) + [user_id]).include?(user.id)
  end

  def authors
    return @authors if @authors
    return @authors = [user] if author_ids.count == 1
    @authors = User.where(id: author_ids).to_a
  end

  def author_ids
    @author_ids ||= (replies.group(:user_id).pluck(:user_id) + [user_id]).uniq
  end

  def last_character_for(user)
    ordered_replies = replies.where(user_id: user.id).order('id asc')
    if ordered_replies.exists?
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
    return unless replies.exists?
    @first_unread ||= replies.where('created_at > ?', viewed_at).order('created_at asc').first
  end

  def hide_warnings_for(user)
    view_for(user).update_attributes(warnings_hidden: true)
  end

  def show_warnings_for?(user)
    !(view_for(user).try(:warnings_hidden))
  end

  def completed?
    status == STATUS_COMPLETE
  end

  def on_hiatus?
    status == STATUS_HIATUS || (active? && tagged_at < 1.month.ago)
  end

  def active?
    status == STATUS_ACTIVE
  end

  def abandoned?
    status == STATUS_ABANDONED
  end

  def last_updated
    edited_at
  end

  def read_time_for(viewing_replies)
    return self.edited_at if viewing_replies.empty?

    most_recent = viewing_replies.max_by(&:id)
    most_recent_id = replies.select(:id).order('id desc').first.id
    return most_recent.updated_at if most_recent.id == most_recent_id
    most_recent.created_at
  end

  def metadata_editable_by?(user)
    return false unless user
    return true if user.admin?
    author_ids.include?(user.id)
  end

  def characters
    @chars ||= Character.where(id: ([character_id] + replies.group(:character_id).pluck(:character_id)).compact).sort_by(&:name)
  end

  def taggable_by?(user)
    return false unless user
    return false if completed? || abandoned?
    return false unless user.writes_in?(board)
    return true unless authors_locked?
    author_ids.include?(user.id)
  end

  def total_word_count
    return word_count unless replies.exists?
    contents = replies.pluck(:content)
    contents[0] = contents[0].split.size
    word_count + contents.inject{|r, e| r + e.split.size}.to_i
  end

  private

  def update_access_list
    return unless privacy_changed? || privacy == PRIVACY_LIST
    PostViewer.where(post_id: id).destroy_all and return unless privacy == PRIVACY_LIST
    return unless post_viewer_ids

    updated_ids = (post_viewer_ids - [""]).map(&:to_i)
    existing_ids = post_viewers.map(&:user_id)

    PostViewer.where(post_id: id, user_id: (existing_ids - updated_ids)).destroy_all
    (updated_ids - existing_ids).each do |new_id|
      PostViewer.create(post_id: id, user_id: new_id)
    end
  end

  def update_tag_list
    return unless tag_ids.present? || setting_ids.present? || warning_ids.present?

    updated_ids = (tag_ids + setting_ids + warning_ids - ['']).map(&:to_i).reject(&:zero?).uniq.compact
    existing_ids = post_tags.map(&:tag_id)

    PostTag.where(post_id: id, tag_id: (existing_ids - updated_ids)).destroy_all
    (updated_ids - existing_ids).each do |new_id|
      PostTag.create(post_id: id, tag_id: new_id)
    end
  end

  def timestamp_attributes_for_update
    # Makes Rails treat edited_at as a timestamp identical to updated_at
    # if specific attributes are updated. Also uses tagged_at if there
    # are no replies yet.
    # Be VERY CAREFUL editing this!
    return super if skip_edited
    return super + [:edited_at] if replies.exists?
    super + [:edited_at, :tagged_at]
  end

  def skip_edited
    @skip_edited || !EDITED_ATTRS.any?{ |edit| send(edit + "_changed?")}
  end

  def timestamp_attributes_for_create
    super + [:tagged_at]
  end

  def ordered_attributes
    [:section_id, :board_id]
  end
end
