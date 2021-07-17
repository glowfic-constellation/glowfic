def convert_versions
  post_audits = Audited::Audit.where(auditable_type: 'Post', version_id: nil).order(auditable_id: :asc, id: :asc)
  post_audits.find_each do |audit|
    Version.transaction do
      version = setup_version(audit)
      version.save!
      audit.update!(version_id: version.id)
    end
  end

  reply_audits = Audited::Audit.where(auditable_type: 'Reply', version_id: nil).order(associated_id: :asc, auditable_id: :asc, id: :asc)
  reply_audits.find_each do |audit|
    Version.transaction do
      version = setup_version(audit)
      version.post_id = audit.associated_id
      version.save!
      audit.update!(version_id: version.id)
    end
  end

  character_audits = Audited::Audit.where(auditable_type: 'Character', version_id: nil).order(auditable_id: :asc, id: :asc)
  character_audits.find_each do |audit|
    Version.transaction do
      version = setup_version(audit)
      version.save!
      audit.update!(version_id: version.id)
    end
  end

  block_audits = Audited::Audit.where(auditable_type: 'Block', version_id: nil).order(auditable_id: :asc, id: :asc)
  block_audits.find_each.find_each do |audit|
    Version.transaction do
      version = setup_version(audit)
      version.save!
      audit.update!(version_id: version.id)
    end
  end
end

def setup_version(audit)
  Post::Version.new(
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
