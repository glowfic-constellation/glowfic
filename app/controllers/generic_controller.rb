# class must declare permitted_params to use
# frozen_string_literal: true
class GenericController < ApplicationController
  before_action :login_required, only: [:new, :create, :edit, :update, :destroy]
  before_action :find_model, only: [:show, :edit, :update, :destroy]
  before_action :editor_setup, only: [:new, :edit]
  before_action :require_view_permission, only: [:show, :edit, :update, :destroy]
  before_action :require_edit_permission, only: [:edit, :update]
  before_action :require_delete_permission, only: :destroy

  def index
    @page_title = controller_name.titlecase
  end

  def new
    @page_title = "New #{model_name}"
    @model = model_class.new
    set_params
    set_model
  end

  def create
    @model = model_class.new(permitted_params)
    set_params

    begin
      @model.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@model, action: 'created', now: true, class_name: model_name.capitalize)
      log_error(e) unless @model.errors.present?
      @page_title = "New #{model_name}"
      set_model
      editor_setup
      render :new
    else
      flash[:success] = "#{model_name} created."
      redirect_to create_redirect
    end
  end

  def show
    @page_title = @model.name.to_s
  end

  def edit
    @page_title = "Edit #{model_name}: #{@model.name}"
  end

  def update
    begin
      @model.update!(permitted_params)
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@model, action: 'updated', now: true, class_name: model_name.capitalize)
      log_error(e) unless @model.errors.present?
      @page_title = "Edit #{model_name}: #{@model.name}"
      render :edit
    else
      flash[:success] = "#{model_name} updated."
      redirect_to update_redirect
    end
  end

  def destroy
    begin
      @model.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@model, action: 'deleted', class_name: model_name.capitalize)
      log_error(e) unless @model.errors.present?
      redirect_to model_path(@model)
    else
      flash[:success] = "#{model_name} deleted."
      redirect_to destroy_redirect
    end
  end

  protected

  def find_model
    unless (@model = model_class.find_by_id(params[:id]))
      flash[:error] = "#{model_name} could not be found."
      redirect_to invalid_redirect and return
    end
    set_model
  end

  def require_view_permission
    return unless model_class.method_defined? :visible_to?
    unless @model.visible_to?(current_user)
      flash[:error] = "You do not have permission to view this #{model_name.downcase}."
      redirect_to models_path
    end
  end

  def require_edit_permission
    return unless model_class.method_defined? :editable_by?
    unless @model.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this #{model_name.downcase}."
      redirect_to model_path(@model) # TODO not if they don't have view permission either
    end
  end

  def require_delete_permission
    unless model_class.method_defined? :deletable_by?
      require_edit_permission
      return
    end

    unless @model.deletable_by?(current_user)
      flash[:error] = "You do not have permission to modify this #{model_name.downcase}."
      redirect_to model_path(@model) # TODO not if they don't have view permission either
    end
  end

  def model_name
    @mn ||= controller_name.classify
  end

  def model_class
    @mc ||= model_name.constantize
  end

  def model_path(model)
    send("#{controller_name.singularize}_path", model)
  end

  def models_path
    @msp ||= send("#{controller_name}_path")
  end

  def set_model
    instance_variable_set("@#{controller_name.singularize}", @model)
  end

  def editor_setup
    # pass
  end

  def set_params
    # pass
  end

  def create_redirect
    model_path(@model)
  end

  def update_redirect
    model_path(@model)
  end

  def destroy_redirect
    models_path
  end

  def invalid_redirect
    models_path
  end
end
