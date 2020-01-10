class ReportView < ApplicationRecord
  belongs_to :user, optional: false

  validates :user, uniqueness: true
end
