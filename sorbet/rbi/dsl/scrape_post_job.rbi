# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `ScrapePostJob`.
# Please instead update this file by running `bin/tapioca dsl ScrapePostJob`.

class ScrapePostJob
  class << self
    sig do
      params(
        url: T.untyped,
        board_id: T.untyped,
        section_id: T.untyped,
        status: T.untyped,
        threaded: T.untyped,
        importer_id: T.untyped
      ).returns(T.any(ScrapePostJob, FalseClass))
    end
    def perform_later(url, board_id, section_id, status, threaded, importer_id); end

    sig do
      params(
        url: T.untyped,
        board_id: T.untyped,
        section_id: T.untyped,
        status: T.untyped,
        threaded: T.untyped,
        importer_id: T.untyped
      ).returns(T.untyped)
    end
    def perform_now(url, board_id, section_id, status, threaded, importer_id); end
  end
end