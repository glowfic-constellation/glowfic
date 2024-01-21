class Gallery::IconAdder < Generic::Service
  attr_reader :icon_errors, :icons

  def initialize(gallery, user:, params:)
    @gallery = gallery
    @user = user
    @params = params
    @icon_errors = []
    super()
  end

  def assign_existing
    @errors.add(:gallery, "could not be found.") && return unless @gallery # gallery required for adding icons from other galleries

    icon_ids = @params[:image_ids].split(',').map(&:to_i).reject(&:zero?)
    icon_ids -= @gallery.icons.ids
    icons = Icon.where(id: icon_ids, user_id: @user.id)
    @gallery.icons += icons
  end

  def create_new
    @icons = (@params[:icons] || []).reject { |icon| icon.values.all?(&:blank?) }
    @errors.add(:base, "You have to enter something.") && return if icons.empty?
    validate_icons
    return if @errors.present?
    save_icons
  end

  def validate_icons
    icons = @icons.map { |hash| Icon.new(icon_params(hash.except('filename', 'file')).merge(user: @user)) }

    if icons.any? { |i| !i.valid? }
      icons.each_with_index do |icon, index|
        next if icon.valid?
        @icon_errors += icon.get_errors(index)
      end
    end

    @errors.add(:icons, "could not be saved because of the following problems:") if @icon_errors.present?
  end

  def save_icons
    Icon.transaction do
      icons.each_with_index do |icon, index|
        next if icon.save
        @icon_errors += icon.errors.present? ? icon.get_errors(index) : ["Icon #{index + 1} could not be saved."]
      end
      raise ActiveRecord::Rollback if @errors.present?
      @gallery.icons += icons if @gallery
    end

    @errors.add(:icons, "could not be saved because of the following problems:") && return if @icon_errors.present?
  end

  def icon_params(paramset)
    paramset.permit(:url, :keyword, :credit, :s3_key)
  end
end
