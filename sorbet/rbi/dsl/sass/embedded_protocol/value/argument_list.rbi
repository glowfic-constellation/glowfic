# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Sass::EmbeddedProtocol::Value::ArgumentList`.
# Please instead update this file by running `bin/tapioca dsl Sass::EmbeddedProtocol::Value::ArgumentList`.


class Sass::EmbeddedProtocol::Value::ArgumentList < Google::Protobuf::AbstractMessage
  sig do
    params(
      contents: T.nilable(T.any(Google::Protobuf::RepeatedField[Sass::EmbeddedProtocol::Value], T::Array[Sass::EmbeddedProtocol::Value])),
      id: T.nilable(Integer),
      keywords: T.nilable(T.any(Google::Protobuf::Map[String, Sass::EmbeddedProtocol::Value], T::Hash[String, Sass::EmbeddedProtocol::Value])),
      separator: T.nilable(T.any(Symbol, Integer))
    ).void
  end
  def initialize(contents: T.unsafe(nil), id: nil, keywords: T.unsafe(nil), separator: nil); end

  sig { void }
  def clear_contents; end

  sig { void }
  def clear_id; end

  sig { void }
  def clear_keywords; end

  sig { void }
  def clear_separator; end

  sig { returns(Google::Protobuf::RepeatedField[Sass::EmbeddedProtocol::Value]) }
  def contents; end

  sig { params(value: Google::Protobuf::RepeatedField[Sass::EmbeddedProtocol::Value]).void }
  def contents=(value); end

  sig { returns(Integer) }
  def id; end

  sig { params(value: Integer).void }
  def id=(value); end

  sig { returns(Google::Protobuf::Map[String, Sass::EmbeddedProtocol::Value]) }
  def keywords; end

  sig { params(value: Google::Protobuf::Map[String, Sass::EmbeddedProtocol::Value]).void }
  def keywords=(value); end

  sig { returns(T.any(Symbol, Integer)) }
  def separator; end

  sig { params(value: T.any(Symbol, Integer)).void }
  def separator=(value); end
end
