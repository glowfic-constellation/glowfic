class Character < ActiveRecord::Base
  belongs_to :user
  belongs_to :template
  belongs_to :default_icon, class_name: Icon
  belongs_to :character_group
  has_many :replies
  has_many :posts
  has_and_belongs_to_many :galleries
  has_many :character_tags, inverse_of: :character, dependent: :destroy
  has_many :tags, through: :character_tags

  validates_presence_of :name, :user
  validate :valid_template, :valid_group, :valid_galleries, :valid_default_icon

  after_save :update_galleries
  after_update :delete_view_cache
  after_destroy :delete_view_cache

  attr_accessor :new_template_name, :group_name, :gallery_ids

  nilify_blanks

  def icon
    @icon ||= default_icon || galleries.detect(&:default_icon).try(:default_icon)
  end

  def icons
    @icons ||= galleries.map(&:icons).flatten.uniq_by(&:id)
  end

  def recent_posts(limit=25, page=1)
    return @recent unless @recent.nil?
    reply_ids = replies.group(:post_id).select(:post_id).map(&:post_id)
    post_ids = posts.select(:id).map(&:id)
    @recent ||= Post.where(id: (post_ids + reply_ids).uniq).order('tagged_at desc').paginate(per_page: limit, page: page)
  end

  def selector_name
    [name, template_name, screenname].compact.join(' | ')
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
    if default_icon.present? && default_icon.user_id != user.id
      errors.add(:default_icon, "must be yours")
    end
  end

  def update_galleries
    return unless gallery_ids

    updated_ids = (gallery_ids - [""]).map(&:to_i)
    existing_ids = galleries.map(&:id)

    CharactersGallery.where(character_id: id, gallery_id: (existing_ids - updated_ids)).destroy_all
    (updated_ids - existing_ids).each do |new_id|
      CharactersGallery.create(character_id: id, gallery_id: new_id)
    end
  end

  def delete_view_cache
    return unless name_changed? || screenname_changed?
    replies.each do |reply|
      reply.send(:delete_view_cache)
    end
  end
end
