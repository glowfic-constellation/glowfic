# used to do bulk updates of a single model (e.g. Post)
# when there are potentially too many objects to be updated,
# slow callbacks, or similar complications such that performing
# the updates synchronously in the API is undesirable.

class UpdateModelJob < ApplicationJob
  queue_as :low

  def perform(klass, where_vals, new_attrs, user_id=0)
    if user_id == 0
      UpdateModelJob.notify_exception(ArgumentError, klass, where_vals, new_attrs)
    elsif (user = User.find_by(id: user_id)).nil?
      UpdateModelJob.notify_exception(ActiveRecord::RecordNotFound, klass, where_vals, new_attrs, user_id)
    end

    if user_id == 0
      update_records(klass, where_vals, new_attrs)
    else
      Audited.audit_class.as_user(user) do
        update_records(klass, where_vals, new_attrs)
      end
    end
  end

  def update_records(klass, where_vals, new_attrs)
    klass.constantize.where(where_vals).find_each do |model|
      model.update!(new_attrs)
    end
  end
end
