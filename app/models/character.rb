class Character < ApplicationRecord
  include Presentable

  belongs_to :user, optional: false
  belongs_to :template, inverse_of: :characters, optional: true
  belongs_to :default_icon, class_name: 'Icon', inverse_of: false, optional: true
  belongs_to :character_group, optional: true
  has_many :replies, dependent: false
  has_many :posts, dependent: false # These are handled in callbacks
  has_many :aliases, class_name: 'CharacterAlias', inverse_of: :character, dependent: :destroy
  has_many :reply_drafts, dependent: :nullify
  has_one :active_user, inverse_of: :active_character, class_name: 'User', foreign_key: :active_character_id, dependent: :nullify

  has_many :characters_galleries, inverse_of: :character, autosave: true, dependent: :destroy
  accepts_nested_attributes_for :characters_galleries, allow_destroy: true
  has_many :galleries, through: :characters_galleries, dependent: :destroy
  has_many :icons, -> { group('icons.id').ordered }, through: :galleries

  has_many :character_tags, inverse_of: :character, dependent: :destroy
  has_many :settings, -> { ordered_by_char_tag }, through: :character_tags, source: :setting, dependent: :destroy
  has_many :gallery_groups, -> { ordered_by_char_tag }, through: :character_tags, source: :gallery_group, dependent: :destroy

  validates :name,
    presence: true,
    length: { maximum: 255 }
  validate :valid_group, :valid_galleries, :valid_default_icon

  attr_accessor :group_name

  before_validation :strip_spaces
  after_update :update_flat_posts
  after_destroy :clear_char_ids

  scope :ordered, -> { order(name: :asc).order(Arel.sql('lower(screenname) asc'), created_at: :asc, id: :asc) }
  scope :with_name, ->(charname) { where("lower(concat_ws(' | ', name, nickname, screenname)) LIKE ?", "%#{charname.downcase}%") }

  accepts_nested_attributes_for :template, reject_if: :all_blank

  nilify_blanks

  audited on: :update, mod_only: true, update_with_comment_only: false

  def editable_by?(user)
    self.class.editable_by?(user, self.user_id)
  end

  def self.editable_by?(user, user_id)
    return false unless user
    return true if user_id == user.id
    user.has_permission?(:edit_characters)
  end

  def deletable_by?(user)
    self.class.deletable_by?(user, self.user_id)
  end

  def self.deletable_by?(user, user_id)
    return false unless user
    return true if user_id == user.id
    user.has_permission?(:delete_characters)
  end

  def recent_posts
    return @recent unless @recent.nil?
    reply_ids = replies.group(:post_id).pluck(:post_id)
    post_ids = posts.select(:id).map(&:id)
    @recent ||= Post.where(id: (post_ids + reply_ids).uniq).ordered
  end

  def selector_name(include_settings: false)
    parts = [name, nickname, screenname]
    parts << settings.pluck(:name).join(' & ') if include_settings
    parts.reject(&:blank?).join(' | ')
  end

  def reorder_galleries(_gallery=nil)
    # public so that it can be called from CharactersGallery.after_destroy
    galleries = CharactersGallery.where(character_id: id).ordered
    return unless galleries.present?

    galleries.each_with_index do |other, index|
      next if other.section_order == index
      other.section_order = index
      other.save
    end
  end

  def ungrouped_gallery_ids
    characters_galleries.reject(&:added_by_group?).map(&:gallery_id)
  end

  def ungrouped_gallery_ids=(new_ids)
    new_ids -= ['']
    new_ids = new_ids.map(&:to_i).uniq
    group_gallery_ids = gallery_groups.joins(:galleries).where(galleries: { user_id: user_id }).pluck('galleries.id')
    characters_galleries.each do |char_gal|
      gallery_id = char_gal.gallery_id
      if new_ids.include?(gallery_id)
        # make sure added_by_group is false for galleries in the new ids
        char_gal.added_by_group = false
        char_gal.unmark_for_destruction if char_gal.marked_for_destruction?
        new_ids.delete(gallery_id)
      else
        char_gal.added_by_group = true
        # destroy joins that are not in the new set of IDs and are not in gallery groups
        char_gal.mark_for_destruction unless group_gallery_ids.include?(gallery_id)
      end
    end
    # add any new galleries
    self.characters_galleries.new(new_ids.map { |id| { gallery_id: id } }) if new_ids.present?
  end

  def character_gallery_for(gallery)
    characters_galleries.find_by(gallery_id: gallery)
  end

  PB_STRUCT = Struct.new(:id, :name, :type, :pb, :user_id, :username, keyword_init: true).freeze

  def self.facecast_for(data)
    char_id, char_name, pb, user_id, username, template_id, template_name = data
    is_template = template_id.present?
    PB_STRUCT.new(
      pb: pb,
      user_id: user_id,
      username: username,
      id: is_template ? template_id : char_id,
      name: is_template ? template_name : char_name,
      type: is_template ? Template : Character,
    )
  end

  private

  def valid_group
    return unless character_group_id == 0
    @group = CharacterGroup.new(user: user, name: group_name)
    return if @group.valid?
    @group.errors.messages.each do |k, v|
      v.each { |val| errors.add("group #{k}", val) }
    end
  end

  def valid_galleries
    errors.add(:galleries, "must be yours") if galleries.present? && galleries.detect { |g| g.user_id != user.id }
  end

  def valid_default_icon
    return unless default_icon.present?
    return if default_icon.user_id == user_id
    errors.add(:default_icon, "must be yours")
  end

  def clear_char_ids
    UpdateModelJob.perform_later(Post.to_s, { character_id: id }, { character_id: nil }, audited_user_id)
    UpdateModelJob.perform_later(Reply.to_s, { character_id: id }, { character_id: nil }, audited_user_id)
  end

  def strip_spaces
    self.pb = self.pb.strip if self.pb.present?
  end

  def update_flat_posts
    return unless saved_change_to_name? || saved_change_to_screenname?
    post_ids = (Post.where(character_id: id).pluck(:id) + Reply.where(character_id: id).select(:post_id).distinct.pluck(:post_id)).uniq
    post_ids.each { |id| GenerateFlatPostJob.enqueue(id) }
  end
end
