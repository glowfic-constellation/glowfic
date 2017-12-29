# frozen_string_literal: true
class SettingsController < ApplicationController
  include Taggable

  before_action :login_required, except: [:index, :show]
  before_action :find_setting, except: :index
  before_action :permission_required, except: [:index, :show, :destroy]

  def index
    @page_title = 'Settings'

    @settings = Setting
      .select('settings.*')
      .with_item_counts
      .order('LOWER(name) asc')
      .paginate(per_page: 25, page: page)
  end

  def show
    @posts = posts_from_relation(@setting.posts)
    @characters = @setting.characters.includes(:user, :template)
    @page_title = @setting.name.to_s
  end

  def edit
    @page_title = "Edit Setting: #{@setting.name}"
    build_editor
  end

  def update
    @setting.assign_attributes(setting_params)

    begin
      Tag.transaction do
        @setting.parent_settings = process_tags(Setting, :setting, :parent_setting_ids)
        @setting.save!
      end

      flash[:success] = "Setting saved!"
      redirect_to setting_path(@setting)

    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {}
      flash.now[:error][:message] = "Setting could not be saved because of the following problems:"
      flash.now[:error][:array] = @setting.errors.full_messages
      @page_title = "Edit Setting: #{@setting.name}"
      build_editor
      render action: :edit and return
    end
  end

  def destroy
    unless @setting.deletable_by?(current_user)
      flash[:error] = "You do not have permission to edit this setting."
      redirect_to setting_path(@setting) and return
    end

    @setting.destroy
    flash[:success] = "Setting deleted."

    url_params = {}
    url_params[:page] = page if params[:page].present?
    redirect_to settings_path(url_params)
  end

  private

  def find_setting
    unless (@setting = Setting.find_by_id(params[:id]))
      flash[:error] = "Setting could not be found."
      redirect_to settings_path
    end
  end

  def permission_required
    unless @setting.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this setting."
      redirect_to setting_path(@setting)
    end
  end

  def build_editor
    use_javascript('tags/edit')
  end

  def setting_params
    permitted = [:type, :description, :owned]
    permitted.insert(0, :name, :user_id) if current_user.admin? || @setting.user == current_user
    params.fetch(:setting, {}).permit(permitted)
  end
end
