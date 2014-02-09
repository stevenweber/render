# Render allows one to define object Graphs with Schema/endpoint information.
# Once defined and constructed, a Graph can be built at once that will:
#  - Query its endpoint to construct a hash for its Schema
#  - Add nested Graphs by interpreting/sending data they need

require "uuid"
require "date"
require "logger"

require "render/version"
require "render/errors"
require "render/extensions/dottable_hash"
require "render/type"
require "render/generator"
require "render/definition"
require "render/graph"

module Render
  @live = true
  @logger = ::Logger.new("/dev/null")
  @threading = true

  class << self
    attr_accessor :live, :logger, :threading

    def threading?
      threading == true
    end

    def live?
      @live == true
    end

  end
end
