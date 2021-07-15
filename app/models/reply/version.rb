class Reply::Version < ::Version
  self.table_name = :reply_versions

  belongs_to :reply, foreign_key: :item_id, inverse_of: :versions
  belongs_to :post, inverse_of: false
end
