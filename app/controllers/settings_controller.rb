# frozen_string_literal: true
class SettingsController < TaggableController
  def index
    @settings = Setting::Searcher.new.search(name: params[:name], page: page)
    @post_counts = Post.visible_to(current_user).joins(setting_posts: :setting).where(setting_posts: { setting_id: @settings.map(&:id) })
    @post_counts = @post_counts.group('setting_posts.setting_id').count
    @page_title = 'Settings'
  end

  def edit
    super
    build_editor
  end

  def update
    @setting.assign_attributes(permitted_params)

    begin
      Setting.transaction do
        @setting.parent_settings = process_tags(Setting, obj_param: :setting, id_param: :parent_setting_ids)
        @setting.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@tag, action: 'updated', now: true, err: e)

      @page_title = "Edit Setting: #{@setting.name}"
      build_editor
      render :edit
    else
      flash[:success] = "Setting updated."
      redirect_to setting_path(@setting)
    end
  end

  def destroy
    begin
      @setting.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@tag, action: 'deleted', err: e)
      redirect_to @setting
    else
      flash[:success] = "Setting deleted."

      url_params = {}
      url_params[:page] = page if params[:page].present?
      url_params[:view] = params[:view] if params[:view].present?
      redirect_to settings_path(url_params)
    end
  end

  private

  def find_model
    super(Setting, settings_path)
    @setting = @tag
  end

  def build_editor
    use_javascript('tags/edit')
  end
end
