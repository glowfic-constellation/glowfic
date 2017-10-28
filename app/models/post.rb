class Post < ApplicationRecord
  include Concealable
  include Orderable
  include PgSearch
  include Presentable
  include Taggable
  include Viewable
  include Writable

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
  has_many :post_viewers, inverse_of: :post, dependent: :destroy
  has_many :viewers, through: :post_viewers, source: :user
  has_many :reply_drafts, dependent: :destroy
  has_many :post_tags, inverse_of: :post, dependent: :destroy
  has_many :labels, through: :post_tags, source: :label
  has_many :settings, through: :post_tags, source: :setting
  has_many :content_warnings, through: :post_tags, source: :content_warning, after_add: :reset_warnings
  has_many :favorites, as: :favorite, dependent: :destroy
  has_many :index_posts, inverse_of: :post, dependent: :destroy
  has_many :indexes, inverse_of: :posts, through: :index_posts
  has_many :index_sections, inverse_of: :posts, through: :index_posts

  attr_accessor :is_import
  attr_writer :skip_edited

  validates_presence_of :board, :subject
  validate :valid_board, :valid_board_section

  before_create :build_initial_flat_post
  before_create :set_last_user
  after_commit :notify_followers, on: :create

  acts_as_tag :label, :content_warning, :setting

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
  scope :no_tests, -> { where('posts.board_id != ?', Board::ID_SITETESTING) }

  scope :with_has_content_warnings, -> {
    select("(SELECT tags.id IS NOT NULL FROM tags LEFT JOIN post_tags ON tags.id = post_tags.tag_id WHERE tags.type = 'ContentWarning' AND post_tags.post_id = posts.id LIMIT 1) AS has_content_warnings")
  }

  scope :with_author_ids, -> {
    # fetches replies.map(&:user_id).uniq
    # then appends post.user_id
    # then unions distinctly, and re-converts to an array
    select('ARRAY(SELECT posts.user_id UNION SELECT replies.user_id FROM replies WHERE replies.post_id = posts.id GROUP BY replies.user_id) AS author_ids')
  }

  scope :with_reply_count, -> {
    select('(SELECT COUNT(*) FROM replies WHERE replies.post_id = posts.id) AS reply_count')
  }

  def visible_to?(user)
    return true if public?
    return false unless user
    return true if registered_users?
    return true if user.admin?
    return user.id == user_id if private?
    (post_viewers.pluck(:user_id) + [user_id]).include?(user.id)
  end

  def authors
    return @authors if @authors
    return @authors = [user] if author_ids.count == 1
    @authors = User.where(id: author_ids).to_a
  end

  def author_ids
    return read_attribute(:author_ids) if has_attribute?(:author_ids)
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

    reply
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
    @last_seen = reply
  end

  def recent_characters_for(user, count)
    # fetch the (count) most recent non-nil character_ids for user in post
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
    !view_for(user).try(:warnings_hidden)
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

  def word_count_for(user)
    sum = 0
    sum = word_count if user_id == user.id
    return sum unless replies.where(user_id: user.id).exists?

    contents = replies.where(user_id: user.id).pluck(:content)
    contents[0] = contents[0].split.size
    sum + contents.inject{|r, e| r + e.split.size}.to_i
  end

  def author_word_counts
    authors.map { |author| [author.username, word_count_for(author)] }.sort_by{|a| -a[1] }
  end

  def character_appearance_counts
    reply_counts = replies.joins(:character).group(:character_id).count
    reply_counts[character_id] = reply_counts[character_id].to_i + 1
    Character.where(id: reply_counts.keys).map { |c| [c, reply_counts[c.id]]}.sort_by{|a| -a[1] }
  end

  def has_content_warnings?
    return read_attribute(:has_content_warnings) if has_attribute?(:has_content_warnings)
    content_warnings.exists?
  end

  def reply_count
    return read_attribute(:reply_count) if has_attribute?(:reply_count)
    replies.count
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

  def set_last_user
    self.last_user = user
  end

  def timestamp_attributes_for_update
    # Makes Rails treat edited_at as a timestamp identical to updated_at
    # if specific attributes are updated. Also uses tagged_at if there
    # are no replies yet or if the status has changed.
    # Be VERY CAREFUL editing this!
    return super if skip_edited
    return super + [:edited_at] if replies.exists? && !status_changed?
    super + [:edited_at, :tagged_at]
  end

  def skip_edited
    @skip_edited || EDITED_ATTRS.none? { |edit| send(edit + "_changed?") }
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

  def reset_warnings(_warning)
    PostView.where(post_id: id).update_all(warnings_hidden: false)
  end

  def notify_followers
    return if is_import
    NotifyFollowersOfNewPostJob.perform_later(self.id)
  end
end
