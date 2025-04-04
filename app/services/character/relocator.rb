# frozen_string_literal: true
# Steps:
# validate single user, unshared icons, galleries, and templates (if included), lack of character groups
# collect: templates (if included), characters, posts, replies, drafts, galleries, icons
# update all on unaudited (templates, aliases, drafts, galleries, icons)
# UpdateModelJob on audited (characters, posts, replies)

class Character::Relocator < Object
  def initialize(admin_id)
    @audited_user_id = admin_id
  end

  def transfer(character_ids, new_user_id, include_templates: false)
    @characters = Character.where(id: character_ids)
    raise CharacterGroupError.new('Characters must not have groups') unless @characters.ids.sort == @characters.ungrouped.ids.sort

    User.find(new_user_id) # fail with invalid target user

    @user_id = validate_user!
    @user_other_characters = Character.where(user_id: @user_id).where.not(id: @characters.ids)
    @other_character_galleries = get_galleries(@user_other_characters)
    @other_character_icon_ids = get_icon_ids(@user_other_characters, @other_character_galleries)

    @galleries = validate_galleries!
    @icons = validate_icons!
    @templates = validate_templates! if include_templates

    @posts = Post.where(character_id: character_ids, user_id: @user_id)
    @replies = Reply.where(character_id: character_ids, user_id: @user_id)
    @drafts = ReplyDraft.where(character_id: character_ids, user_id: @user_id)

    @new_authors = calc_new_authors(new_user_id)
    @rem_authors = calc_rem_authors

    update_characters(new_user_id, include_templates)
  end

  private

  def validate_user!
    user_id = @characters.select(:user_id).distinct.pluck(:user_id)
    raise RequireSingleUser.new('Characters must all have the same original user') if user_id.length > 1
    User.find(user_id.first).id
  end

  def validate_galleries!
    galleries = get_galleries(@characters)
    intersection = @other_character_galleries.ids & galleries.ids
    msg = "Galleries for characters which are being moved must not be the same as ones not being moved; gallery ids #{intersection} intersect"
    raise OverlappingGalleriesError.new(msg) unless intersection.empty?
    galleries
  end

  def validate_icons!
    icon_ids = get_icon_ids(@characters, @galleries)
    intersection = @other_character_icon_ids & icon_ids
    msg = "Icons for characters which are being moved must not be the same as ones not being moved; icon ids #{intersection} intersect"
    raise OverlappingIconsError.new(msg) unless intersection.empty?
    Icon.where(id: icon_ids)
  end

  def validate_templates!
    template_ids = @characters.select(:template_id).distinct.pluck(:template_id)
    templates = Template.where(id: template_ids)
    raise ActiveRecord::RecordInvalid if templates.where.not(user_id: @user_id).exists?
    msg = 'When moving templates all characters in them must be moved'
    raise OverlappingTemplatesError.new(msg) if @user_other_characters.where(template_id: template_ids).exists?
    templates
  end

  def calc_new_authors(new_user_id)
    post_ids = (@replies.select(:post_id).distinct.pluck(:post_id) + @posts.ids).uniq
    existing_authors = Post::Author.where(post_id: post_ids, user_id: new_user_id).pluck(:post_id)
    (post_ids - existing_authors)
  end

  def calc_rem_authors
    post_ids = (@replies.select(:post_id).distinct.pluck(:post_id) + @posts.ids).uniq
    other_uses = Reply.where(post_id: post_ids, user_id: @user_id).where.not(character_id: @characters.ids).select(:post_id).distinct.pluck(:post_id)
    (post_ids - other_uses)
  end

  def get_galleries(characters)
    gallery_ids = characters.joins(:characters_galleries).select(:gallery_id).distinct.pluck(:gallery_id)
    galleries = Gallery.where(id: gallery_ids)
    raise ActiveRecord::RecordInvalid if galleries.where.not(user_id: @user_id).exists?
    galleries
  end

  def get_icon_ids(characters, galleries)
    icon_ids = galleries.joins(:galleries_icons).select(:icon_id).distinct.pluck(:icon_id)
    icon_ids += characters.joins(:default_icon).select(:default_icon_id).distinct.pluck(:default_icon_id)
    icon_ids.uniq
    raise ActiveRecord::RecordInvalid if Icon.where(id: icon_ids).where.not(user_id: @user_id).exists?
    icon_ids
  end

  def update_characters(new_user_id, include_templates)
    Character.transaction do
      # rubocop:disable Rails/SkipsModelValidations
      @templates.update_all(user_id: new_user_id) if include_templates
      @galleries.update_all(user_id: new_user_id)
      @icons.update_all(user_id: new_user_id)
      @drafts.update_all(user_id: new_user_id)
      # rubocop:enable Rails/SkipsModelValidations

      @new_authors.each { |post_id| Post::Author.create!(post_id: post_id, user_id: new_user_id) }
      @rem_authors.each { |post_id| Post::Author.find_by!(post_id: post_id, user_id: @user_id).destroy! }

      UpdateModelJob.perform_later(Post.to_s, { character_id: @characters.ids }, { user_id: new_user_id }, @audited_user_id)
      UpdateModelJob.perform_later(Reply.to_s, { character_id: @characters.ids }, { user_id: new_user_id }, @audited_user_id)
      UpdateModelJob.perform_later(Character.to_s, { id: @characters.ids }, { user_id: new_user_id }, @audited_user_id)
    end
  end
end

class CharacterGroupError < ApiError; end
class RequireSingleUser < ApiError; end
class OverlappingGalleriesError < ApiError; end
class OverlappingIconsError < ApiError; end
class OverlappingTemplatesError < ApiError; end
