class Icon::Adder < Object
  attr_reader :errors, :icon_hashes

  def initialize(icon_hashes, gallery: nil, user:)
    @icon_hashes = (icon_hashes || []).reject { |icon| icon.values.all?(&:blank?) }
    @errors = "You have to enter something." and return if @icon_hashes.empty?

    @icon_hashes = @icon_hashes.map { |hash| icon_params(hash).merge(user: user) }
    @gallery = gallery
    @errors = []
  end

  def add
    @icons = @icon_hashes.map { |hash| Icon.new(hash) }
    validate_icons
    return if @errors.present?
    save_icons
    return if @errors.present?
    @gallery.icons += @icons if @gallery
  end

  private

  def validate_icons
    @icons.each_with_index do |icon, index|
      next if icon.valid?
      if icon.errors.added?(:url, :invalid)
        @icon_hashes[index]['url'] = ''
        @icon_hashes[index]['s3_key'] = ''
      end
      @errors += get_errors(icon, index)
    end
  end

  def save_icons
    Icon.transaction do
      @icons.each(&:save)
      process_errors
      raise ActiveRecord::Rollback if @errors.present?
    end
  end

  def process_errors
    return unless @icons.detect(&:new_record?)
    @icons.each_with_index do |icon, index|
      next if icon.persisted?
      @errors += get_errors(icon, index)
    end
  end

  def get_errors(icon, index)
    prefix = "Icon #{index + 1}: "
    if icon.errors.present?
      icon.errors.full_messages.map { |m| prefix + m.downcase }
    else
      [prefix + 'could not be saved']
    end
  end

  def icon_params(paramset)
    paramset.permit(:url, :keyword, :credit, :s3_key)
  end
end
