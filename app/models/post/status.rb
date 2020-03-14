module Post::Status
  extend ActiveSupport::Concern

  ACTIVE = 0
  COMPLETE = 1
  HIATUS = 2
  ABANDONED = 3

  included do
    def completed?
      status == COMPLETE
    end

    def on_hiatus?
      marked_hiatus? || (active? && tagged_at < 1.month.ago)
    end

    def marked_hiatus?
      status == HIATUS
    end

    def active?
      status == ACTIVE
    end

    def abandoned?
      status == ABANDONED
    end
  end

  def self.get_status(param)
    statuses = ['Active', 'Complete', 'Hiatus', 'Abandoned'].map(&:upcase)
    raise NameError unless statuses.include?(param)
    const_get(param)
  end
end
