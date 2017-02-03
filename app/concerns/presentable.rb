module Presentable
  extend ActiveSupport::Concern

  included do
    def as_json(*args, **kwargs)
      begin
        presenter = (self.class.name + "Presenter").constantize
      rescue NameError
        super
      else
        presenter.new(self).as_json(*args, **kwargs)
      end
    end
  end
end