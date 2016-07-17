# class must declare model_params to use
# frozen_string_literal: true
class CrudController < ApplicationController
  before_action :login_required, only: [:new, :create, :edit, :update, :destroy]
  before_action :find_model, only: [:show, :edit, :update, :destroy]
  before_action :setup_editor, only: [:new, :edit]
  before_action :require_view_permission, only: [:show, :edit, :update, :destroy]
  before_action :require_edit_permission, only: [:edit, :update]
  before_action :require_delete_permission, only: :destroy

  def index
    @page_title = controller_name.titlecase
  end

  def new
    @page_title = "New #{model_name}"
    model = model_class.new
    set_params(model)
    set_model(model)
  end

  def create
    model = model_class.new(model_params)
    set_params(model)

    unless model.save
      flash.now[:error] = {}
      flash.now[:error][:message] = "#{model_name} could not be created."
      flash.now[:error][:array] = model.errors.full_messages
      @page_title = "New #{model_name}"
      set_model(model)
      setup_editor
      render :new and return
    end

    flash[:success] = "#{model_name} created successfully."
    redirect_to model_path(model)
  end

  def show
    @page_title = @model.name.to_s
  end

  def edit
    @page_title = "Edit #{model_name}: #{@model.name}"
  end

  def update
    unless @model.update_attributes(model_params)
      flash.now[:error] = {}
      flash.now[:error][:message] = "#{model_name} could not be saved because of the following problems:"
      flash.now[:error][:array] = @model.errors.full_messages
      @page_title = "Edit #{model_name}: #{@model.name}"
      render :edit and return
    end

    flash[:success] = "#{model_name} saved!"
    redirect_to model_path(@model)
  end

  def destroy
    @model.destroy!
    flash[:success] = "#{model_name} deleted."
    redirect_to models_path
  rescue ActiveRecord::RecordNotDestroyed
    flash[:error] = {}
    flash[:error][:message] = "#{model_name} could not be deleted."
    flash[:error][:array] = @model.errors.full_messages
    redirect_to model_path(@model)
  end

  protected

  def find_model
    unless @model = model_class.find_by_id(params[:id])
      flash[:error] = "#{model_name} could not be found."
      redirect_to models_path and return
    end
    set_model(@model)
  end

  def require_view_permission
    return unless model_class.method_defined? :visible_to?
    unless @model.visible_to?(current_user)
      flash[:error] = "You do not have permission to view this #{controller_name.singularize}."
      redirect_to models_path
    end
  end

  def require_edit_permission
    return unless model_class.method_defined? :editable_by?
    unless @model.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this #{controller_name.singularize}."
      redirect_to model_path(@model) # TODO not if they don't have view permission either
    end
  end

  def require_delete_permission
    unless model_class.method_defined? :deletable_by?
      require_edit_permission
      return
    end

    unless @model.deletable_by?(current_user)
      flash[:error] = "You do not have permission to edit this #{controller_name.singularize}."
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

  def set_model(model)
    instance_variable_set("@#{controller_name.singularize}", model)
  end

  def setup_editor
    # pass
  end

  def set_params(model)
    # pass
  end
end
