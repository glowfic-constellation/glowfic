# include Presentable in a model Model to have it automatically use
# app/presenters/ModelPresenter.rb to generate its JSON.
#
# Can safely be included on classes with no presenter file;
# it will fall back to the default Rails as_json method.
#
# Limitations:
# - Presenter must have an initializer that takes the model as an argument
# - Presenter must implement as_json(options={})
# - If the class Model implements its own as_json method that will override the presenter
#   unless you include Presentable after the as_json is defined

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
