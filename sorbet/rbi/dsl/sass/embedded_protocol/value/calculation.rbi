# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Sass::EmbeddedProtocol::Value::Calculation`.
# Please instead update this file by running `bin/tapioca dsl Sass::EmbeddedProtocol::Value::Calculation`.


class Sass::EmbeddedProtocol::Value::Calculation < Google::Protobuf::AbstractMessage
  sig do
    params(
      arguments: T.nilable(T.any(Google::Protobuf::RepeatedField[Sass::EmbeddedProtocol::Value::Calculation::CalculationValue], T::Array[Sass::EmbeddedProtocol::Value::Calculation::CalculationValue])),
      name: T.nilable(String)
    ).void
  end
  def initialize(arguments: T.unsafe(nil), name: nil); end

  sig { returns(Google::Protobuf::RepeatedField[Sass::EmbeddedProtocol::Value::Calculation::CalculationValue]) }
  def arguments; end

  sig do
    params(
      value: Google::Protobuf::RepeatedField[Sass::EmbeddedProtocol::Value::Calculation::CalculationValue]
    ).void
  end
  def arguments=(value); end

  sig { void }
  def clear_arguments; end

  sig { void }
  def clear_name; end

  sig { returns(String) }
  def name; end

  sig { params(value: String).void }
  def name=(value); end
end
