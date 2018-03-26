# used to do bulk updates of a single model (e.g. Post)
# when there are potentially too many objects to be updated,
# slow callbacks, or similar complications such that performing
# the updates synchronously in the API is undesirable.

class UpdateModelJob < ApplicationJob
  queue_as :low

  def perform(klass, where_vals, new_attrs)
    klass.constantize.where(where_vals).find_each do |model|
      model.update(new_attrs)
    end
  end
end
