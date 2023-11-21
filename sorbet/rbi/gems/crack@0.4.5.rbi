# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `crack` gem.
# Please instead update this file by running `bin/tapioca gem crack`.

# source://crack/lib/crack/xml.rb#196
module Crack; end

# source://crack/lib/crack/xml.rb#197
class Crack::REXMLParser
  class << self
    # source://crack/lib/crack/xml.rb#198
    def parse(xml); end
  end
end

# source://crack/lib/crack/xml.rb#225
class Crack::XML
  class << self
    # source://crack/lib/crack/xml.rb#234
    def parse(xml); end

    # source://crack/lib/crack/xml.rb#226
    def parser; end

    # source://crack/lib/crack/xml.rb#230
    def parser=(parser); end
  end
end

# This is a slighly modified version of the XMLUtilityNode from
# http://merb.devjavu.com/projects/merb/ticket/95 (has.sox@gmail.com)
# It's mainly just adding vowels, as I ht cd wth n vwls :)
# This represents the hard part of the work, all I did was change the
# underlying parser.
#
# source://crack/lib/crack/xml.rb#23
class REXMLUtilityNode
  # @return [REXMLUtilityNode] a new instance of REXMLUtilityNode
  #
  # source://crack/lib/crack/xml.rb#56
  def initialize(name, normalized_attributes = T.unsafe(nil)); end

  # source://crack/lib/crack/xml.rb#73
  def add_node(node); end

  # source://crack/lib/crack/xml.rb#24
  def attributes; end

  # source://crack/lib/crack/xml.rb#24
  def attributes=(_arg0); end

  # source://crack/lib/crack/xml.rb#24
  def children; end

  # source://crack/lib/crack/xml.rb#24
  def children=(_arg0); end

  # Get the inner_html of the REXML node.
  #
  # source://crack/lib/crack/xml.rb#172
  def inner_html; end

  # source://crack/lib/crack/xml.rb#24
  def name; end

  # source://crack/lib/crack/xml.rb#24
  def name=(_arg0); end

  # source://crack/lib/crack/xml.rb#78
  def to_hash; end

  # Converts the node into a readable HTML node.
  #
  # @return [String] The HTML node in text form.
  #
  # source://crack/lib/crack/xml.rb#179
  def to_html; end

  # source://crack/lib/crack/xml.rb#185
  def to_s; end

  # source://crack/lib/crack/xml.rb#24
  def type; end

  # source://crack/lib/crack/xml.rb#24
  def type=(_arg0); end

  # Typecasts a value based upon its type. For instance, if
  # +node+ has #type == "integer",
  # {{[node.typecast_value("12") #=> 12]}}
  #
  # @note If +self+ does not have a "type" key, or if it's not one of the
  #   options specified above, the raw +value+ will be returned.
  # @param value [String] The value that is being typecast.
  # @return [Integer, TrueClass, FalseClass, Time, Date, Object] The result of typecasting +value+.
  #
  # source://crack/lib/crack/xml.rb#157
  def typecast_value(value); end

  # Take keys of the form foo-bar and convert them to foo_bar
  #
  # source://crack/lib/crack/xml.rb#164
  def undasherize_keys(params); end

  private

  # source://crack/lib/crack/xml.rb#191
  def unnormalize_xml_entities(value); end

  class << self
    # source://crack/lib/crack/xml.rb#34
    def available_typecasts; end

    # source://crack/lib/crack/xml.rb#38
    def available_typecasts=(obj); end

    # source://crack/lib/crack/xml.rb#26
    def typecasts; end

    # source://crack/lib/crack/xml.rb#30
    def typecasts=(obj); end
  end
end

# The Reason behind redefining the String Class for this specific plugin is to
# avoid the dynamic insertion of stuff on it (see version previous to this commit).
# Doing that disables the possibility of efectuating a dump on the structure. This way it goes.
#
# source://crack/lib/crack/xml.rb#14
class REXMLUtiliyNodeString < ::String
  # Returns the value of attribute attributes.
  #
  # source://crack/lib/crack/xml.rb#15
  def attributes; end

  # Sets the attribute attributes
  #
  # @param value the value to set the attribute attributes to.
  #
  # source://crack/lib/crack/xml.rb#15
  def attributes=(_arg0); end
end
