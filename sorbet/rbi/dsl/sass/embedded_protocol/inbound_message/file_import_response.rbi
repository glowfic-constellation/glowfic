# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Sass::EmbeddedProtocol::InboundMessage::FileImportResponse`.
# Please instead update this file by running `bin/tapioca dsl Sass::EmbeddedProtocol::InboundMessage::FileImportResponse`.


class Sass::EmbeddedProtocol::InboundMessage::FileImportResponse < Google::Protobuf::AbstractMessage
  sig do
    params(
      containing_url_unused: T.nilable(T::Boolean),
      error: T.nilable(String),
      file_url: T.nilable(String),
      id: T.nilable(Integer)
    ).void
  end
  def initialize(containing_url_unused: nil, error: nil, file_url: nil, id: nil); end

  sig { void }
  def clear_containing_url_unused; end

  sig { void }
  def clear_error; end

  sig { void }
  def clear_file_url; end

  sig { void }
  def clear_id; end

  sig { returns(T::Boolean) }
  def containing_url_unused; end

  sig { params(value: T::Boolean).void }
  def containing_url_unused=(value); end

  sig { returns(String) }
  def error; end

  sig { params(value: String).void }
  def error=(value); end

  sig { returns(String) }
  def file_url; end

  sig { params(value: String).void }
  def file_url=(value); end

  sig { returns(Object) }
  def has_error?; end

  sig { returns(Object) }
  def has_file_url?; end

  sig { returns(Integer) }
  def id; end

  sig { params(value: Integer).void }
  def id=(value); end

  sig { returns(T.nilable(Symbol)) }
  def result; end
end
