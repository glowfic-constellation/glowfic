# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Sass::EmbeddedProtocol::Value::HostFunction`.
# Please instead update this file by running `bin/tapioca dsl Sass::EmbeddedProtocol::Value::HostFunction`.


class Sass::EmbeddedProtocol::Value::HostFunction < Google::Protobuf::AbstractMessage
  sig { params(id: T.nilable(Integer), signature: T.nilable(String)).void }
  def initialize(id: nil, signature: nil); end

  sig { void }
  def clear_id; end

  sig { void }
  def clear_signature; end

  sig { returns(Integer) }
  def id; end

  sig { params(value: Integer).void }
  def id=(value); end

  sig { returns(String) }
  def signature; end

  sig { params(value: String).void }
  def signature=(value); end
end
