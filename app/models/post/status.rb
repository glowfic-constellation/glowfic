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

    # explicitly on hiatus, or not updated for a month (see #on_hiatus?)
    scope :on_hiatus, -> { hiatus.or(where('tagged_at < ?', 1.month.ago)) }
    scope :not_on_hiatus, -> { where.not(status: :hiatus).where('tagged_at > ?', 1.month.ago) }

    def on_hiatus?
      hiatus? || (active? && tagged_at < 1.month.ago)
    end
  end
end
