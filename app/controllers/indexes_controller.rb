# frozen_string_literal: true
class IndexesController < ApplicationController
  before_action :login_required, except: [:index, :show]
  before_action :find_index, except: [:index, :new, :create]
  before_action :permission_required, except: [:index, :new, :create, :show]

  def index
    @page_title = "Indexes"
    @indexes = Index.order('id asc').paginate(per_page: 25, page: page)
  end

  def new
    @page_title = "New Index"
    @index = Index.new(user: current_user)
  end

  def create
    @index = Index.new(index_params)
    @index.user = current_user

    if @index.save
      flash[:success] = "Index created!"
      redirect_to index_path(@index) and return
    end

    flash.now[:error] = {}
    flash.now[:error][:message] = "Index could not be created."
    flash.now[:error][:array] = @index.errors.full_messages
    @page_title = 'New Index'
    render :action => :new
  end

  def show
    unless @index.visible_to?(current_user)
      flash[:error] = "You do not have permission to view this index."
      redirect_to indexes_path and return
    end

    @page_title = @index.name.to_s
    @sectionless = @index.posts.where(index_posts: {index_section_id: nil})
    @sectionless = @sectionless.ordered_by_index
    @sectionless = posts_from_relation(@sectionless, true, false, ', index_posts.description as index_description')
    @sectionless = @sectionless.select { |p| p.visible_to?(current_user) }
  end

  def edit
    @page_title = "Edit Index: #{@index.name}"
  end

  def update
    unless @index.update_attributes(index_params)
      flash.now[:error] = {}
      flash.now[:error][:message] = "Index could not be saved because of the following problems:"
      flash.now[:error][:array] = @index.errors.full_messages
      @page_title = "Edit Index: #{@index.name}"
      render action: :edit and return
    end

    flash[:success] = "Index saved!"
    redirect_to index_path(@index)
  end

  def destroy
    @index.destroy!
    flash[:success] = "Index deleted."
    redirect_to indexes_path
  rescue ActiveRecord::RecordNotDestroyed
    flash[:error] = {}
    flash[:error][:message] = "Index could not be deleted."
    flash[:error][:array] = @index.errors.full_messages
    redirect_to index_path(@index)
  end

  private

  def find_index
    unless (@index = Index.find_by_id(params[:id]))
      flash[:error] = "Index could not be found."
      redirect_to indexes_path
    end
  end

  def permission_required
    unless @index.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this index."
      redirect_to index_path(@index)
    end
  end

  def index_params
    params.fetch(:index, {}).permit(:name, :description, :privacy, :open_to_anyone)
  end
end
