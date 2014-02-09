# Render allows one to define object Graphs with Schema/endpoint information.
# Once defined and constructed, a Graph can be built at once that will:
#  - Query its endpoint to construct a hash for its Schema
#  - Add nested Graphs by interpreting/sending data they need

require "uuid"
require "date"
require "logger"

require "render/version"
require "render/extensions/dottable_hash"
require "render/errors"
require "render/types"
require "render/graph"
require "render/generator"
require "render/definition"

module Render
  @live = true
  @logger = ::Logger.new("/dev/null")
  @threading = true

  class << self
    attr_accessor :live,
      :logger,
      :threading

    def threading?
      threading == true
    end

    def parse_type(type)
      Render::Types.parse(type)
    end
  end
end
