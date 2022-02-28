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
      flash[:error] = "You do not have permission to edit this index."
      redirect_to index_path(index) and return
    end

    @page_title = "New Index Section"
    @section = IndexSection.new(index: index)
  end

  def create
    @section = IndexSection.new(permitted_params)

    if @section.index && !@section.index.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this index."
      redirect_to @section.index and return
    end

    begin
      @section.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Index section could not be created.",
        array: @section.errors.full_messages,
      }
      @page_title = 'New Index Section'
      render :new
    else
      flash[:success] = "New section, #{@section.name}, has successfully been created for #{@section.index.name}."
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
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "Index section could not be saved because of the following problems:",
        array: @section.errors.full_messages,
      }
      @page_title = "Edit Index Section: #{@section.name}"
      render :edit
    else
      flash[:success] = "Index section saved!"
      redirect_to @section.index
    end
  end

  def destroy
    begin
      @section.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {}
      flash[:error][:message] = "Index section could not be deleted."
      flash[:error][:array] = @section.errors.full_messages
    else
      flash[:success] = "Index section deleted."
    end
    redirect_to @section.index
  end

  private

  def find_model
    unless (@section = IndexSection.find_by_id(params[:id]))
      flash[:error] = "Index section could not be found."
      redirect_to indexes_path
    end
  end

  def require_permission
    unless @section.index.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this index."
      redirect_to @section.index
    end
  end

  def permitted_params
    params.fetch(:index_section, {}).permit(:name, :description, :index_id)
  end
end
