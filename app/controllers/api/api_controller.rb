class Api::ApiController < ActionController::Base
  include Rails::Pagination
  include Authentication::Api

  protect_from_forgery with: :exception
  before_action :check_token
  around_action :set_timezone
  around_action :handle_param_validation

  resource_description do
    formats ['json']
    meta author: {name: 'Marri'}
    app_info 'The public API for the Glowfic Constellation'
  end

  protected

  def check_token
    # checks for invalid tokens in a before to prevent double renders
    logged_in?
  end

  def login_required
    return if logged_in?
    error = {message: "You must be logged in to view that page."}
    render json: {errors: [error]}, status: :unauthorized and return
  end

  def set_timezone
    Time.use_zone("UTC") { yield }
  end

  def handle_param_validation
    yield
  rescue Apipie::ParamMissing, Apipie::ParamInvalid => e
    error_hash = {message: Glowfic::Sanitizers.full(e.message.tr('"', "'"))}
    render json: {errors: [error_hash]}, status: :unprocessable_entity
  end

  def access_denied
    error = {message: "You do not have permission to perform this action."}
    render json: {errors: [error]}, status: :forbidden
  end

  def find_object(klass, param: :id, status: :not_found)
    object = klass.find_by_id(params[param])
    unless object
      error = {message: klass.to_s + " could not be found."}
      render json: {errors: [error]}, status: status and return
    end
    object
  end

  def per_page
    per = params[:per_page].to_i
    return 25 if per < 1
    return 100 if per > 100
    per
  end

  def reorder(id_list, model_klass:, model_name: nil, parent_klass:, section_klass: nil, section_key: nil, section_id: nil)
    model_name ||= model_klass.model_name.to_s.downcase
    parent_name = parent_klass.model_name.to_s.downcase
    parent_key = parent_name.foreign_key.to_sym
    sectioned = !section_klass.nil?
    section_key ||= section_klass.model_name.to_s.foreign_key.to_sym if sectioned
    section_id = section_id ? section_id.to_i : nil

    id_list = id_list.map(&:to_i).uniq
    list = model_klass.where(id: id_list)
    count = list.count
    unless count == id_list.count
      missing_items = id_list - list.pluck(:id)
      error = {message: "Some #{model_name.pluralize} could not be found: #{missing_items.join(', ')}"}
      render json: {errors: [error]}, status: :not_found and return
    end

    parents = parent_klass.where(id: list.select(parent_key).distinct.pluck(parent_key))
    unless parents.count == 1
      error = {message: "#{model_name.pluralize.humanize} must be from one #{parent_name}"}
      render json: {errors: [error]}, status: :unprocessable_entity and return
    end

    parent = parents.first
    access_denied and return unless parent.editable_by?(current_user)

    if sectioned
      section_ids = list.select(section_key).distinct.pluck(section_key)
      unless section_ids == [section_id] && (section_id.nil? || section_klass.where(id: section_id, parent_key => parent.id).exists?)
        error = {message: "Posts must be from one specified section in the #{parent_name}, or no section"}
        render json: {errors: [error]}, status: :unprocessable_entity and return
      end
    end

    model_klass.transaction do
      list = list.sort_by {|item| id_list.index(item.id) }
      list.each_with_index do |item, i|
        next if item.section_order == i
        item.update(section_order: i)
      end

      other_models = model_klass.where(parent_key => parent.id).where.not(id: id_list)
      if sectioned
        other_models = other_models.where(section_key => section_id).ordered_in_section
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
