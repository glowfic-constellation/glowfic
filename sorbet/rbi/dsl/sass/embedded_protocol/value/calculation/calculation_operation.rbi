# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Sass::EmbeddedProtocol::Value::Calculation::CalculationOperation`.
# Please instead update this file by running `bin/tapioca dsl Sass::EmbeddedProtocol::Value::Calculation::CalculationOperation`.


class Sass::EmbeddedProtocol::Value::Calculation::CalculationOperation < Google::Protobuf::AbstractMessage
  sig do
    params(
      left: T.nilable(Sass::EmbeddedProtocol::Value::Calculation::CalculationValue),
      operator: T.nilable(T.any(Symbol, Integer)),
      right: T.nilable(Sass::EmbeddedProtocol::Value::Calculation::CalculationValue)
    ).void
  end
  def initialize(left: nil, operator: nil, right: nil); end

  sig { void }
  def clear_left; end

  sig { void }
  def clear_operator; end

  sig { void }
  def clear_right; end

  sig { returns(Object) }
  def has_left?; end

  sig { returns(Object) }
  def has_right?; end

  sig { returns(T.nilable(Sass::EmbeddedProtocol::Value::Calculation::CalculationValue)) }
  def left; end

  sig { params(value: T.nilable(Sass::EmbeddedProtocol::Value::Calculation::CalculationValue)).void }
  def left=(value); end

  sig { returns(T.any(Symbol, Integer)) }
  def operator; end

  sig { params(value: T.any(Symbol, Integer)).void }
  def operator=(value); end

  sig { returns(T.nilable(Sass::EmbeddedProtocol::Value::Calculation::CalculationValue)) }
  def right; end

  sig { params(value: T.nilable(Sass::EmbeddedProtocol::Value::Calculation::CalculationValue)).void }
  def right=(value); end
end
