class Character < ActiveRecord::Base
  belongs_to :user
  belongs_to :template
  belongs_to :gallery
  belongs_to :default_icon, class_name: Icon
  has_many :replies

  validates_presence_of :name, :user

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
end
