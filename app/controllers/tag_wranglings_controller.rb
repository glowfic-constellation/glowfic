# frozen_string_literal: true
class TagWranglingsController < ApplicationController
  before_action :login_required
  before_action :readonly_forbidden
  before_action :require_wrangler
  before_action :find_tag, only: :update

  def index
    @page_title = "Tag Wrangling"
    @type = params[:type].presence
    if @type && Tag::TYPES.exclude?(@type)
      flash[:error] = "Invalid filter"
      redirect_to tag_wranglings_path and return
    end

    @coverage = TagWrangling::Coverage.new(type: @type)
    @clusters = TagWrangling::DuplicateClusters.new(type: @type).clusters
    @tags = queue.paginate(page: page, per_page: 25)
  end

  def update
    level, message = case params[:commit_action]
      when 'canonical' then mark_canonical
      when 'unwrangleable' then mark_unwrangleable
      when 'merge' then merge_into_target
      else [:error, "Unrecognized wrangling action."]
    end
    flash[level] = message
    redirect_to tag_wranglings_path(type: params[:type].presence)
  end

  private

  def require_wrangler
    return if current_user.has_permission?(:wrangle_tags)
    flash[:error] = "You do not have permission to wrangle tags."
    redirect_to root_path
  end

  def find_tag
    @tag = Tag.find_by(id: params[:id])
    if @tag.nil?
      flash[:error] = "Tag could not be found."
    elsif !@tag.wrangleable_by?(current_user)
      flash[:error] = "You do not have permission to wrangle this tag."
    else
      return
    end
    redirect_to tag_wranglings_path
  end

  # Ordered by usage, so the queue is worked by value rather than front to back.
  def queue
    tags = Tag.awaiting_wrangling.select('tags.*, (SELECT COUNT(*) FROM post_tags WHERE post_tags.tag_id = tags.id) AS post_count')
    tags = tags.where(type: @type) if @type
    tags = tags.within_wrangling_scope(current_user.wrangling_scope_ids) unless current_user.has_permission?(:wrangle_tags_global)
    tags.order(Arel.sql('post_count DESC'), name: :asc)
  end

  def mark_canonical
    return [:error, "A synonym cannot be marked canonical. Remove the synonym relationship first."] if @tag.synonym?
    @tag.update!(canonical: true)
    [:success, "Tag #{@tag.name} marked canonical."]
  end

  def mark_unwrangleable
    @tag.update!(unwrangleable: true)
    [:success, "Tag #{@tag.name} marked unwrangleable."]
  end

  def merge_into_target
    target = Tag.find_by(id: params[:merger_id])
    if target.nil? || target.type != @tag.type || target.id == @tag.id
      [:error, "Merge target must be a different existing tag of the same type."]
    elsif !target.wrangleable_by?(current_user)
      [:error, "You do not have permission to wrangle this tag."]
    elsif target.synonym?
      [:error, "Merge target #{target.name} is itself a synonym. Merge into its canonical tag instead."]
    elsif params[:destroy_loser].present? && current_user.has_permission?(:delete_tags)
      target.merge_with(@tag)
      [:success, "Tag #{@tag.name} merged into #{target.name} and deleted."]
    else
      target.merge_as_synonym(@tag)
      [:success, "Tag #{@tag.name} is now a synonym of #{target.name}."]
    end
  end
end
