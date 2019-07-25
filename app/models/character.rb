class Character < ApplicationRecord
  include Presentable

  belongs_to :user, optional: false
  belongs_to :template, inverse_of: :characters, optional: true
  belongs_to :default_icon, class_name: 'Icon', inverse_of: false, optional: true
  belongs_to :character_group, optional: true
  has_many :replies, dependent: false
  has_many :posts, dependent: false # These are handled in callbacks
  has_many :aliases, class_name: 'CharacterAlias', inverse_of: :character, dependent: :destroy

  has_many :characters_galleries, inverse_of: :character, dependent: :destroy
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
  after_destroy :clear_char_ids

  scope :ordered, -> { order(name: :asc).order(Arel.sql('lower(screenname) asc'), created_at: :asc, id: :asc) }
  scope :with_name, -> (charname) { where("lower(concat_ws(' | ', name, template_name, screenname)) LIKE ?", "%#{charname.downcase}%") }

  accepts_nested_attributes_for :template, reject_if: :all_blank

  nilify_blanks

  audited on: :update, mod_only: true

  def editable_by?(user)
    return false unless user
    return true if user_id == user.id
    user.has_permission?(:edit_characters)
  end

  def deletable_by?(user)
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

  def selector_name
    [name, template_name, screenname].compact.join(' | ')
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

  def character_gallery_for(gallery)
    characters_galleries.find_by(gallery_id: gallery)
  end

  private

  def valid_group
    return unless character_group_id == 0
    @group = CharacterGroup.new(user: user, name: group_name)
    return if @group.valid?
    @group.errors.messages.each do |k, v|
      v.each { |val| errors.add('group '+k.to_s, val) }
    end
  end

  def valid_galleries
    if galleries.present? && galleries.detect{|g| g.user_id != user.id}
      errors.add(:galleries, "must be yours")
    end
  end

  def valid_default_icon
    return unless default_icon.present?
    return if default_icon.user_id == user_id
    errors.add(:default_icon, "must be yours")
  end

  def clear_char_ids
    UpdateModelJob.perform_later(Post.to_s, {character_id: id}, {character_id: nil})
    UpdateModelJob.perform_later(Reply.to_s, {character_id: id}, {character_id: nil})
    ReplyDraft.where(character_id: id).update_all(character_id: nil)
    User.where(active_character_id: id).update_all(active_character_id: nil)
  end

  def strip_spaces
    self.pb = self.pb.strip if self.pb.present?
  end
end
