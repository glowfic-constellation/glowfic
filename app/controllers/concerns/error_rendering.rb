module ErrorRendering
  class ErrorRenderer
    def initialize(target, source)
      @target = target
      @source = source
    end

    def now(*args, **kwargs)
      @source.send(:render_err_target, @target.now, *args, **kwargs)
    end
  end

  def render_err(chain=:chain, *args, **kwargs)
    if chain == :chain
      ErrorRenderer.new(flash, self)
    else
      render_err_target(flash, chain, *args, **kwargs)
    end
  end

  private

  def render_err_target(target, model, key, model_name: nil, err: nil)
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
end
