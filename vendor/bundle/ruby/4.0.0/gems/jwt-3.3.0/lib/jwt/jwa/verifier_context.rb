# frozen_string_literal: true

module JWT
  module JWA
    # @api private
    class VerifierContext
      attr_reader :jwa

      def initialize(jwa:, keys:)
        @jwa = jwa
        @keys = Array(keys)
      end

      def verify(*args, **kwargs)
        @keys.any? do |key|
          @jwa.verify(*args, **kwargs, verification_key: key)
        end
      end
    end
  end
end
