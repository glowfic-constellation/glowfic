class Character < ActiveRecord::Base
  belongs_to :user
  belongs_to :template
  belongs_to :gallery
  belongs_to :default_icon, class_name: Icon
  has_many :replies
  belongs_to :character_group

  validates_presence_of :name, :user
  validate :valid_template, :valid_group

  attr_accessor :new_template_name, :group_name

  nilify_blanks

  def icon
    default_icon || gallery.try(:default_icon)
  end

  def multi_icons?
    gallery.present? && gallery.icons.count > 1
  end

  def recent_posts(limit=25)
    @recent ||= Post.where(id: replies.group(:post_id).select(:post_id)).order('updated_at desc').limit(limit)
  end

  def selector_name
    [name, template_name, screenname].compact.join(' | ')
  end

  private

  def valid_template
    return unless template_id.zero?
    @template = Template.new(user: user, name: new_template_name)
    return if @template.valid?
    @template.errors.messages.each do |k, v|
      v.each { |val| errors.add('template '+k.to_s, val) }
    end
  end

  def valid_group
    return unless character_group_id.zero?
    @group = CharacterGroup.new(user: user, name: group_name)
    return if @group.valid?
    @group.errors.messages.each do |k, v|
      v.each { |val| errors.add('group '+k.to_s, val) }
    end
  end
end
