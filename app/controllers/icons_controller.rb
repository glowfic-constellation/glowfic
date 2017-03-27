# frozen_string_literal: true
class IconsController < ApplicationController
  before_filter :login_required, except: :show
  before_filter :find_icon, except: :delete_multiple
  before_filter :require_own_icon, only: [:edit, :update, :replace, :do_replace, :destroy, :avatar]

  def delete_multiple
    icon_ids = (params[:marked_ids] || []).map(&:to_i).reject(&:zero?)
    if icon_ids.empty? or (icons = Icon.where(id: icon_ids)).empty?
      flash[:error] = "No icons selected."
      redirect_to galleries_path and return
    end

    if params[:gallery_delete]
      gallery = Gallery.find_by_id(params[:gallery_id])
      unless gallery
        flash[:error] = "Gallery could not be found."
        redirect_to galleries_path and return
      end
      if gallery.user_id != current_user.id
        flash[:error] = "That is not your gallery."
        redirect_to galleries_path and return
      end

      icons.each do |icon|
        next unless icon.user_id == current_user.id
        gallery.icons.destroy(icon)
      end
      flash[:success] = "Icons removed from gallery."
      redirect_to gallery_path(gallery) and return
    end

    icons.each do |icon|
      next unless icon.user_id == current_user.id
      icon.destroy
    end
    flash[:success] = "Icons deleted."
    redirect_to gallery_path(id: params[:gallery_id] || 0)
  end

  def show
    @page_title = @icon.keyword
    if params[:view] == 'posts'
      where_calc = Post.where(icon_id: @icon.id).where(id: Reply.where(icon_id: @icon.id).pluck('distinct post_id'))
      @posts = posts_from_relation(Post.where(where_calc.where_values.reduce(:or)).order('tagged_at desc'))
    end
  end

  def edit
    @page_title = 'Edit Icon: ' + @icon.keyword
  end

  def update
    unless @icon.update_attributes(icon_params)
      flash.now[:error] = {}
      flash.now[:error][:message] = "Your icon could not be saved due to the following problems:"
      flash.now[:error][:array] = @icon.errors.full_messages
      @page_title = 'Edit icon: ' + @icon.keyword_was
      render action: :edit and return
    end

    flash[:success] = "Icon updated."
    redirect_to icon_path(@icon)
  end

  def replace
    @page_title = "Replace Icon: " + @icon.keyword
    all_icons = if @icon.has_gallery?
      @icon.galleries.map(&:icons).flatten.uniq.compact - [@icon]
    else
      current_user.galleryless_icons - [@icon]
    end
    @alts = all_icons.sort_by{|i| i.keyword.downcase }
    use_javascript('icons')
    gon.gallery = Hash[all_icons.map { |i| [i.id, {url: i.url, keyword: i.keyword}] }]
    gon.gallery[''] = {url: '/images/no-icon.png', keyword: 'No Icon'}

    all_posts = Post.where(icon_id: @icon.id) + Post.where(id: Reply.where(icon_id: @icon.id).pluck('distinct post_id'))
    @posts = all_posts.uniq
  end

  def do_replace
    unless params[:icon_dropdown].blank? || new_icon = Icon.find_by_id(params[:icon_dropdown])
      flash[:error] = "Icon could not be found."
      redirect_to replace_icon_path(@icon) and return
    end

    if new_icon && new_icon.user_id != current_user.id
      flash[:error] = "That is not your icon."
      redirect_to replace_icon_path(@icon) and return
    end

    Post.transaction do
      replies = Reply.where(icon_id: @icon.id)
      replies = replies.where(post_id: params[:post_ids]) if params[:post_ids].present?
      replies.update_all(icon_id: new_icon.try(:id))

      posts = Post.where(icon_id: @icon.id)
      posts = posts.where(id: params[:post_ids]) if params[:post_ids].present?
      posts.update_all(icon_id: new_icon.try(:id))
    end

    flash[:success] = "All uses of this icon have been replaced."
    redirect_to icon_path(@icon)
  end

  def destroy
    gallery = @icon.galleries.first if @icon.galleries.count == 1
    @icon.destroy
    flash[:success] = "Icon deleted successfully."
    redirect_to gallery_path(gallery) and return if gallery
    redirect_to galleries_path
  end

  def avatar
    if current_user.update_attributes(avatar: @icon)
      flash[:success] = "Avatar has been set!"
    else
      flash[:error] = "Something went wrong."
    end
    redirect_to icon_path(@icon)
  end

  private

  def find_icon
    unless @icon = Icon.find_by_id(params[:id])
      flash[:error] = "Icon could not be found."
      redirect_to galleries_path
    end
  end

  def require_own_icon
    if @icon.user_id != current_user.id
      flash[:error] = "That is not your icon."
      redirect_to galleries_path
    end
  end

  def icon_params
    params.fetch(:icon, {}).permit(:url, :keyword, :credit)
  end
end
