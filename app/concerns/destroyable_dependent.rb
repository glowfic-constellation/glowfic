module DestroyableDependent
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_destroy_callbacks
  end
end
