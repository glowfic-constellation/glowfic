# typed: true
module Tapioca
  module Compilers
    class WillPaginate < Tapioca::Dsl::Compiler
      ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

      # @override
      #: -> Enumerable[Module]
      def self.gather_constants
        ActiveRecord::Base.descendants.reject(&:abstract_class?)
      end

      #: -> RBI::Scope
      def model
        @model ||= T.let(
          root.create_path(constant),
          T.nilable(RBI::Scope),
        )
      end

      #: -> RBI::Scope
      def common_relation_methods_module
        @common_relation_methods_module ||= T.let(
          model.create_module("CommonRelationMethods"),
          T.nilable(RBI::Scope),
        )
      end

      # @override
      #: -> void
      def decorate
        create_relation_methods
      end

      def create_relation_methods
        common_relation_methods_module.create_method(
          "paginate",
          parameters: [
            create_param("options", type: "T::Hash[Symbol, Integer]"),
          ],
          return_type: "PrivateRelation",
        )
      end
    end
  end
end
