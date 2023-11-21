# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `audited` gem.
# Please instead update this file by running `bin/tapioca gem audited`.

# source://audited/lib/audited.rb#6
module Audited
  class << self
    # source://audited/lib/audited.rb#16
    def audit_class; end

    # Sets the attribute audit_class
    #
    # @param value the value to set the attribute audit_class to.
    #
    # source://audited/lib/audited.rb#14
    def audit_class=(_arg0); end

    # remove audit_model in next major version it was only shortly present in 5.1.0
    #
    # source://activesupport/7.0.8lib/active_support/deprecation/method_wrappers.rb#63
    def audit_model(*args, **_arg1, &block); end

    # Returns the value of attribute auditing_enabled.
    #
    # source://audited/lib/audited.rb#8
    def auditing_enabled; end

    # Sets the attribute auditing_enabled
    #
    # @param value the value to set the attribute auditing_enabled to.
    #
    # source://audited/lib/audited.rb#8
    def auditing_enabled=(_arg0); end

    # @yield [_self]
    # @yieldparam _self [Audited] the object that the method was called on
    #
    # source://audited/lib/audited.rb#32
    def config; end

    # Returns the value of attribute current_user_method.
    #
    # source://audited/lib/audited.rb#8
    def current_user_method; end

    # Sets the attribute current_user_method
    #
    # @param value the value to set the attribute current_user_method to.
    #
    # source://audited/lib/audited.rb#8
    def current_user_method=(_arg0); end

    # Returns the value of attribute ignored_attributes.
    #
    # source://audited/lib/audited.rb#8
    def ignored_attributes; end

    # Sets the attribute ignored_attributes
    #
    # @param value the value to set the attribute ignored_attributes to.
    #
    # source://audited/lib/audited.rb#8
    def ignored_attributes=(_arg0); end

    # Returns the value of attribute max_audits.
    #
    # source://audited/lib/audited.rb#8
    def max_audits; end

    # Sets the attribute max_audits
    #
    # @param value the value to set the attribute max_audits to.
    #
    # source://audited/lib/audited.rb#8
    def max_audits=(_arg0); end

    # source://audited/lib/audited.rb#28
    def store; end

    # Returns the value of attribute store_synthesized_enums.
    #
    # source://audited/lib/audited.rb#8
    def store_synthesized_enums; end

    # Sets the attribute store_synthesized_enums
    #
    # @param value the value to set the attribute store_synthesized_enums to.
    #
    # source://audited/lib/audited.rb#8
    def store_synthesized_enums=(_arg0); end
  end
end

