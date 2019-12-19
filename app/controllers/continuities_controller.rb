# frozen_string_literal: true
class ContinuitiesController < ApplicationController
  before_action :login_required, except: [:index, :show, :search]
  before_action :find_continuity, only: [:show, :edit, :update, :destroy]
  before_action :set_available_cowriters, only: [:new, :edit]
  before_action :require_permission, only: [:edit, :update, :destroy]

  def index
    if params[:user_id].present?
      unless (@user = User.active.find_by_id(params[:user_id]))
        flash[:error] = "User could not be found."
        redirect_to root_path and return
      end

      @page_title = if @user.id == current_user.try(:id)
        "Your Continuities"
      else
        @user.username + "'s Continuities"
      end

      continuity_ids = ContinuityAuthor.where(user_id: @user.id, cameo: false).select(:continuity_id).distinct.pluck(:continuity_id)
      @continuities = Continuity.where(creator_id: @user.id).or(Continuity.where(id: continuity_ids)).ordered
      @cameo_continuities = Continuity.where(id: ContinuityAuthor.where(user_id: @user.id, cameo: true).select(:continuity_id).distinct.pluck(:continuity_id)).ordered
    else
      @page_title = 'Continuities'
      @continuities = Continuity.ordered.paginate(page: page, per_page: 25)
    end
  end

  def new
    @continuity = Continuity.new
    @continuity.creator = current_user
    @page_title = 'New Continuity'
  end

  def create
    @continuity = Continuity.new(continuity_params)
    @continuity.creator = current_user

    begin
      @continuity.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Continuity could not be created.",
        array: @continuity.errors.full_messages
      }
      @page_title = 'New Continuity'
      set_available_cowriters
      render :new
    else
      flash[:success] = "Continuity created!"
      redirect_to continuities_path
    end
  end

  def show
    @page_title = @continuity.name
    @subcontinuities = @continuity.subcontinuities.ordered
    continuity_posts = @continuity.posts.where(section_id: nil)
    if @continuity.ordered?
      continuity_posts = continuity_posts.ordered_in_section
    else
      continuity_posts = continuity_posts.ordered
    end
    @posts = posts_from_relation(continuity_posts, no_tests: false)
    @meta_og = og_data
    use_javascript('continuities/show')
  end

  def edit
    @page_title = 'Edit Continuity: ' + @continuity.name
    use_javascript('continuities/edit')
    @subcontinuities = @continuity.subcontinuities.ordered
    @unsectioned_posts = @continuity.posts.where(section_id: nil).ordered_in_section if @continuity.ordered?
  end

  def update
    begin
      @continuity.update!(continuity_params)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Continuity could not be created.",
        array: @continuity.errors.full_messages
      }
      @page_title = 'Edit Continuity: ' + @continuity.name_was
      set_available_cowriters
      use_javascript('subcontinuities')
      @subcontinuities = @continuity.subcontinuities.ordered
      render :edit
    else
      flash[:success] = "Continuity saved!"
      redirect_to continuity_path(@continuity)
    end
  end

  def destroy
    begin
      @continuity.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "Continuity could not be deleted.",
        array: @continuity.errors.full_messages
      }
      redirect_to continuity_path(@continuity)
    else
      flash[:success] = "Continuity deleted."
      redirect_to continuities_path
    end
  end

  def mark
    unless (continuity = Continuity.find_by_id(params[:continuity_id]))
      flash[:error] = "Continuity could not be found."
      redirect_to unread_posts_path and return
    end

    if params[:commit] == "Mark Read"
      Continuity.transaction do
        continuity.mark_read(current_user)
        read_time = continuity.last_read(current_user)
        post_views = PostView.joins(post: :continuity).where(user: current_user, continuities: {id: continuity.id})
        post_views.update_all(read_at: read_time, updated_at: read_time) # rubocop:disable Rails/SkipsModelValidations
      end
      flash[:success] = "#{continuity.name} marked as read."
    elsif params[:commit] == "Hide from Unread"
      continuity.ignore(current_user)
      flash[:success] = "#{continuity.name} hidden from this page."
    else
      flash[:error] = "Please choose a valid action."
    end
    redirect_to unread_posts_path
  end

  def search
    @page_title = 'Search Continuities'
    @users = User.active.where(id: params[:author_id]).ordered if params[:author_id].present?
    return unless params[:commit].present?

    searcher = Continuity::Searcher.new
    @search_results = searcher.search(params, page: page)
  end

  private

  def set_available_cowriters
    @coauthors = @cameos = User.active.ordered
    if @continuity
      @coauthors -= @continuity.cameos
      @cameos -= @continuity.writers
      @coauthors -= [@continuity.creator]
      @cameos -= [@continuity.creator]
    else
      @coauthors -= [current_user]
      @cameos -= [current_user]
    end
    use_javascript('continuities/editor')
  end

  def find_continuity
    unless (@continuity = Continuity.find_by_id(params[:id]))
      flash[:error] = "Continuity could not be found."
      redirect_to continuities_path and return
    end
  end

  def require_permission
    unless @continuity.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit that continuity."
      redirect_to continuity_path(@continuity) and return
    end
  end

  def og_data
    metadata = []
    metadata << @continuity.writers.where.not(deleted: true).ordered.pluck(:username).join(', ') if @continuity.authors_locked?
    post_count = @continuity.posts.where(privacy: Concealable::PUBLIC).count
    stats = "#{post_count} " + "post".pluralize(post_count)
    section_count = @continuity.subcontinuities.count
    stats += " in #{section_count} " + "section".pluralize(section_count) if section_count > 0
    metadata << stats
    desc = [metadata.join(' – ')]
    desc << generate_short(@continuity.description) if @continuity.description.present?
    {
      url: continuity_url(@continuity),
      title: @continuity.name,
      description: desc.join("\n"),
    }
  end

  def continuity_params
    params.fetch(:continuity, {}).permit(:name, :description, coauthor_ids: [], cameo_ids: [])
  end
end
