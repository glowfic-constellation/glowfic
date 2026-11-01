# frozen_string_literal: true

module Aws
  module S3
    # @api private
    class ObjectCopier
      # @param [S3::Object] object
      def initialize(object, options = {})
        @object = object
        @options = options.merge(client: @object.client)
      end

      def copy_from(source, options = {})
        copy_object(source, @object, merge_options(source, options))
      end

      def copy_to(target, options = {})
        copy_object(@object, target, merge_options(target, options))
      end

      private

      def copy_object(source, target, options) # rubocop:disable Metrics/MethodLength
        target_bucket, target_key = copy_target(target)
        options[:bucket] = target_bucket
        options[:key] = target_key
        options[:copy_source] = copy_source(source)
        Aws::Plugins::UserAgent.metric('S3_TRANSFER') do
          if options.delete(:multipart_copy)
            apply_source_client(source, options)
            ObjectMultipartCopier.new(@options).copy(options)
          else
            @object.client.copy_object(options)
          end
        end
      end

      def copy_source(source) # rubocop:disable Metrics/MethodLength
        case source
        when String then source
        when Hash
          src = "#{source[:bucket]}/#{escape(source[:key])}"
          src += "?versionId=#{source[:version_id]}" if source.key?(:version_id)
          src
        when S3::Object, S3::ObjectSummary
          "#{source.bucket_name}/#{escape(source.key)}"
        when S3::ObjectVersion
          "#{source.bucket_name}/#{escape(source.object_key)}?versionId=#{source.id}"
        else
          raise ArgumentError, 'expected source to be an Aws::S3::Object, Hash, or String'
        end
      end

      def copy_target(target)
        case target
        when String then target.match(%r{([^/]+?)/(.+)})[1, 2]
        when Hash then target.values_at(:bucket, :key)
        when S3::Object then [target.bucket_name, target.key]
        else
          raise ArgumentError, 'expected target to be an Aws::S3::Object, Hash, or String'
        end
      end

      def merge_options(source_or_target, options)
        if source_or_target.is_a?(Hash)
          source_or_target.each_with_object(options.dup) do |(key, value), opts|
            opts[key] = value unless %i[bucket key version_id].include?(key)
          end
        else
          options.dup
        end
      end

      def apply_source_client(source, options) # rubocop:disable Metrics/AbcSize
        options[:copy_source_client] ||= source.client if source.respond_to?(:client)

        if options[:copy_source_region]
          config = @object.client.config
          config = config.each_pair.with_object({}) { |(k, v), h| h[k] = v unless v.nil? }
          config[:region] = options.delete(:copy_source_region)
          options[:copy_source_client] ||= S3::Client.new(config)
        end

        options[:copy_source_client] ||= @object.client
      end

      def escape(str)
        Seahorse::Util.uri_path_escape(str)
      end
    end
  end
end
