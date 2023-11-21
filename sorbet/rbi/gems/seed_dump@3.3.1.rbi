# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `seed_dump` gem.
# Please instead update this file by running `bin/tapioca gem seed_dump`.

# source://seed_dump/lib/seed_dump/dump_methods/enumeration.rb#1
class SeedDump
  extend ::SeedDump::Environment
  extend ::SeedDump::DumpMethods::Enumeration
  extend ::SeedDump::DumpMethods
end

# source://seed_dump/lib/seed_dump/dump_methods/enumeration.rb#2
module SeedDump::DumpMethods
  include ::SeedDump::DumpMethods::Enumeration

  # source://seed_dump/lib/seed_dump/dump_methods.rb#5
  def dump(records, options = T.unsafe(nil)); end

  private

  # source://seed_dump/lib/seed_dump/dump_methods.rb#102
  def active_record_import_options(options); end

  # source://seed_dump/lib/seed_dump/dump_methods.rb#108
  def attribute_names(records, options); end

  # source://seed_dump/lib/seed_dump/dump_methods.rb#33
  def dump_attribute_new(attribute, value, options); end

  # source://seed_dump/lib/seed_dump/dump_methods.rb#18
  def dump_record(record, options); end

  # source://seed_dump/lib/seed_dump/dump_methods.rb#118
  def model_for(records); end

  # source://seed_dump/lib/seed_dump/dump_methods.rb#60
  def open_io(options); end

  # source://seed_dump/lib/seed_dump/dump_methods.rb#54
  def range_to_string(object); end

  # source://seed_dump/lib/seed_dump/dump_methods.rb#37
  def value_to_s(value); end

  # source://seed_dump/lib/seed_dump/dump_methods.rb#70
  def write_records_to_io(records, io, options); end
end

# source://seed_dump/lib/seed_dump/dump_methods/enumeration.rb#3
module SeedDump::DumpMethods::Enumeration
  # source://seed_dump/lib/seed_dump/dump_methods/enumeration.rb#4
  def active_record_enumeration(records, io, options); end

  # source://seed_dump/lib/seed_dump/dump_methods/enumeration.rb#56
  def batch_params_from(records, options); end

  # source://seed_dump/lib/seed_dump/dump_methods/enumeration.rb#66
  def batch_size_from(records, options); end

  # source://seed_dump/lib/seed_dump/dump_methods/enumeration.rb#35
  def enumerable_enumeration(records, io, options); end
end

# source://seed_dump/lib/seed_dump/environment.rb#2
module SeedDump::Environment
  # source://seed_dump/lib/seed_dump/environment.rb#4
  def dump_using_environment(env = T.unsafe(nil)); end

  private

  # Internal: Parses a Boolean from the given value.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#135
  def parse_boolean_value(value); end

  # Internal: Returns a Boolean indicating whether the value for the "APPEND"
  # key in the given Hash is equal to the String "true" (ignoring case),
  # false if no value exists.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#84
  def retrieve_append_value(env); end

  # Internal: Retrieves an Integer from the value for the "BATCH_SIZE" key in
  # the given Hash, and nil if no such key exists.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#124
  def retrieve_batch_size_value(env); end

  # Internal: Retrieves an Array of Symbols from the value for the "EXCLUDE"
  # key from the given Hash, and nil if no such key exists.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#112
  def retrieve_exclude_value(env); end

  # Internal: Retrieves the value for the "FILE" key from the given Hash, and
  # 'db/seeds.rb' if no such key exists.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#118
  def retrieve_file_value(env); end

  # Internal: Returns a Boolean indicating whether the value for the "IMPORT"
  # key in the given Hash is equal to the String "true" (ignoring case),
  # false if  no value exists.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#91
  def retrieve_import_value(env); end

  # Internal: Retrieves an Integer from the value for the given key in
  # the given Hash, and nil if no such key exists.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#130
  def retrieve_integer_value(key, hash); end

  # Internal: Retrieves an Integer from the value for the "LIMIT" key in the
  # given Hash, and nil if no such key exists.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#106
  def retrieve_limit_value(env); end

  # Internal: Retrieves an Array of Active Record model class constants to be
  # dumped.
  #
  # If a "MODEL" or "MODELS" environment variable is specified, there will be
  # an attempt to parse the environment variable String by splitting it on
  # commmas and then converting it to constant.
  #
  # Model classes that do not have corresponding database tables or database
  # records will be filtered out, as will model classes internal to Active
  # Record.
  #
  # env - Hash of environment variables from which to parse Active Record
  #       model classes. The Hash is not optional but the "MODEL" and "MODELS"
  #       keys are optional.
  #
  # Returns the Array of Active Record model classes to be dumped.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#49
  def retrieve_models(env); end

  # Internal: Retrieves an Array of Class constants parsed from the value for
  # the "MODELS_EXCLUDE" key in the given Hash, and an empty Array if such
  # key exists.
  #
  # source://seed_dump/lib/seed_dump/environment.rb#98
  def retrieve_models_exclude(env); end
end

# Internal: Array of Strings corresponding to Active Record model class names
# that should be excluded from the dump.
#
# source://seed_dump/lib/seed_dump/environment.rb#30
SeedDump::Environment::ACTIVE_RECORD_INTERNAL_MODELS = T.let(T.unsafe(nil), Array)

# source://seed_dump/lib/seed_dump/railtie.rb#2
class SeedDump::Railtie < ::Rails::Railtie; end