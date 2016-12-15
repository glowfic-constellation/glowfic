# frozen_string_literal: true
class TemplatesController < ApplicationController
  before_filter :login_required, except: :show
  before_filter :find_template, :only => [:show, :destroy, :edit, :update]
  before_filter :require_own_template, :only => [:edit, :update, :destroy]

  def new
    @template = Template.new
    @page_title = "New Template"
  end

  def create
    @template = Template.new(params[:template])
    @template.user = current_user
    if @template.save
      flash[:success] = "Template saved successfully."
      redirect_to template_path(@template)
    else
      flash.now[:error] = "Your template could not be saved."
      @page_title = "New Template"
      render :action => :new
    end
  end

  def show
    @user = @template.user
    @characters = @template.characters
    character_ids = @characters.map(&:id)
    post_ids = Reply.where(character_id: character_ids).pluck('distinct post_id')
    where = Post.where(character_id: character_ids).where(id: post_ids).where_values.reduce(:or)
    @posts = Post.where(where).order('tagged_at desc').paginate(per_page: 25, page: page)
    @page_title = @template.name
  end

  def edit
    @page_title = 'Edit Template: ' + @template.name
  end

  def update
    if @template.update_attributes(params[:template])
      flash[:success] = "Template saved successfully."
      redirect_to template_path(@template)
    else
      flash.now[:error] = "Your template could not be saved."
      @page_title = 'Edit Template: ' + @template.name_was
      render :action => :edit
    end
  end

  def destroy
    @template.destroy
    flash[:success] = "Template deleted successfully."
    redirect_to characters_path
  end

  private

  def find_template
    unless @template = Template.find_by_id(params[:id])
      flash[:error] = "Template could not be found."
      redirect_to characters_path and return
    end
  end

  def require_own_template
    return true if @template.user_id == current_user.id
    flash[:error] = "That is not your template."
    redirect_to characters_path
  end
end
