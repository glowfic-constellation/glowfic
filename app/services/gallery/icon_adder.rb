class Gallery::IconAdder < Generic::Service
  attr_reader :success_message, :errors, :icons

  def initialize(gallery, user:, params:)
    @gallery = gallery
    @user = user
    @params = params
    @errors = []
  end

  def assign_existing
    raise MissingGalleryError, "Gallery could not be found." unless @gallery # gallery required for adding icons from other galleries

    icon_ids = @params[:image_ids].split(',').map(&:to_i).reject(&:zero?)
    icon_ids -= @gallery.icons.ids
    icons = Icon.where(id: icon_ids, user_id: @user.id)
    @gallery.icons += icons

    @success_message = "Icons added to gallery."
  end

  def create_new
    @icons = (@params[:icons] || []).reject { |icon| icon.values.all?(&:blank?) }
    raise NoIconsError, "You have to enter something." if icons.empty?

    icons = @icons.map { |hash| Icon.new(icon_params(hash.except('filename', 'file')).merge(user: @user)) }

    if icons.any? { |i| !i.valid? }
      icons.each_with_index do |icon, index|
        next if icon.valid?
        @errors += icon.get_errors(index)
      end
    end

    raise InvalidIconsError, "Icons could not be saved because of the following problems:" if @errors.present?

    Icon.transaction do
      icons.each_with_index do |icon, index|
        next if icon.save
        @errors += icon.errors.present? ? icon.get_errors(index) : ["Icon #{index + 1} could not be saved."]
      end
      raise ActiveRecord::Rollback if @errors.present?
      @gallery.icons += icons if @gallery
    end

    raise InvalidIconsError, "Icons could not be saved because of the following problems:" if @errors.present?
    @success_message = "Icons saved."
  end

  def icon_params(paramset)
    paramset.permit(:url, :keyword, :credit, :s3_key)
  end
end

class MissingGalleryError < ApiError; end
class NoIconsError < ApiError; end
class InvalidIconsError < ApiError; end
