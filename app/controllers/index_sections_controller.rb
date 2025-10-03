# frozen_string_literal: true
class IndexSectionsController < ApplicationController
  before_action :login_required, except: [:show]
  before_action :readonly_forbidden, except: [:show]
  before_action :find_model, except: [:new, :create]
  before_action :require_permission, except: [:new, :create, :show]

  def new
    unless (index = Index.find_by_id(params[:index_id]))
      flash[:error] = "Index could not be found."
      redirect_to indexes_path and return
    end

    unless index.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this index."
      redirect_to index_path(index) and return
    end

    @page_title = "New Index Section"
    @section = IndexSection.new(index: index)
  end

  def create
    @section = IndexSection.new(permitted_params)

    if @section.index && !@section.index.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this index." # rubocop:disable Rails/ActionControllerFlashBeforeRender
      redirect_to @section.index and return
    end

    begin
      @section.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@section, action: 'created', now: true, err: e)

      @page_title = 'New Index Section'
      render :new
    else
      flash[:success] = "New section, #{@section.name}, created for #{@section.index.name}."
      redirect_to @section.index
    end
  end

  def show
    @page_title = @section.name
  end

  def edit
    @page_title = "Edit Index Section: #{@section.name}"
  end

  def update
    begin
      @section.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@section, action: 'updated', now: true, err: e)
      @page_title = "Edit Index Section: #{@section.name}"
      render :edit
    else
      flash[:success] = "Index section updated."
      redirect_to @section.index
    end
  end

  def destroy
    begin
      @section.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@section, action: 'deleted', err: e)
    else
      flash[:success] = "Index section deleted."
    end
    redirect_to @section.index
  end

  private

  def find_model
    return if (@section = IndexSection.find_by_id(params[:id]))
    flash[:error] = "Index section could not be found."
    redirect_to indexes_path
  end

  def require_permission
    return if @section.index.editable_by?(current_user)
    flash[:error] = "You do not have permission to modify this index."
    redirect_to @section.index
  end

  def permitted_params
    params.fetch(:index_section, {}).permit(:name, :description, :index_id)
  end
end