# source://audited/lib/audited/audit.rb#42
class Audited::Audit < ::ActiveRecord::Base
  include ::Audited::Audit::GeneratedAttributeMethods
  include ::Audited::Audit::GeneratedAssociationMethods

  # Return all audits older than the current one.
  #
  # source://audited/lib/audited/audit.rb#69
  def ancestors; end

  # source://audited/lib/audited/audit.rb#49
  def audited_class_names; end

  # source://audited/lib/audited/audit.rb#49
  def audited_class_names=(val); end

  # source://activerecord/7.0.8lib/active_record/autosave_association.rb#160
  def autosave_associated_records_for_associated(*args); end

  # source://activerecord/7.0.8lib/active_record/autosave_association.rb#160
  def autosave_associated_records_for_auditable(*args); end

  # source://activerecord/7.0.8lib/active_record/autosave_association.rb#160
  def autosave_associated_records_for_user(*args); end

  # Returns a hash of the changed attributes with the new values
  #
  # source://audited/lib/audited/audit.rb#83
  def new_attributes; end

  # Returns a hash of the changed attributes with the old values
  #
  # source://audited/lib/audited/audit.rb#90
  def old_attributes; end

  # Return an instance of what the object looked like at this revision. If
  # the object has been destroyed, this will be a new record.
  #
  # source://audited/lib/audited/audit.rb#75
  def revision; end

  # Allows user to undo changes
  #
  # source://audited/lib/audited/audit.rb#97
  def undo; end

  # @private
  #
  # source://audited/lib/audited/audit.rb#126
  def user; end

  # Allows user to be set to either a string or an ActiveRecord object
  #
  # @private
  #
  # source://audited/lib/audited/audit.rb#115
  def user=(user); end

  # source://activerecord/7.0.8lib/active_record/associations/builder/association.rb#103
  def user_as_model; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/association.rb#111
  def user_as_model=(value); end

  # @private
  #
  # source://audited/lib/audited/audit.rb#126
  def user_as_string; end

  # Allows user to be set to either a string or an ActiveRecord object
  #
  # @private
  #
  # source://audited/lib/audited/audit.rb#115
  def user_as_string=(user); end

  private

  # source://audited/lib/audited/audit.rb#187
  def set_audit_user; end

  # source://audited/lib/audited/audit.rb#198
  def set_remote_address; end

  # source://audited/lib/audited/audit.rb#193
  def set_request_uuid; end

  # source://audited/lib/audited/audit.rb#177
  def set_version_number; end

  class << self
    # source://activesupport/7.0.8lib/active_support/callbacks.rb#68
    def __callbacks; end

    # source://activerecord/7.0.8lib/active_record/reflection.rb#11
    def _reflections; end

    # source://activemodel/7.0.8lib/active_model/validations.rb#52
    def _validators; end

    # All audits made during the block called will be recorded as made
    # by +user+. This method is hopefully threadsafe, making it ideal
    # for background operations that require audit information.
    #
    # source://audited/lib/audited/audit.rb#140
    def as_user(user); end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def ascending(*args, **_arg1); end

    # @private
    #
    # source://audited/lib/audited/audit.rb#157
    def assign_revision_attributes(record, attributes); end

    # source://activerecord/7.0.8lib/active_record/attributes.rb#11
    def attributes_to_define_after_schema_loads; end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def auditable_finder(*args, **_arg1); end

    # source://audited/lib/audited/audit.rb#49
    def audited_class_names; end

    # source://audited/lib/audited/audit.rb#49
    def audited_class_names=(val); end

    # Returns the list of classes that are being audited
    #
    # source://audited/lib/audited/audit.rb#133
    def audited_classes; end

    # use created_at as timestamp cache key
    #
    # source://audited/lib/audited/audit.rb#171
    def collection_cache_key(collection = T.unsafe(nil), *_arg1); end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def creates(*args, **_arg1); end

    # source://activerecord/7.0.8lib/active_record/enum.rb#116
    def defined_enums; end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def descending(*args, **_arg1); end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def destroys(*args, **_arg1); end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def from_version(*args, **_arg1); end

    # @private
    #
    # source://audited/lib/audited/audit.rb#149
    def reconstruct_attributes(audits); end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def to_version(*args, **_arg1); end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def up_until(*args, **_arg1); end

    # source://activerecord/7.0.8lib/active_record/scoping/named.rb#174
    def updates(*args, **_arg1); end
  end
end

# source://audited/lib/audited/audit.rb#0
module Audited::Audit::GeneratedAssociationMethods
  # source://activerecord/7.0.8lib/active_record/associations/builder/association.rb#103
  def associated; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/association.rb#111
  def associated=(value); end

  # source://activerecord/7.0.8lib/active_record/associations/builder/belongs_to.rb#132
  def associated_changed?; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/belongs_to.rb#136
  def associated_previously_changed?; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/association.rb#103
  def auditable; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/association.rb#111
  def auditable=(value); end

  # source://activerecord/7.0.8lib/active_record/associations/builder/belongs_to.rb#132
  def auditable_changed?; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/belongs_to.rb#136
  def auditable_previously_changed?; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/singular_association.rb#19
  def reload_associated; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/singular_association.rb#19
  def reload_auditable; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/singular_association.rb#19
  def reload_user; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/association.rb#103
  def user; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/association.rb#111
  def user=(value); end

  # source://activerecord/7.0.8lib/active_record/associations/builder/belongs_to.rb#132
  def user_changed?; end

  # source://activerecord/7.0.8lib/active_record/associations/builder/belongs_to.rb#136
  def user_previously_changed?; end
end

# source://audited/lib/audited/audit.rb#0
module Audited::Audit::GeneratedAttributeMethods; end

# Specify this act if you want changes to your model to be saved in an
# audit table.  This assumes there is an audits table ready.
#
#   class User < ActiveRecord::Base
#     audited
#   end
#
# To store an audit comment set model.audit_comment to your comment before
# a create, update or destroy operation.
#
# See <tt>Audited::Auditor::ClassMethods#audited</tt>
# for configuration options
#
# source://audited/lib/audited/auditor.rb#16
module Audited::Auditor
  extend ::ActiveSupport::Concern

  mixes_in_class_methods ::Audited::Auditor::ClassMethods
end

