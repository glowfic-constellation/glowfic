# frozen_string_literal: true

# Rack caps a request body at 4096 form parameters (RACK_QUERY_PARSER_PARAMS_LIMIT)
# and a multipart body at 4096 parts (RACK_MULTIPART_TOTAL_PART_LIMIT), and
# Rack::MethodOverride swallows the error the first cap raises. The gallery edit
# form submits every icon in the gallery as nested attributes, about ten fields
# per icon, so saving a gallery of more than roughly 400 icons overflowed the
# cap, the `_method=put` override was never read, the request fell through as a
# plain POST, and the router answered 404.
#
# Raise both caps well past the largest gallery on the site. Rack's 4 MB body
# limit still bounds how much gets parsed.
limit = 65_536

Rack::Utils.default_query_parser = Rack::QueryParser.make_default(
  Rack::Utils.param_depth_limit,
  params_limit: limit,
)
Rack::Utils.multipart_total_part_limit = limit
