# frozen_string_literal: true
class SkinsController < ApplicationController
  before_action :login_required, except: [:show, :gallery, :css]
  before_action :find_model, only: [:show, :edit, :update, :destroy, :use, :fork, :approve, :reject]
  before_action :require_visible, only: [:show, :use, :fork]
  before_action :require_edit_permission, only: [:edit, :update, :destroy]
  before_action :require_approval_permission, only: [:review, :approve, :reject]

  def index
    @page_title = 'Your Skins'
    @skins = current_user.skins.ordered.paginate(page: page, per_page: 25)
  end

  def gallery
    @page_title = 'Skin Gallery'
    @skins = Skin.listed.ordered.includes(:user).paginate(page: page, per_page: 25)
  end

  def new
    @page_title = 'New Skin'
    @skin = Skin.new
  end

  def create
    @skin = Skin.new(permitted_params)
    @skin.user = current_user

    unless @skin.save
      render_errors(@skin, action: 'created', now: true)
      @page_title = 'New Skin'
      render :new and return
    end

    flash[:success] = 'Skin created.'
    redirect_to @skin
  end

  def show
    @page_title = @skin.name
  end

  # Serves a skin as a standalone stylesheet (referenced via <link> in the
  # layout) rather than inlining it into every page's <style>. Keeps the skin
  # CSS out of the HTML (no markup-escaping needed) and lets the browser cache
  # it across page loads. Tier and content vary per viewer, so cache privately.
  def css
    skin = Skin.find_by(id: params[:id])
    return head(:not_found) unless skin&.viewable_as_stylesheet_by?(current_user)

    response.headers['X-Content-Type-Options'] = 'nosniff'
    return unless stale?(etag: [skin, skin.trusted_for?(current_user)], public: false)

    render plain: skin.stylesheet_for(current_user), content_type: 'text/css'
  end

  def edit
    @page_title = "Edit Skin: #{@skin.name}"
  end

  def update
    unless @skin.update(permitted_params)
      render_errors(@skin, action: 'updated', now: true)
      @page_title = "Edit Skin: #{@skin.name}"
      render :edit and return
    end

    flash[:success] = 'Skin updated.'
    redirect_to @skin
  end

  def destroy
    begin
      @skin.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@skin, action: 'delete', err: e)
    else
      flash[:success] = 'Skin deleted.'
    end
    redirect_to skins_path
  end

  def use
    current_user.update!(skin_id: @skin.id)
    flash[:success] = "Now using the “#{@skin.name}” skin."
    redirect_back_or_to(@skin)
  end

  def clear
    current_user.update!(skin_id: nil)
    flash[:success] = 'Skin turned off.'
    redirect_back_or_to(skins_path)
  end

  def fork
    new_skin = @skin.fork_for(current_user)
    if new_skin.save
      flash[:success] = 'Skin copied to your skins.'
      redirect_to edit_skin_path(new_skin)
    else
      flash[:error] = 'Skin could not be copied.'
      redirect_to @skin
    end
  end

  def review
    @page_title = 'Skins Awaiting Review'
    @skins = Skin.pending_review.ordered.includes(:user).paginate(page: page, per_page: 25)
  end

  def approve
    @skin.approve!(current_user)
    flash[:success] = "Approved the “#{@skin.name}” skin."
    redirect_to @skin
  end

  def reject
    @skin.reject!
    flash[:success] = "Rejected the “#{@skin.name}” skin; it has been unlisted."
    redirect_to @skin
  end

  private

  def permitted_params
    params.fetch(:skin, {}).permit(:name, :description, :css, :public)
  end

  def find_model
    return if (@skin = Skin.find_by(id: params[:id]))
    flash[:error] = 'Skin could not be found.'
    redirect_to skins_path
  end

  def require_visible
    return if @skin.visible_to?(current_user)
    flash[:error] = 'Skin could not be found.'
    redirect_to skins_path
  end

  def require_edit_permission
    return if @skin.editable_by?(current_user)
    flash[:error] = 'You do not have permission to edit that skin.'
    redirect_to skin_path(@skin)
  end

  def require_approval_permission
    return if current_user&.has_permission?(:approve_skins)
    flash[:error] = 'You do not have permission to review skins.'
    redirect_to skins_path
  end
end
