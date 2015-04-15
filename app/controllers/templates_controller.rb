class TemplatesController < ApplicationController
  before_filter :login_required
  before_filter :find_template, :only => [:show, :destroy]

  def index
    @templates = current_user.templates
  end

  def new
    @template = Template.new
  end

  def create
    @template = Template.new(params[:template])
    @template.user = current_user
    if @template.save
      flash[:success] = "Template saved successfully."
      redirect_to templates_path
    else
      flash[:error] = "Your template could not be saved."
      render :action => :new
    end
  end

  def show
  end

  def update
  end

  def destroy
    @template.destroy
    flash[:success] = "Template deleted successfully."
    redirect_to templates_path
  end

  private

  def find_template
    @template = Template.find_by_id(params[:id])

    unless @template
      flash[:error] = "Template could not be found."
      redirect_to templates_path and return
    end

    if @template.user_id != current_user.id
      flash[:error] = "That is not your template."
      redirect_to templates_path and return
    end
  end
end
