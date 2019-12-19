#!/usr/bin/env ruby

Audited::Audit.where(new_changes: nil).find_in_batches do |audits|
  Audited::Audit.transaction do
    puts "Migrating audits #{audits.first.id} through #{audits.last.id}"
    audits.each do |audit|
      audit.update!(new_changes: audit.audited_changes)
    end
  end
end
