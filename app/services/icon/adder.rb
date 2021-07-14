class Icon::Adder < Object
  attr_reader :errors, :icon_hashes

  def initialize(icons, gallery: nil)
    @icon_hashes = icons
    @icons = []
    @gallery = gallery
    @errors = []
  end

  def add(user:)
    @icons = @icon_hashes.map { |hash| Icon.new(icon_params(hash.except('filename', 'file')).merge(user: user)) }
    validate_icons
    return if @errors.present?
    save_icons
    return if @errors.present?
    @gallery.icons += @icons if @gallery
  end

  def validate_icons
    @icons.each_with_index do |icon, index|
      next if icon.valid?
      if icon.errors.added?(:url, :invalid)
        @icon_hashes[index]['url'] = ''
        @icon_hashes[index]['s3_key'] = ''
      end
      @errors += icon.get_errors(index)
    end
  end

  def save_icons
    Icon.transaction do
      @icons.each_with_index do |icon, index|
        next if icon.save

        if icon.errors.present?
          @errors += icon.get_errors(index)
        else
          @errors += ["Icon #{index + 1} could not be saved."]
        end
      end
      
      raise ActiveRecord::Rollback if @errors.present?
    end
  end

  private

  def icon_params(paramset)
    paramset.permit(:url, :keyword, :credit, :s3_key)
  end
end
