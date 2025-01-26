require 'request_store'

module Audited
  # reverts the use of ActiveSupport::CurrentAttributes from
  # https://github.com/collectiveidea/audited/pull/702 due to misbehavior around
  # perform_enqueued_jobs in tests and resetting of Model.auditing_enabled config settings
  class << self
    def store
      ::RequestStore.store[:audited_store] ||= {}
    end
  end

  module Auditor
    module AuditedInstanceMethods
      private

      def write_audit(attrs)
        attrs[:associated] = send(audit_associated_with) unless audit_associated_with.nil?
        self.audit_comment = nil
        run_callbacks(:audit) do
          audit = audits.build(attrs)
          if audited_options[:mod_only]
            if audit.audit_user.nil? || audit.audit_user.id == self.user_id
              audits.delete(audit) # otherwise the unsaved audit is persisted on model.save
            end
          else
            audit.save # required to persist on model.destroy
          end
          audit
        end if auditing_enabled
      end
    end
  end

  class Audit < ::ActiveRecord::Base
    def audit_user
      set_audit_user unless self.user
      self.user
    end
  end
end