# source://audited/lib/audited/auditor.rb#423
module Audited::Auditor::AuditedClassMethods
  # All audit operations during the block are recorded as being
  # made by +user+. This is not model specific, the method is a
  # convenience wrapper around
  #
  # @see Audit#as_user.
  #
  # source://audited/lib/audited/auditor.rb#479
  def audit_as(user, &block); end

  # Returns an array of columns that are audited. See non_audited_columns
  #
  # source://audited/lib/audited/auditor.rb#425
  def audited_columns; end

  # source://audited/lib/audited/auditor.rb#483
  def auditing_enabled; end

  # source://audited/lib/audited/auditor.rb#487
  def auditing_enabled=(val); end

  # source://audited/lib/audited/auditor.rb#491
  def default_ignored_attributes; end

  # source://audited/lib/audited/auditor.rb#467
  def disable_auditing; end

  # source://audited/lib/audited/auditor.rb#471
  def enable_auditing; end

  # We have to calculate this here since column_names may not be available when `audited` is called
  #
  # source://audited/lib/audited/auditor.rb#430
  def non_audited_columns; end

  # source://audited/lib/audited/auditor.rb#434
  def non_audited_columns=(columns); end

  # Executes the block with auditing enabled.
  #
  #   Foo.with_auditing do
  #     @foo.save
  #   end
  #
  # source://audited/lib/audited/auditor.rb#459
  def with_auditing; end

  # Executes the block with auditing disabled.
  #
  #   Foo.without_auditing do
  #     @foo.save
  #   end
  #
  # source://audited/lib/audited/auditor.rb#445
  def without_auditing; end

  protected

  # source://audited/lib/audited/auditor.rb#506
  def calculate_non_audited_columns; end

  # source://audited/lib/audited/auditor.rb#516
  def class_auditing_enabled; end

  # source://audited/lib/audited/auditor.rb#497
  def normalize_audited_options; end
end

# source://audited/lib/audited/auditor.rb#105
module Audited::Auditor::AuditedInstanceMethods
  # List of attributes that are audited.
  #
  # source://audited/lib/audited/auditor.rb#174
  def audited_attributes; end

  # Combine multiple audits into one.
  #
  # source://audited/lib/audited/auditor.rb#189
  def combine_audits(audits_to_combine); end

  # Returns a list combined of record audits and associated audits.
  #
  # source://audited/lib/audited/auditor.rb#182
  def own_and_associated_audits; end

  # Get a specific revision specified by the version number, or +:previous+
  # Returns nil for versions greater than revisions count
  #
  # source://audited/lib/audited/auditor.rb#161
  def revision(version); end

  # Find the oldest revision recorded prior to the date/time provided.
  #
  # source://audited/lib/audited/auditor.rb#168
  def revision_at(date_or_time); end

  # Gets an array of the revisions available
  #
  #   user.revisions.each do |revision|
  #     user.name
  #     user.version
  #   end
  #
  # source://audited/lib/audited/auditor.rb#145
  def revisions(from_version = T.unsafe(nil)); end

  # Temporarily turns on auditing while saving.
  #
  # source://audited/lib/audited/auditor.rb#124
  def save_with_auditing; end

  # Temporarily turns off auditing while saving.
  #
  # source://audited/lib/audited/auditor.rb#109
  def save_without_auditing; end

  # Executes the block with the auditing callbacks enabled.
  #
  #   @foo.with_auditing do
  #     @foo.save
  #   end
  #
  # source://audited/lib/audited/auditor.rb#134
  def with_auditing(&block); end

  # Executes the block with the auditing callbacks disabled.
  #
  #   @foo.without_auditing do
  #     @foo.save
  #   end
  #
  # source://audited/lib/audited/auditor.rb#119
  def without_auditing(&block); end

  protected

  # source://audited/lib/audited/auditor.rb#207
  def revision_with(attributes); end

  private

  # source://audited/lib/audited/auditor.rb#330
  def audit_create; end

  # source://audited/lib/audited/auditor.rb#330
  def audit_create_callback; end

  # source://audited/lib/audited/auditor.rb#349
  def audit_destroy; end

  # source://audited/lib/audited/auditor.rb#349
  def audit_destroy_callback; end

  # source://audited/lib/audited/auditor.rb#342
  def audit_touch; end

  # source://audited/lib/audited/auditor.rb#335
  def audit_update; end

  # source://audited/lib/audited/auditor.rb#335
  def audit_update_callback; end

  # source://audited/lib/audited/auditor.rb#234
  def audited_changes(for_touch: T.unsafe(nil)); end

  # source://audited/lib/audited/auditor.rb#402
  def auditing_enabled; end

  # source://audited/lib/audited/auditor.rb#318
  def audits_to(version = T.unsafe(nil)); end

  # source://audited/lib/audited/auditor.rb#383
  def combine_audits_if_needed; end

  # @return [Boolean]
  #
  # source://audited/lib/audited/auditor.rb#376
  def comment_required_state?; end

  # Replace values for given attrs to a placeholder and return modified hash
  #
  # @param audited_changes [Hash] Hash of changes to be saved to audited version record
  # @param attrs [Array<String>] Array of attrs, values of which will be replaced to placeholder value
  # @param placeholder [String] Placeholder to replace original attr values
  #
  # source://audited/lib/audited/auditor.rb#301
  def filter_attr_values(audited_changes: T.unsafe(nil), attrs: T.unsafe(nil), placeholder: T.unsafe(nil)); end

  # source://audited/lib/audited/auditor.rb#289
  def filter_encrypted_attrs(filtered_changes); end

  # source://audited/lib/audited/auditor.rb#263
  def normalize_enum_changes(changes); end

  # source://audited/lib/audited/auditor.rb#370
  def presence_of_audit_comment; end

  # @return [Boolean]
  #
  # source://audited/lib/audited/auditor.rb#314
  def rails_below?(rails_version); end

  # source://audited/lib/audited/auditor.rb#416
  def reconstruct_attributes(audits); end

  # source://audited/lib/audited/auditor.rb#281
  def redact_values(filtered_changes); end

  # source://audited/lib/audited/auditor.rb#391
  def require_comment; end

  # source://audited/lib/audited/auditor.rb#408
  def run_conditional_check(condition, matching: T.unsafe(nil)); end

  # source://audited/lib/audited/auditor.rb#356
  def write_audit(attrs); end
