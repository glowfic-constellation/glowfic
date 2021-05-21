class ApiReorderer < Object
  attr_reader :errors, :status

  def initialize(model_klass:, model_name: nil, parent_klass:, section_klass: nil, section_key: nil)
    @model_klass = model_klass
    @model_name = model_name || model_klass.model_name.to_s.downcase
    @parent_klass = parent_klass
    @parent_name = parent_klass.model_name.to_s.downcase
    @parent_key = @parent_name.foreign_key.to_sym
    @section_klass = section_klass
    @section_key = section_key || section_klass.model_name.to_s.foreign_key.to_sym unless section_klass.nil?
    @errors = []
    @status = nil
  end

  def reorder(id_list, section_id: nil, user: nil)
    section_id = section_id ? section_id.to_i : nil
    id_list = id_list.map(&:to_i).uniq
    list = @model_klass.where(id: id_list)
    return false unless check_items(list, id_list)
    parent = check_parent(list, user)
    return false unless parent.is_a?(@parent_klass)
    if @section_klass.present?
      return false unless check_section(list, section_id: section_id, parent_id: parent.id)
    end
    do_reorder(list, id_list: id_list, parent_id: parent.id, section_id: section_id)

    return parent if block_given?

    return_list = @model_klass.where(@parent_key => parent.id)
    if @section_klass.present?
      return_list = return_list.where(@section_key => section_id).ordered_in_section
    else
      return_list = return_list.ordered
    end
    return_list.pluck(:id)
  end

  private

  def check_items(list, id_list)
    count = list.count
    unless count == id_list.count
      missing_items = id_list - list.pluck(:id)
      error = {message: "Some #{@model_name.pluralize} could not be found: #{missing_items.join(', ')}"}
      @errors << error
      @status = :not_found
      false
    end
  end

  def check_parent(list, user)
    parents = @parent_klass.where(id: list.select(@parent_key).distinct.pluck(@parent_key))
    unless parents.count == 1
      error = {message: "#{@model_name.pluralize.humanize} must be from one #{@parent_name}"}
      @errors << error
      @status = :unprocessable_entity
      return false
    end

    parent = parents.first
    @status = :forbidden and return false unless parent.editable_by?(user)
    parent
  end

  def check_section(list, section_id:, parent_id:)
    section_ids = list.select(@section_key).distinct.pluck(@section_key)
    unless section_ids == [section_id] && (section_id.nil? || @section_klass.where(id: section_id, @parent_key => parent_id).exists?)
      error = {message: "Posts must be from one specified section in the #{@parent_name}, or no section"}
      @errors << error
      @status = :unprocessable_entity
      return false
    end
  end

  def do_reorder(list, id_list:, parent_id:, section_id:)
    @model_klass.transaction do
      list = list.sort_by {|item| id_list.index(item.id) }
      list.each_with_index do |item, i|
        next if item.section_order == i
        item.update(section_order: i)
      end

      other_models = model_klass.where(@parent_key => parent_id).where.not(id: id_list)
      if @section_klass.present?
        other_models = other_models.where(@section_key => section_id).ordered_in_section
      else
        other_models = other_models.ordered
      end
      other_models.each_with_index do |item, j|
        order = j + count
        next if item.section_order == order
        item.update(section_order: order)
      end
    end

    return parent if block_given?

    return_list = model_klass.where(parent_key => parent.id)
    if sectioned
      return_list = return_list.where(section_key => section_id).ordered_in_section
    else
      return_list = return_list.ordered
    end
    return_list.pluck(:id)
  end
end
