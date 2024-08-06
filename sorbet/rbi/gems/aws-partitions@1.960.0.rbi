# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `aws-partitions` gem.
# Please instead update this file by running `bin/tapioca gem aws-partitions`.


# source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#3
module Aws
  class << self
    # source://aws-sdk-core/3.201.3/lib/aws-sdk-core.rb#138
    def config; end

    # source://aws-sdk-core/3.201.3/lib/aws-sdk-core.rb#141
    def config=(config); end

    # source://aws-sdk-core/3.201.3/lib/aws-sdk-core.rb#200
    def eager_autoload!(*args); end

    # source://aws-sdk-core/3.201.3/lib/aws-sdk-core.rb#193
    def empty_connection_pools!; end

    # source://aws-sdk-core/3.201.3/lib/aws-sdk-core.rb#150
    def partition(partition_name); end

    # source://aws-sdk-core/3.201.3/lib/aws-sdk-core.rb#155
    def partitions; end

    # source://aws-sdk-core/3.201.3/lib/aws-sdk-core.rb#131
    def shared_config; end

    # source://aws-sdk-core/3.201.3/lib/aws-sdk-core.rb#170
    def use_bundled_cert!; end
  end
end

# A {Partition} is a group of AWS {Region} and {Service} objects. You
# can use a partition to determine what services are available in a region,
# or what regions a service is available in.
#
# ## Partitions
#
# **AWS accounts are scoped to a single partition**. You can get a partition
# by name. Valid partition names include:
#
# * `"aws"` - Public AWS partition
# * `"aws-cn"` - AWS China
# * `"aws-us-gov"` - AWS GovCloud
#
# To get a partition by name:
#
#     aws = Aws::Partitions.partition('aws')
#
# You can also enumerate all partitions:
#
#     Aws::Partitions.each do |partition|
#       puts partition.name
#     end
#
# ## Regions
#
# A {Partition} is divided up into one or more regions. For example, the
# "aws" partition contains, "us-east-1", "us-west-1", etc. You can get
# a region by name. Calling {Partition#region} will return an instance
# of {Region}.
#
#     region = Aws::Partitions.partition('aws').region('us-west-2')
#     region.name
#     #=> "us-west-2"
#
# You can also enumerate all regions within a partition:
#
#     Aws::Partitions.partition('aws').regions.each do |region|
#       puts region.name
#     end
#
# Each {Region} object has a name, description and a list of services
# available to that region:
#
#     us_west_2 = Aws::Partitions.partition('aws').region('us-west-2')
#
#     us_west_2.name #=> "us-west-2"
#     us_west_2.description #=> "US West (Oregon)"
#     us_west_2.partition_name "aws"
#     us_west_2.services #=> #<Set: {"APIGateway", "AutoScaling", ... }
#
# To know if a service is available within a region, you can call `#include?`
# on the set of service names:
#
#     region.services.include?('DynamoDB') #=> true/false
#
# The service name should be the service's module name as used by
# the AWS SDK for Ruby. To find the complete list of supported
# service names, see {Partition#services}.
#
# Its also possible to enumerate every service for every region in
# every partition.
#
#     Aws::Partitions.partitions.each do |partition|
#       partition.regions.each do |region|
#         region.services.each do |service_name|
#           puts "#{partition.name} -> #{region.name} -> #{service_name}"
#         end
#       end
#     end
#
# ## Services
#
# A {Partition} has a list of services available. You can get a
# single {Service} by name:
#
#     Aws::Partitions.partition('aws').service('DynamoDB')
#
# You can also enumerate all services in a partition:
#
#     Aws::Partitions.partition('aws').services.each do |service|
#       puts service.name
#     end
#
# Each {Service} object has a name, and information about regions
# that service is available in.
#
#     service.name #=> "DynamoDB"
#     service.partition_name #=> "aws"
#     service.regions #=> #<Set: {"us-east-1", "us-west-1", ... }
#
# Some services have multiple regions, and others have a single partition
# wide region. For example, {Aws::IAM} has a single region in the "aws"
# partition. The {Service#regionalized?} method indicates when this is
# the case.
#
#     iam = Aws::Partitions.partition('aws').service('IAM')
#
#     iam.regionalized? #=> false
#     service.partition_region #=> "aws-global"
#
# Its also possible to enumerate every region for every service in
# every partition.
#
#     Aws::Partitions.partitions.each do |partition|
#       partition.services.each do |service|
#         service.regions.each do |region_name|
#           puts "#{partition.name} -> #{region_name} -> #{service.name}"
#         end
#       end
#     end
#
# ## Service Names
#
# {Service} names are those used by the the AWS SDK for Ruby. They
# correspond to the service's module.
#
# source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#4
module Aws::Partitions
  extend ::Enumerable

  class << self
    # @api private For internal use only.
    # @param new_partitions [Hash]
    #
    # source://aws-partitions//lib/aws-partitions.rb#191
    def add(new_partitions); end

    # @api private For internal use only.
    #
    # source://aws-partitions//lib/aws-partitions.rb#205
    def clear; end

    # @api private
    # @return [Hash]
    #
    # source://aws-partitions//lib/aws-partitions.rb#232
    def default_metadata; end

    # @api private
    # @return [PartitionList]
    #
    # source://aws-partitions//lib/aws-partitions.rb#212
    def default_partition_list; end

    # @api private
    # @return [Hash]
    #
    # source://aws-partitions//lib/aws-partitions.rb#222
    def defaults; end

    # @return [Enumerable<Partition>]
    #
    # source://aws-partitions//lib/aws-partitions.rb#136
    def each(&block); end

    # @api private For Internal use only
    # @param partition_metadata [Hash]
    #
    # source://aws-partitions//lib/aws-partitions.rb#200
    def merge_metadata(partition_metadata); end

    # Return the partition with the given name. A partition describes
    # the services and regions available in that partition.
    #
    #     aws = Aws::Partitions.partition('aws')
    #
    #     puts "Regions available in the aws partition:\n"
    #     aws.regions.each do |region|
    #       puts region.name
    #     end
    #
    #     puts "Services available in the aws partition:\n"
    #     aws.services.each do |services|
    #       puts services.name
    #     end
    #
    # @param name [String] The name of the partition to return.
    #   Valid names include "aws", "aws-cn", and "aws-us-gov".
    # @raise [ArgumentError] Raises an `ArgumentError` if a partition is
    #   not found with the given name. The error message contains a list
    #   of valid partition names.
    # @return [Partition]
    #
    # source://aws-partitions//lib/aws-partitions.rb#163
    def partition(name); end

    # Returns an array with every partitions. A partition describes
    # the services and regions available in that partition.
    #
    #     Aws::Partitions.partitions.each do |partition|
    #
    #       puts "Regions available in #{partition.name}:\n"
    #       partition.regions.each do |region|
    #         puts region.name
    #       end
    #
    #       puts "Services available in #{partition.name}:\n"
    #       partition.services.each do |service|
    #         puts service.name
    #       end
    #     end
    #
    # @return [Enumerable<Partition>] Returns an enumerable of all
    #   known partitions.
    #
    # source://aws-partitions//lib/aws-partitions.rb#185
    def partitions; end

    # @api private For internal use only.
    # @return [Hash<String,String>] Returns a map of service module names
    #   to their id as used in the endpoints.json document.
    #
    # source://aws-partitions//lib/aws-partitions.rb#243
    def service_ids; end
  end
