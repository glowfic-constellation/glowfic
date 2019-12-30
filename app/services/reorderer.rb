class Reorderer < Object
  attr_reader :error

  def initialize(ordering_class, ordered_in_class, user)
    @success = false
    @error = nil
    @ordering_class = ordering_class
    @ordered_in_class = ordered_in_class
    @user = user
  end

  def section_id=(val)
    @section_id = val ? val.to_i : nil
  end

  def new_ordering_ids=(val)
    @new_ordering_ids = val.map(&:to_i).uniq
  end

  def reorder
    return unless validate_missing_items
    return unless validate_parent
    return unless validate_same_parent

    do_reorder
  end

  def succeeded?
    @success
  end

  private

  def validate_missing_items
    @items = @ordering_class.where(id: @new_ordering_ids)
    item_count = @items.count
    return true if item_count == @new_ordering_ids.count

    missing_items = @new_ordering_ids - @items.pluck(:id)
    @error = {
      message: "Some #{display_name.pluralize} could not be found: #{missing_items * ', '}",
      status: :not_found
    }
    false
  end

  def validate_parent
    parents = @ordered_in_class.where(id: @items.select(parent_column).distinct.pluck(parent_column))
    if parents.count > 1
      @error = {
        message: "#{display_name.pluralize.titlecase} must be from one #{@ordered_in_class.name.downcase}",
        status: :unprocessable_entity
      }
      return
    end

    @parent = parents.first
    return true if @parent.editable_by?(@user)
    @error = {
      message: 'You do not have permission to perform this action.',
      status: :forbidden
    }
    false
  end

  def validate_same_parent
    return true unless @ordering_class == Post || @ordering_class == IndexPost

    section_ids = @items.select(section_column).distinct.pluck(section_column)
    section_class = (@ordered_in_class.name + "Section").constantize
    return true if section_ids == [@section_id] &&
      (@section_id.nil? || section_class.where(:id => @section_id, parent_column => @parent.id).exists?)

    @error = {
      message: "#{display_name.pluralize.titlecase} must be from one specified section in the #{@ordered_in_class.name.downcase}, or no section",
      status: :unprocessable_entity
    }
    false
  end

  def do_reorder
    begin
      IndexPost.transaction do
        reorder_items
        reorder_others
      end
      @success = true
      queryset.send(ordering).pluck(:id)
    rescue ActiveRecord::RecordInvalid
      @error = {
        status: :unprocessable_entity,
        message: 'An unexpected error occurred.'
      }
    end
  end

  def reorder_items
    ordered_items = @items.sort_by { |item| @new_ordering_ids.index(item.id) }
    ordered_items.each_with_index do |item, order|
      next if item.section_order == order
      item.update!(section_order: order)
    end
  end

  def reorder_others
    other_items = queryset.where.not(id: @new_ordering_ids).send(ordering)
    other_items.each_with_index do |item, index|
      order = index + @new_ordering_ids.size
      next if item.section_order == order
      item.update!(section_order: order)
    end
  end

  def queryset
    qs = @ordering_class.where(parent_column => @parent.id)
    qs = qs.where(section_column => @section_id) if @section_id
    qs
  end

  def section_column
    @section_col ||= (@ordering_class == Post ? :section_id : :index_section_id)
  end

  def parent_column
    @parent_col ||= "#{@ordered_in_class.name.downcase}_id"
  end

  def ordering
    return :ordered unless @ordering_class.name.include?('Post')
    :ordered_in_section
  end

  def display_name
    return 'post' if @ordering_class.name.include?('Post')
    'section'
  end
end
