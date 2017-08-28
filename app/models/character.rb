class Character < ActiveRecord::Base
  include Presentable
  include Taggable

  belongs_to :user
  belongs_to :template
  belongs_to :default_icon, class_name: Icon
  belongs_to :character_group
  has_many :replies
  has_many :posts
  has_many :aliases, class_name: CharacterAlias

  has_many :characters_galleries, inverse_of: :character
  accepts_nested_attributes_for :characters_galleries, allow_destroy: true
  has_many :galleries, through: :characters_galleries, after_remove: :reorder_galleries
  has_many :icons, -> { group('icons.id').order('LOWER(keyword)') }, through: :galleries

  has_many :character_tags, inverse_of: :character, dependent: :destroy
  has_many :labels, through: :character_tags, source: :label
  has_many :settings, through: :character_tags, source: :setting
  has_many :gallery_groups, through: :character_tags, source: :gallery_group, after_remove: :remove_galleries_from_character

  validates_presence_of :name, :user
  validate :valid_template, :valid_group, :valid_galleries, :valid_default_icon

  attr_accessor :new_template_name, :group_name

  after_destroy :clear_char_ids

  acts_as_tag :label, :setting, :gallery_group

  nilify_blanks

  def recent_posts
    return @recent unless @recent.nil?
    reply_ids = replies.group(:post_id).pluck(:post_id)
    post_ids = posts.select(:id).map(&:id)
    @recent ||= Post.where(id: (post_ids + reply_ids).uniq).order('tagged_at desc')
  end

  def selector_name
    [name, template_name, screenname].compact.join(' | ')
  end

  def reorder_galleries(_gallery=nil)
    # public so that it can be called from CharactersGallery.after_destroy
    galleries = CharactersGallery.where(character_id: id).order('section_order asc')
    return unless galleries.present?

    galleries.each_with_index do |other, index|
      next if other.section_order == index
      other.section_order = index
      other.save
    end
  end

  def ungrouped_gallery_ids
    characters_galleries.where(added_by_group: false).pluck(:gallery_id)
  end

  def ungrouped_gallery_ids=(new_ids)
    new_ids -= ['']
    new_ids = new_ids.map(&:to_i)
    old_ids = ungrouped_gallery_ids
    rem_ids = old_ids - new_ids
    group_gallery_ids = gallery_groups.joins(:gallery_tags).reorder('gallery_tags.gallery_id').pluck('distinct gallery_tags.gallery_id')
    new_chargals = []
    characters_galleries.each do |char_gal|
      gallery_id = char_gal.gallery_id
      if new_ids.include?(gallery_id)
        # add relevant old galleries, making sure added_by_group is false
        char_gal.added_by_group = false
        new_chargals << char_gal.attributes
        new_ids.delete(gallery_id)
      elsif group_gallery_ids.include?(gallery_id)
        # add relevant old group galleries, added_by_group being true
        char_gal.added_by_group = true
        new_chargals << char_gal.attributes
        group_gallery_ids.delete(gallery_id)
      else
        # destroy joins that are not in the new set of IDs
        new_chargals << char_gal.attributes.merge(_destroy: true)
      end
    end
    new_ids.each do |gallery_id|
      # add any leftover new galleries
      new_chargals << {gallery_id: gallery_id, character_id: id, added_by_group: false}
    end
    # leftover galleries from gallery groups will be added by that model
    self.characters_galleries_attributes = new_chargals
  end

  def remove_galleries_from_character(gallery_group)
    galleries = gallery_group.galleries.where(user_id: user_id)
    CharactersGallery.where(character: self, gallery: galleries, added_by_group: true).destroy_all
  end

  private

  def valid_template
    unless template_id == 0
      errors.add(:template, "must be yours") if template.present? && template.user_id != user.id
      return
    end
    @template = Template.new(user: user, name: new_template_name)
    return if @template.valid?
    @template.errors.messages.each do |k, v|
      v.each { |val| errors.add('template '+k.to_s, val) }
    end
  end

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
    if default_icon.present? && default_icon.user_id != user_id
      errors.add(:default_icon, "must be yours")
    end
  end

  def clear_char_ids
    Reply.where(character_id: id).update_all(character_id: nil)
    Post.where(character_id: id).update_all(character_id: nil)
  end
end
