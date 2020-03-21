module Translations
  def t_notify(key, action: :notifications, model: nil)
    model_name = if model.respond_to?(:model_name)
      model.model_name.human
    else
      t(model, scope: :models)
    end

    t(
      key,
      model_name: model_name,
      scope: [:actioncontroller, action, :messages],
    )
  end

  def t_success(key, **kwargs)
    kwargs = { action: :success }.merge(kwargs)
    t_notify(key, **kwargs)
  end

  def t_err(key, **kwargs)
    kwargs = { action: :errors }.merge(kwargs)
    t_notify(key, **kwargs)
  end
end