end

# @api private
#
# source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#6
class Aws::Partitions::EndpointProvider
  # Intentionally marked private. The format of the endpoint rules
  # is an implementation detail.
  #
  # @api private
  # @return [EndpointProvider] a new instance of EndpointProvider
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#31
  def initialize(rules); end

  # @api private Use the static class methods instead.
  # @option variants
  # @option variants
  # @param region [String] The region used to fetch the partition.
  # @param service [String] Used only if dualstack is true. Used to find a
  #   DNS suffix for a specific service.
  # @param variants [Hash] Endpoint variants such as 'fips' or 'dualstack'
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#73
  def dns_suffix_for(region, service, variants); end

  # @api private Use the static class methods instead.
  # @option variants
  # @option variants
  # @param region [String] The region for the client.
  # @param service [String] The endpoint prefix for the service, e.g.
  #   "monitoring" for cloudwatch.
  # @param sts_regional_endpoints [String] [STS only] Whether to use
  #   `legacy` (global endpoint for legacy regions) or `regional` mode for
  #   using regional endpoint for supported regions except 'aws-global'
  # @param variants [Hash] Endpoint variants such as 'fips' or 'dualstack'
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#46
  def resolve(region, service, sts_regional_endpoints, variants); end

  # @api private Use the static class methods instead.
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#51
  def signing_region(region, service, sts_regional_endpoints); end

  # @api private Use the static class methods instead.
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#57
  def signing_service(region, service); end

  private

  # returns a callable that takes a region
  # and returns true if the service is global
  #
  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#178
  def build_is_global_fn(sts_regional_endpoints = T.unsafe(nil)); end

  # @api private
  # @return [Boolean]
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#83
  def configured_variants?(variants); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#192
  def credential_scope(region, service, is_global_fn); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#238
  def default_partition; end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#125
  def endpoint_for(region, service, is_global_fn, variants); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#141
  def endpoint_no_variants_for(region, service, is_global_fn); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#133
  def endpoint_with_variants_for(region, service, variants); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#87
  def fetch_variant(cfg, tags); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#212
  def get_partition(region_or_partition); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#219
  def partition_containing_region(region); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#234
  def partition_matching_name(partition_name); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#225
  def partition_matching_region(region); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#92
  def resolve_variant(region, service, config_variants); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#117
  def validate_variant!(config_variants, resolved_variant); end

  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#171
  def warn_deprecation(service, region); end

  class << self
    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#256
    def dns_suffix_for(region, service = T.unsafe(nil), variants = T.unsafe(nil)); end

    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#244
    def resolve(region, service, sts_endpoint = T.unsafe(nil), variants = T.unsafe(nil)); end

    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#248
    def signing_region(region, service, sts_regional_endpoints = T.unsafe(nil)); end

    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#252
    def signing_service(region, service); end

    private

    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#262
    def default_provider; end
  end
