# frozen_string_literal: true
module Post::Status
  extend ActiveSupport::Concern

  included do
    enum :status, {
      active: 0,
      complete: 1,
      hiatus: 2,
      abandoned: 3,
    }

    def on_hiatus?
      hiatus? || (active? && tagged_at < 1.month.ago)
    end
  end
end
