class Post < ActiveRecord::Base
  include Presentable
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
  has_one :flat_post
  has_many :replies, inverse_of: :post, dependent: :destroy
  has_many :post_viewers, dependent: :destroy
  has_many :viewers, through: :post_viewers, source: :user
  has_many :reply_drafts, dependent: :destroy
  has_many :post_tags, inverse_of: :post, dependent: :destroy
  has_many :labels, through: :post_tags, source: :label
  has_many :settings, through: :post_tags, source: :setting
  has_many :content_warnings, through: :post_tags, source: :content_warning, after_add: :reset_warnings
  has_many :favorites, as: :favorite, dependent: :destroy

  attr_accessible :board, :board_id, :subject, :privacy, :viewer_ids, :description, :section_id, :label_ids, :warning_ids, :setting_ids, :section_order, :status
  attr_accessor :label_ids, :warning_ids, :setting_ids
  attr_writer :skip_edited

  validates_presence_of :board, :subject
  validate :valid_board, :valid_board_section

  before_create :build_initial_flat_post
  after_save :update_tag_list
  before_create :set_last_user

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

  def build_new_reply_for(user)
    draft = ReplyDraft.draft_reply_for(self, user)
    return draft if draft.present?

    reply = Reply.new(post: self, user: user)
    user_replies = replies.where(user_id: user.id).order('id asc')

    if user_replies.exists?
      last_user_reply = user_replies.last
      reply.character_id = last_user_reply.character_id
      reply.character_alias_id = last_user_reply.character_alias_id
    elsif self.user == user
      reply.character_id = self.character_id
      reply.character_alias_id = self.character_alias_id
    elsif user.active_character_id.present?
      reply.character_id = user.active_character_id
    end

    if reply.character_id.nil?
      reply.icon_id = user.avatar_id
    else
      reply.icon_id = reply.character.default_icon.try(:id)
    end

    return reply
  end

  def first_unread_for(user)
    return @first_unread if @first_unread
    viewed_at = last_read(user) || board.last_read(user)
    return @first_unread = self unless viewed_at
    return unless replies.exists?
    reply = replies.where('created_at > ?', viewed_at).order('id asc').first
    @first_unread ||= reply
  end

  def last_seen_reply_for(user)
    return @last_seen if @last_seen
    return unless replies.exists? # unlike first_unread_for we don't care about the post
    viewed_at = last_read(user) || board.last_read(user)
    return unless viewed_at
    reply = replies.where('created_at <= ?', viewed_at).order('id desc').first
    @last_seen ||= reply
  end

  def recent_characters_for(user, count=4)
    # fetch the 4 (count) most recent non-nil character_ids for user in post
    recent_ids = replies.where(user_id: user.id).where('character_id IS NOT NULL').limit(count).group('character_id').select('DISTINCT character_id, MAX(id)').order('MAX(id) desc').pluck(:character_id)

    # add the post's character_id to the last one if it's not over the limit
    if character_id.present? && user_id == user.id && recent_ids.length < count && !recent_ids.include?(character_id)
      recent_ids << character_id
    end

    # fetch the relevant characters and sort by their index in the recent list
    Character.where(id: recent_ids).includes(:default_icon).sort_by do |x|
      recent_ids.index(x.id)
    end
  end

  def hide_warnings_for(user)
    view_for(user).update_attributes(warnings_hidden: true)
  end

  def show_warnings_for?(user)
    return false if user.hide_warnings
    !(view_for(user).try(:warnings_hidden))
  end

  def completed?
    status == STATUS_COMPLETE
  end

  def on_hiatus?
    marked_hiatus? || (active? && tagged_at < 1.month.ago)
  end

  def marked_hiatus?
    status == STATUS_HIATUS
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

  def valid_board
    return unless board_id.present?
    return unless new_record? || board_id_changed?
    unless board.open_to?(user)
      errors.add(:board, "is invalid – you must be able to write in it")
    end
  end

  def valid_board_section
    if section.present? && section.board_id != board_id
      errors.add(:section, "must be in the post's board")
    end
  end

  def update_tag_list
    return unless label_ids.present? || setting_ids.present? || warning_ids.present?

    updated_ids = ((label_ids || []) + (setting_ids || []) + (warning_ids || []) - ['']).map(&:to_i).reject(&:zero?).uniq.compact
    existing_ids = post_tags.map(&:tag_id)

    PostTag.where(post_id: id, tag_id: (existing_ids - updated_ids)).destroy_all
    (updated_ids - existing_ids).each do |new_id|
      PostTag.create(post_id: id, tag_id: new_id)
    end
  end

  def set_last_user
    self.last_user = user
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

  def build_initial_flat_post
    build_flat_post
    true
  end

  def reset_warnings(warning)
    PostView.where(post_id: id).update_all(warnings_hidden: false)
  end
end
