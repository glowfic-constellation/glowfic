module Translations
  # t_sym_for takes a list of translation keys, like ['avatar', :errors, :messages, :update_failed]
  # and returns the translation path as a symbol for lookup, like :'avatar.errors.messages.update_failed'
  def t_sym_for(*args)
    args.map(&:to_s).join('.').to_sym
  end

  # translates a flash message from actioncontroller.<model>.<status>.messages.<key>
  # (or actioncontroller.<status>.messages.<key> if no model override is available)
  # for use in a flash message
  # e.g. (key: :saved, status: :success) "<model> saved."
  #      (key: :create_failed, status: :errors) "<model> could not be created."
  #      (key: :create_failed, status: :errors, format: :intro) "<model> could not be created, because of the following problems:"
  # if model is passed, it will be used to determine the model name for the translation
  # otherwise, associated_model will be used
  # format should be be :final if the flash should stand alone, or :intro if it comes with an array of errors
  def t_flash(key, status:, model: nil, format: :final)
    model ||= associated_model
    model_name = if model.respond_to?(:model_name)
      model.model_name.human
    else
      model
    end

    str = t(
      # pick up a model-specific translation if available
      t_sym_for(model_name.parameterize.underscore, status, :messages, key),
      model_name: model_name,
      scope: [:actioncontroller],
      # fall back to the basic translation otherwise
      default: t_sym_for(status, :messages, key),
    )

    # control the overall message format via :intro or :final
    # :final - "<Error>."
    # :intro - "<Error>, because of the following problems:")
    t(
      format,
      str: str,
      scope: [:actioncontroller, status, :formats],
    )
  end

  # translates a success message from actioncontroller.success.messages.<key>
  # (or an override via actioncontroller.<model>.success.messages.<key> if present)
  # e.g. :saved for "<model> saved."
  # see t_flash for more arguments
  def t_success(key, **kwargs)
    t_flash(key, status: :success, **kwargs)
  end

  # translates an error message from actioncontroller.errors.messages.<key>
  # (or an override via actioncontroller.<model>.errors.messages.<key> if present)
  # e.g. :create_failed for "<model> could not be created."
  # see t_flash for more arguments
  def t_err(key, **kwargs)
    t_flash(key, status: :errors, **kwargs)
  end
end