end

# When sts_regional_endpoint is set to `legacy`, the endpoint
# pattern stays global for the following regions:
#
# @api private
#
# source://aws-partitions//lib/aws-partitions/endpoint_provider.rb#9
Aws::Partitions::EndpointProvider::STS_LEGACY_REGIONS = T.let(T.unsafe(nil), Array)

# source://aws-partitions//lib/aws-partitions/partition.rb#5
class Aws::Partitions::Partition
  # @api private
  # @option options
  # @option options
  # @option options
  # @param options [Hash] a customizable set of options
  # @return [Partition] a new instance of Partition
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#10
  def initialize(options = T.unsafe(nil)); end

  # @return [Metadata] The metadata for the partition.
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#25
  def metadata; end

  # @return [String] The partition name, e.g. "aws", "aws-cn", "aws-us-gov".
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#19
  def name; end

  # @param region_name [String] The name of the region, e.g. "us-east-1".
  # @raise [ArgumentError] Raises `ArgumentError` for unknown region name.
  # @return [Region]
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#30
  def region(region_name); end

  # @param region_name [String] The name of the region, e.g. "us-east-1".
  # @return [Boolean] true if the region is in the partition.
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#47
  def region?(region_name); end

  # @return [String] The regex representing the region format.
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#22
  def region_regex; end

  # @return [Array<Region>]
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#41
  def regions; end

  # @param service_name [String] The service module name.
  # @raise [ArgumentError] Raises `ArgumentError` for unknown service name.
  # @return [Service]
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#54
  def service(service_name); end

  # @param service_name [String] The service module name.
  # @return [Boolean] true if the service is in the partition.
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#71
  def service?(service_name); end

  # @return [Array<Service>]
  #
  # source://aws-partitions//lib/aws-partitions/partition.rb#65
  def services; end

  class << self
    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/partition.rb#77
    def build(partition); end

    private

    # @param partition [Hash]
    # @return [Hash<String,Region>]
    #
    # source://aws-partitions//lib/aws-partitions/partition.rb#90
    def build_regions(partition); end

    # @param partition [Hash]
    # @return [Hash<String,Service>]
    #
    # source://aws-partitions//lib/aws-partitions/partition.rb#102
    def build_services(partition); end
  end
end

# source://aws-partitions//lib/aws-partitions/partition_list.rb#5
class Aws::Partitions::PartitionList
  include ::Enumerable

  # @return [PartitionList] a new instance of PartitionList
  #
  # source://aws-partitions//lib/aws-partitions/partition_list.rb#9
  def initialize; end

  # @api private
  # @param partition [Partition]
  #
  # source://aws-partitions//lib/aws-partitions/partition_list.rb#37
  def add_partition(partition); end

  # Removed all partitions.
  #
  # @api private
  #
  # source://aws-partitions//lib/aws-partitions/partition_list.rb#80
  def clear; end

  # @return [Enumerator<Partition>]
  #
  # source://aws-partitions//lib/aws-partitions/partition_list.rb#14
  def each(&block); end

  # @api private
  # @param partitions_metadata [Partition]
  #
  # source://aws-partitions//lib/aws-partitions/partition_list.rb#47
  def merge_metadata(partitions_metadata); end

  # @param partition_name [String]
  # @return [Partition]
  #
  # source://aws-partitions//lib/aws-partitions/partition_list.rb#20
  def partition(partition_name); end

  # @return [Array<Partition>]
  #
  # source://aws-partitions//lib/aws-partitions/partition_list.rb#31
  def partitions; end

  private

  # source://aws-partitions//lib/aws-partitions/partition_list.rb#86
  def build_metadata_regions(partition_name, metadata_regions, existing = T.unsafe(nil)); end

  class << self
    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/partition_list.rb#104
    def build(partitions); end
  end
