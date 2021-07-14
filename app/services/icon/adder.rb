class Icon::Adder < Object
  attr_reader :errors, :icons

  def initialize(icons, gallery: nil)
    @icons = icons
    @gallery = gallery
    @errors = []
  end

  def add
    icons = @icons.map { |hash| Icon.new(icon_params(hash.except('filename', 'file')).merge(user: current_user)) }

    if icons.any? { |i| !i.valid? }
      flash.now[:error] = {
        message: "Your icons could not be saved.",
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
  end

  private

  def icon_params(paramset)
    paramset.permit(:url, :keyword, :credit, :s3_key)
  end
end
