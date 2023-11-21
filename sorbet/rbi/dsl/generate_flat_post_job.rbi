# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `GenerateFlatPostJob`.
# Please instead update this file by running `bin/tapioca dsl GenerateFlatPostJob`.

class GenerateFlatPostJob
  class << self
    sig { params(post_id: T.untyped).returns(T.any(GenerateFlatPostJob, FalseClass)) }
    def perform_later(post_id); end

    sig { params(post_id: T.untyped).returns(T.untyped) }
    def perform_now(post_id); end
  end
end
