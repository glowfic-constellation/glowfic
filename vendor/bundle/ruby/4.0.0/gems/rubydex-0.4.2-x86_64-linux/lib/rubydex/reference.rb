# frozen_string_literal: true

module Rubydex
  class Reference
    #: () -> Location
    def location
      raise NotImplementedError, "Subclasses must implement the #location method"
    end
  end
end
