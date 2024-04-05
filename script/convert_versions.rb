def convert_versions
  audits_for('Post').find_each do |audit|
    create_version(audit, Post::Version)
  end

  audits_for('Reply').find_each do |audit|
    create_version(audit, Reply::Version)
  end

  audits_for('Character').find_each do |audit|
    create_version(audit, Character::Version)
  end

  audits_for('Block').find_each do |audit|
    create_version(audit, Block::Version)
  end
end

def audits_for(model)
  audits = Audited::Audit.where(auditable_type: model, version_id: nil)
  if model == 'Reply'
    audits.order(associated_id: :asc, auditable_id: :asc, id: :asc)
  else
    audits.order(auditable_id: :asc, id: :asc)
  end
end

def create_version(audit, klass)
  Version.transaction do
    version = setup_version(audit, klass)
    version.save!
    audit.update!(version_id: version.id)
  end
end

def setup_version(audit, klass)
  version = klass.new(
    item_id: audit.auditable_id,
    item_type: audit.auditable_type,
    event: audit.action,
    whodunnit: audit.user_id,
    object_changes: convert_changes(audit.audited_changes, audit.action),
    comment: audit.comment,
    ip: audit.remote_address,
    request_uuid: audit.request_uuid,
    created_at: audit.created_at,
  )
  version.post_id = audit.associated_id if klass == Reply::Version
  version
end

def convert_changes(changes, action)
  case action
    when 'create'
      changes.transform_values! { |new| [nil, new] }
      changes.delete_if { |_, value| value == [nil, nil] }
    when 'update'
      changes
    when 'destroy'
      changes.transform_values! { |old| [old, nil] }
      changes.delete_if { |_, value| value == [nil, nil] }
  end
end

convert_versions if $PROGRAM_NAME == __FILE__