end

# source://aws-partitions//lib/aws-partitions/region.rb#7
class Aws::Partitions::Region
  # @api private
  # @option options
  # @option options
  # @option options
  # @option options
  # @param options [Hash] a customizable set of options
  # @return [Region] a new instance of Region
  #
  # source://aws-partitions//lib/aws-partitions/region.rb#14
  def initialize(options = T.unsafe(nil)); end

  # @return [String] A short description of this region.
  #
  # source://aws-partitions//lib/aws-partitions/region.rb#25
  def description; end

  # @return [String] The name of this region, e.g. "us-east-1".
  #
  # source://aws-partitions//lib/aws-partitions/region.rb#22
  def name; end

  # @return [String] The partition this region exists in, e.g. "aws",
  #   "aws-cn", "aws-us-gov".
  #
  # source://aws-partitions//lib/aws-partitions/region.rb#29
  def partition_name; end

  # @return [Set<String>] The list of services available in this region.
  #   Service names are the module names as used by the AWS SDK
  #   for Ruby.
  #
  # source://aws-partitions//lib/aws-partitions/region.rb#34
  def services; end

  class << self
    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/region.rb#39
    def build(region_name, region, partition); end

    private

    # source://aws-partitions//lib/aws-partitions/region.rb#50
    def region_services(region_name, partition); end

    # @return [Boolean]
    #
    # source://aws-partitions//lib/aws-partitions/region.rb#61
    def service_in_region?(svc, region_name); end
  end
end

# source://aws-partitions//lib/aws-partitions/service.rb#7
class Aws::Partitions::Service
  # @api private
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @param options [Hash] a customizable set of options
  # @return [Service] a new instance of Service
  #
  # source://aws-partitions//lib/aws-partitions/service.rb#15
  def initialize(options = T.unsafe(nil)); end

  # @return [Set<String>] The Dualstack compatible regions this service is
  #   available in. Regions are scoped to the partition.
  #
  # source://aws-partitions//lib/aws-partitions/service.rb#42
  def dualstack_regions; end

  # @return [Set<String>] The FIPS compatible regions this service is
  #   available in. Regions are scoped to the partition.
  #
  # source://aws-partitions//lib/aws-partitions/service.rb#38
  def fips_regions; end

  # @return [String] The name of this service. The name is the module
  #   name as used by the AWS SDK for Ruby.
  #
  # source://aws-partitions//lib/aws-partitions/service.rb#27
  def name; end

  # @return [String] The partition name, e.g "aws", "aws-cn", "aws-us-gov".
  #
  # source://aws-partitions//lib/aws-partitions/service.rb#30
  def partition_name; end

  # @return [String, nil] The global patition endpoint for this service.
  #   May be `nil`.
  #
  # source://aws-partitions//lib/aws-partitions/service.rb#46
  def partition_region; end

  # Returns `false` if the service operates with a single global
  # endpoint for the current partition, returns `true` if the service
  # is available in multiple regions.
  #
  # Some services have both a partition endpoint and regional endpoints.
  #
  # @return [Boolean]
  #
  # source://aws-partitions//lib/aws-partitions/service.rb#55
  def regionalized?; end

  # @return [Set<String>] The regions this service is available in.
  #   Regions are scoped to the partition.
  #
  # source://aws-partitions//lib/aws-partitions/service.rb#34
  def regions; end

  class << self
    # @api private
    #
    # source://aws-partitions//lib/aws-partitions/service.rb#62
    def build(service_name, service, partition); end

    private

    # source://aws-partitions//lib/aws-partitions/service.rb#97
    def partition_region(service); end

    # source://aws-partitions//lib/aws-partitions/service.rb#76
    def regions(service, partition); end

    # source://aws-partitions//lib/aws-partitions/service.rb#82
    def variant_regions(variant_name, service, partition); end
  end
end
