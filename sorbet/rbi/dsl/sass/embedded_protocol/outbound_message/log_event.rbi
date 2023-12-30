# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Sass::EmbeddedProtocol::OutboundMessage::LogEvent`.
# Please instead update this file by running `bin/tapioca dsl Sass::EmbeddedProtocol::OutboundMessage::LogEvent`.


class Sass::EmbeddedProtocol::OutboundMessage::LogEvent < Google::Protobuf::AbstractMessage
  sig do
    params(
      deprecation_type: T.nilable(String),
      formatted: T.nilable(String),
      message: T.nilable(String),
      span: T.nilable(Sass::EmbeddedProtocol::SourceSpan),
      stack_trace: T.nilable(String),
      type: T.nilable(T.any(Symbol, Integer))
    ).void
  end
  def initialize(deprecation_type: nil, formatted: nil, message: nil, span: nil, stack_trace: nil, type: nil); end

  sig { returns(T.nilable(Symbol)) }
  def _deprecation_type; end

  sig { returns(T.nilable(Symbol)) }
  def _span; end

  sig { void }
  def clear_deprecation_type; end

  sig { void }
  def clear_formatted; end

  sig { void }
  def clear_message; end

  sig { void }
  def clear_span; end

  sig { void }
  def clear_stack_trace; end

  sig { void }
  def clear_type; end

  sig { returns(String) }
  def deprecation_type; end

  sig { params(value: String).void }
  def deprecation_type=(value); end

  sig { returns(String) }
  def formatted; end

  sig { params(value: String).void }
  def formatted=(value); end

  sig { returns(Object) }
  def has_deprecation_type?; end

  sig { returns(Object) }
  def has_span?; end

  sig { returns(String) }
  def message; end

  sig { params(value: String).void }
  def message=(value); end

  sig { returns(T.nilable(Sass::EmbeddedProtocol::SourceSpan)) }
  def span; end

  sig { params(value: T.nilable(Sass::EmbeddedProtocol::SourceSpan)).void }
  def span=(value); end

  sig { returns(String) }
  def stack_trace; end

  sig { params(value: String).void }
  def stack_trace=(value); end

  sig { returns(T.any(Symbol, Integer)) }
  def type; end

  sig { params(value: T.any(Symbol, Integer)).void }
  def type=(value); end
end