end

# source://audited/lib/audited/auditor.rb#106
Audited::Auditor::AuditedInstanceMethods::REDACTED = T.let(T.unsafe(nil), String)

# source://audited/lib/audited/auditor.rb#19
Audited::Auditor::CALLBACKS = T.let(T.unsafe(nil), Array)

# source://audited/lib/audited/auditor.rb#21
module Audited::Auditor::ClassMethods
  # * +redacted+ - Changes to these fields will be logged, but the values
  #   will not. This is useful, for example, if you wish to audit when a
  #   password is changed, without saving the actual password in the log.
  #   To store values as something other than '[REDACTED]', pass an argument
  #   to the redaction_value option.
  #
  #     class User < ActiveRecord::Base
  #       audited redacted: :password, redaction_value: SecureRandom.uuid
  #     end
  #
  # * +if+ - Only audit the model when the given function returns true
  # * +unless+ - Only audit the model when the given function returns false
  #
  #     class User < ActiveRecord::Base
  #       audited :if => :active?
  #
  #       def active?
  #         self.status == 'active'
  #       end
  #     end
  #
  # source://audited/lib/audited/auditor.rb#61
  def audited(options = T.unsafe(nil)); end

  # source://audited/lib/audited/auditor.rb#100
  def has_associated_audits; end
end

# source://audited/lib/audited/railtie.rb#4
class Audited::Railtie < ::Rails::Railtie; end

# source://audited/lib/audited/sweeper.rb#4
class Audited::Sweeper
  # source://audited/lib/audited/sweeper.rb#13
  def around(controller); end

  # source://audited/lib/audited/sweeper.rb#34
  def controller; end

  # source://audited/lib/audited/sweeper.rb#38
  def controller=(value); end

  # source://audited/lib/audited/sweeper.rb#22
  def current_user; end

  # source://audited/lib/audited/sweeper.rb#26
  def remote_ip; end

  # source://audited/lib/audited/sweeper.rb#30
  def request_uuid; end

  # source://audited/lib/audited/sweeper.rb#11
  def store(*_arg0, **_arg1, &_arg2); end
end

# source://audited/lib/audited/sweeper.rb#5
Audited::Sweeper::STORED_DATA = T.let(T.unsafe(nil), Hash)

# Audit saves the changes to ActiveRecord models.  It has the following attributes:
#
# * <tt>auditable</tt>: the ActiveRecord model that was changed
# * <tt>user</tt>: the user that performed the change; a string or an ActiveRecord model
# * <tt>action</tt>: one of create, update, or delete
# * <tt>audited_changes</tt>: a hash of all the changes
# * <tt>comment</tt>: a comment set with the audit
# * <tt>version</tt>: the version of the model
# * <tt>request_uuid</tt>: a uuid based that allows audits from the same controller request
# * <tt>created_at</tt>: Time that the change was performed
#
# source://audited/lib/audited/audit.rb#18
class Audited::YAMLIfTextColumnType
  class << self
    # source://audited/lib/audited/audit.rb#28
    def dump(obj); end

    # source://audited/lib/audited/audit.rb#20
    def load(obj); end

    # @return [Boolean]
    #
    # source://audited/lib/audited/audit.rb#36
    def text_column?; end
  end
end