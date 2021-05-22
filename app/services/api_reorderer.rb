class ApiReorderer < Object
  attr_reader :errors, :status

  def initialize(model_klass:, model_name: nil, parent_klass:, section_klass: nil, section_key: nil, section_id: nil)
    @model = {
      klass: model_klass,
      name: model_name || model_klass.model_name.to_s.downcase
    }

    @parent = {
      klass: parent_klass,
      name: parent_klass.model_name.to_s.downcase,
    }
    @parent[:key] = @parent[:name].foreign_key.to_sym

    unless section_klass.nil?
      @section = {
        klass: section_klass,
        key: section_key || section_klass.model_name.to_s.foreign_key.to_sym,
        id: section_id ? section_id.to_i : nil
      }
      @section[:where] = {@section[:key] => @section[:id]}
    end

    @errors = []
    @status = nil
  end

  def reorder(id_list, user: nil)
    id_list = id_list.map(&:to_i).uniq
    list = @model[:klass].where(id: id_list)
    return false unless check_items(list, id_list)
    return false unless set_parent(list, user)
    return false unless @section.nil? || check_section(list)

    @model[:klass].transaction do
      reorder_list(list, id_list)
      reorder_others(id_list)
    end

    return parent if block_given?

    generate_return
  end

  private

  def check_items(list, id_list)
    return true if list.count == id_list.count

    missing_items = id_list - list.pluck(:id)
    @errors << {message: "Some #{@model[:name].pluralize} could not be found: #{missing_items.join(', ')}"}
    @status = :not_found
    false
  end

  def set_parent(list, user)
    parents = @parent[:klass].where(id: list.select(@parent[:key]).distinct.pluck(@parent[:key]))
    unless parents.count == 1
      @errors << {message: "#{@model[:name].pluralize.humanize} must be from one #{@parent[:name]}"}
      @status = :unprocessable_entity
      return false
    end

    @parent[:obj] = parents.first
    @parent[:id] = @parent[:obj].id
    @parent[:where] = {@parent[:key] => @parent[:id]}
    return true if @parent[:obj].editable_by?(user)

    @errors << {message: "You do not have permission to perform this action."}
    @status = :forbidden
    false
  end

  def check_section(list)
    section_ids = list.select(@section[:key]).distinct.pluck(@section[:key])
    return true if section_ids == [@section[:id]] && (@section[:id].nil? || @section[:klass].where(id: @section[:id]).where(@parent[:where]).exists?)

    @errors << {message: "Posts must be from one specified section in the #{@parent[:name]}, or no section"}
    @status = :unprocessable_entity
    false
  end

  def reorder_list(list, id_list)
    list = list.sort_by {|item| id_list.index(item.id) }
    list.each_with_index do |item, i|
      next if item.section_order == i
      item.update(section_order: i)
    end
  end

  def reorder_others(id_list)
    other_models = @model[:klass].where(@parent[:where]).where.not(id: id_list)
    if @section.present?
      other_models = other_models.where(@section[:where]).ordered_in_section
    else
      other_models = other_models.ordered
    end
    other_models.each_with_index do |item, j|
      order = j + id_list.size
      next if item.section_order == order
      item.update(section_order: order)
    end
  end

  def generate_return
    return_list = @model[:klass].where(@parent[:where])
    if @section.present?
      return_list = return_list.where(@section[:where]).ordered_in_section
    else
      return_list = return_list.ordered
    end
    return_list.pluck(:id)
  end
end
