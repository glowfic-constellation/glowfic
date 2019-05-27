class Gallery::IconAdder < Object
  def initialize(gallery, user:, params:)
    @gallery = gallery
    @user = user
    @params = params
  end

  def add
    if params[:image_ids].present?
      return unless find_model # gallery required for adding icons from other galleries

      icon_ids = params[:image_ids].split(',').map(&:to_i).reject(&:zero?)
      icon_ids -= @gallery.icons.ids
      icons = Icon.where(id: icon_ids, user_id: current_user.id)
      @gallery.icons += icons

      flash[:success] = "Icons added to gallery."
      redirect_to @gallery
    else
      add_new_icons
    end
  end

  def add_new_icons
    @icons = (params[:icons] || []).reject { |icon| icon.values.all?(&:blank?) }

    if @icons.empty?
      flash.now[:error] = "You have to enter something."
      render :add and return
    end

    icons = @icons.map { |hash| Icon.new(icon_params(hash.except('filename', 'file')).merge(user: current_user)) }

    if icons.any? { |i| !i.valid? }
      flash.now[:error] = {
        message: "Icons could not be saved because of the following problems:",
        array: [],
      }

      icons.each_with_index do |icon, index|
        next if icon.valid?
        @icons[index]['url'] = @icons[index]['s3_key'] = '' if icon.errors.added?(:url, :invalid)
        flash.now[:error][:array] += icon.get_errors(index)
      end

      render :add and return
    end

    errors = []
    Icon.transaction do
      icons.each_with_index do |icon, index|
        next if icon.save
        errors += icon.errors.present? ? icon.get_errors(index) : ["Icon #{index + 1} could not be saved."]
      end
      raise ActiveRecord::Rollback if errors.present?
      @gallery.icons += icons if @gallery
    end

    if errors.present?
      flash.now[:error] = {
        message: "Icons could not be saved because of the following problems:",
        array: errors,
      }
      render :add
    else
      flash[:success] = "Icons saved."
      redirect_to @gallery || user_gallery_path(id: 0, user_id: current_user.id)
    end
  end
end
