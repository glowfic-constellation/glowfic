def convert_versions
  audits_for('Post').find_each do |audit|
    create_version(audit, Post::Version)
  end

  reply_audits = audits_for('Reply').reorder(associated_id: :asc, auditable_id: :asc, id: :asc)
  reply_audits.find_each do |audit|
    Version.transaction do
      version = setup_version(audit, Reply::Version)
      version.post_id = audit.associated_id
      version.save!
      audit.update!(version_id: version.id)
    end
  end

  audits_for('Character').find_each do |audit|
    create_version(audit, Character::Version)
  end

  audits_for('Block').find_each do |audit|
    create_version(audit, Block::Version)
  end
end

def audits_for(model)
  Audited::Audit.where(auditable_type: model, version_id: nil).order(auditable_id: :asc, id: :asc)
end

def create_version(audit, model)
  Version.transaction do
    version = setup_version(audit, model)
    version.save!
    audit.update!(version_id: version.id)
  end
end

def setup_version(audit, model)
  model.new(
    item_id: audit.auditable_id,
    item_type: audit.auditable_type,
    event: audit.action,
    whodunnit: audit.user_id,
    object: audit.auditable.revision_at(audit.created_at - 1.second),
    object_changes: convert_changes(audit.auditable_changes, audit.action),
    comment: audit.comment,
    ip: audit.remote_address,
    request_uuid: audit.request_uuid,
    created_at: audit.created_at,
  )
end

def convert_changes(changes, action)
  case action
    when 'create'
      changes.transform_values { |new| [nil, new] }
    when 'update'
      changes
    when 'destroy'
      changes.transform_values { |old| [old, nil] }
  end
end

convert_versions if $PROGRAM_NAME == __FILE__
