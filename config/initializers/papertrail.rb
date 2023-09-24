module PaperTrail # rubocop:disable Style/ClassAndModuleChildren
  class Version < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    include PaperTrail::VersionConcern
    self.abstract_class = true
  end
end
