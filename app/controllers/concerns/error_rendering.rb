module ErrorRendering
  # when called with arguments as in render_err_to, render_err will save
  # an error hash to flash.
  # otherwise, it returns an ErrorRenderer, which allows chaining like:
  # render_err.now(...) to render to flash.now instead
  def render_err(*args, **kwargs)
    renderer = ErrorRenderer.new(flash, self)
    unless args.empty? && kwargs.empty?
      renderer.flash(*args, **kwargs)
      return
    end
    renderer
  end

  # render_err_to stores an error hash in a flash, typically called via
  # render_err(...) or render_err.now(...)
  #
  # - target should either be flash or flash.now
  # - model should be the specific object that failed to save, including errors
  # - key corresponds to a translation key to use (actioncontroller.errors.messages.<key>),
  #   like :create_failed or :deleted_failed.
  # - model_name allows overriding the translation for the model class in specific contexts
  #   (e.g. User -> account settings)
  # - err allows passing the save exception if applicable
  def render_err_to(target, model, key, model_name: nil, err: nil)
    model_name ||= model

    lists_errors = model.errors.present?
    msg = t_err(key, model: model_name, format: lists_errors ? :intro : :final)
    if lists_errors
      msg = {
        message: msg,
        array: model.errors.full_messages,
      }
    elsif err
      log_error(err)
    end

    target[:error] = msg
  end

  # ErrorRendering is a DSL helper for render_err, allowing calls like:
  # render_err.now(...), to render to flash.now
  # it is returned when render_err is called with no arguments
  class ErrorRenderer
    def initialize(flash, controller)
      @flash = flash
      @controller = controller
    end

    def flash(*args, **kwargs)
      @controller.render_err_to(@flash, *args, **kwargs)
    end

    def now(*args, **kwargs)
      @controller.render_err_to(@flash.now, *args, **kwargs)
    end
  end
end
