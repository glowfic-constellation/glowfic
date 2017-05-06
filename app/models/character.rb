class Character < ActiveRecord::Base
  include Presentable

  belongs_to :user
  belongs_to :template
  belongs_to :default_icon, class_name: Icon
  belongs_to :character_group
  has_many :replies
  has_many :posts
  has_many :aliases, class_name: CharacterAlias

  has_many :characters_galleries
  has_many :galleries, through: :characters_galleries, after_remove: :reorder_galleries
  has_many :icons, through: :galleries, group: 'icons.id', order: 'LOWER(keyword)'

  has_many :character_tags, inverse_of: :character, dependent: :destroy
  has_many :tags, through: :character_tags, source: :all_tags, source_type: 'Tag' # TODO THIS IS BROKEN does not filter subtypes like setting

  has_many :settings, through: :character_tags, source: :all_tags, source_type: 'Setting'

  validates_presence_of :name, :user
  validate :valid_template, :valid_group, :valid_galleries, :valid_default_icon

  attr_accessor :new_template_name, :group_name

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

  def reorder_galleries(gallery=nil)
    # public so that it can be called from CharactersGallery.after_destroy
    galleries = CharactersGallery.where(character_id: id).order('section_order asc')
    return unless galleries.present?

    galleries.each_with_index do |other, index|
      next if other.section_order == index
      other.section_order = index
      other.save
    end
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
end
