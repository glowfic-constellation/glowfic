# frozen_string_literal: true
class TagWranglingsController < ApplicationController
  before_action :login_required
  before_action :readonly_forbidden
  before_action :require_wrangler

  def index
    @page_title = "Tag Wrangling"
    @type = params[:type].presence
    if @type && Tag::TYPES.exclude?(@type)
      flash[:error] = "Invalid filter"
      redirect_to tag_wranglings_path and return
    end

    @coverage = TagWrangling::Coverage.new(type: @type)
    @clusters = TagWrangling::DuplicateClusters.new(type: @type).clusters
    @tags = queue_scope.paginate(page: page, per_page: 25)
  end

  def update
    @tag = Tag.find_by(id: params[:id])
    return tag_not_found unless @tag
    return not_permitted unless @tag.wrangleable_by?(current_user)

    case params[:commit_action]
      when 'canonical' then mark_canonical
      when 'unwrangleable' then mark_unwrangleable
      when 'merge' then merge_into_target
      else
        flash[:error] = "Unrecognized wrangling action."
        redirect_to tag_wranglings_path
    end
  end

  private

  def require_wrangler
    return if current_user.has_permission?(:wrangle_tags)
    return if current_user.has_permission?(:wrangle_tags_global)
    flash[:error] = "You do not have permission to wrangle tags."
    redirect_to root_path
  end

  def queue_scope
    scope = Tag.awaiting_wrangling.select('tags.*, (SELECT COUNT(*) FROM post_tags WHERE post_tags.tag_id = tags.id) AS post_count')
    scope = scope.where(type: @type) if @type
    scope = scope.where(id: wrangleable_ids) unless current_user.has_permission?(:wrangle_tags_global)
    scope.order(Arel.sql('post_count DESC'), name: :asc)
  end

  def wrangleable_ids
    setting_ids = WranglingAssignment.scope_ids_for(current_user)
    return [] if setting_ids.empty?
    co_tagged = PostTag.where(post_id: PostTag.where(tag_id: setting_ids).select(:post_id)).select(:tag_id)
    Tag.where(id: co_tagged).or(Tag.where(id: setting_ids)).select(:id)
  end

  def mark_canonical
    if @tag.synonym?
      flash[:error] = "A synonym cannot be marked canonical. Remove the synonym relationship first."
    else
      @tag.update!(canonical: true)
      flash[:success] = "Tag #{@tag.name} marked canonical."
    end
    redirect_to tag_wranglings_path(type: params[:type])
  end

  def mark_unwrangleable
    @tag.update!(unwrangleable: true)
    flash[:success] = "Tag #{@tag.name} marked unwrangleable."
    redirect_to tag_wranglings_path(type: params[:type])
  end

  def merge_into_target
    target = Tag.find_by(id: params[:merger_id])
    return invalid_merge_target if target.nil? || target.type != @tag.type || target.id == @tag.id
    return not_permitted unless target.wrangleable_by?(current_user)

    if target.synonym?
      flash[:error] = "Merge target #{target.name} is itself a synonym. Merge into its canonical tag instead."
      redirect_to tag_wranglings_path(type: params[:type]) and return
    end

    if params[:destroy_loser].present? && current_user.has_permission?(:delete_tags)
      target.merge_with(@tag)
      flash[:success] = "Tag #{@tag.name} merged into #{target.name} and deleted."
    else
      target.merge_as_synonym(@tag)
      flash[:success] = "Tag #{@tag.name} is now a synonym of #{target.name}."
    end
    redirect_to tag_wranglings_path(type: params[:type])
  end

  def invalid_merge_target
    flash[:error] = "Merge target must be a different existing tag of the same type."
    redirect_to tag_wranglings_path(type: params[:type])
  end

  def tag_not_found
    flash[:error] = "Tag could not be found."
    redirect_to tag_wranglings_path
  end

  def not_permitted
    flash[:error] = "You do not have permission to wrangle this tag."
    redirect_to tag_wranglings_path
  end
end
