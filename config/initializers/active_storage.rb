require 'active_storage/attachment'

class ActiveStorage::Attachment
  before_save :do_something

  def do_something
    return unless self.record_type == 'Icon'
    self.record.url = Rails.application.routes.url_helpers.rails_blob_url(self)
  end
end