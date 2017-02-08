module Presentable
  extend ActiveSupport::Concern

  included do
    def as_json_with_presenter(options={})
      begin
        presenter = (self.class.name + "Presenter").constantize
      rescue NameError
        as_json_without_presenter(options)
      else
        presenter.new(self).as_json(options)
      end
    end
    alias_method_chain :as_json, :presenter
  end
end
