class Reply::Version < ::Version
  self.table_name = :reply_versions

  belongs_to :reply, foreign_key: :item_id, optional: true, inverse_of: :versions
  belongs_to :post, inverse_of: false

  alias_attribute :auditable, :item
  alias_attribute :auditable_id, :item_id
  alias_attribute :associated, :post
end
