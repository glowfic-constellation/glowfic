class ReportView < ApplicationRecord
  belongs_to :user, optional: false
end
