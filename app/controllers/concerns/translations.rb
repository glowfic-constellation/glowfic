module Translations
  def t_notify(key, action = :notifications, model_name = nil)
    model_name = if model_name
      t(model_name, scope: :models)
    else
      associated_model.model_name.human
    end

    t(
      key,
      model_name: model_name,
      scope: [:actioncontroller, action, :messages],
    )
  end

  def t_success(key, model_name=nil)
    t_notify(key, :success, model_name)
  end

  def t_err(key, model_name=nil)
    t_notify(key, :errors, model_name)
  end
end
