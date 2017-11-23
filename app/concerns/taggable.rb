module Taggable
  def process_tags(klass, obj_param, id_param)
    # fetch and clean tag ids
    ids = params.fetch(obj_param, {}).fetch(id_param, [])
    ids = ids.reject(&:blank?).map(&:to_s)
    return [] unless ids.present?

    # separate existing from creating
    new_names = ids.select { |id| id.to_s.start_with?('_') }
    existing_tags = klass.where(id: (ids - new_names))
    new_names.map! { |name| name[1..-1].strip }

    # locate anything that already exists and substitute it
    matched_new_tags = klass.where(name: new_names)
    matched_new_names = matched_new_tags.map { |tag| tag.name.upcase }
    new_names = new_names.reject { |name| matched_new_names.include?(name.upcase) }

    # create anything remaining. TODO uniq case insensitive
    new_tags = new_names.uniq.map { |name| klass.new(user: current_user, name: name) }

    # consolidate and sort (TODO sort)
    original_order = ids.map { |id| id.to_s.upcase }
    all_tags = (existing_tags + matched_new_tags + new_tags).uniq # TODO input order
  end
end
