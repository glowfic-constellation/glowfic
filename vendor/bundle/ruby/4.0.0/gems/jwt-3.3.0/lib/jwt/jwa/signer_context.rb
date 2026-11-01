# frozen_string_literal: true

module JWT
  module JWA
    # @api private
    class SignerContext
      attr_reader :jwa

      def initialize(jwa:, key:)
        @jwa = jwa
        @key = key
      end

      def sign(*args, **kwargs)
        @jwa.sign(*args, **kwargs, signing_key: @key)
      end
    end
  end
end
