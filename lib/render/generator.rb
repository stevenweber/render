# Custom generators to make fake data in non-live mode.

require "render"
require "render/errors"

module Render
  class Generator
    attr_accessor :type, :matcher, :algorithm

    # When in non-live mode, e.g. testing, you can use custom generators to make fake data for a given attribute type
    # and name-matcher.
    # @param type [Class] Use generator for this type of data
    # @param matcher [Regexp] Use generator for attribute whose name matches this
    # @param algorithm [Proc, #call] Call this to generate a value
    def initialize(type, matcher, algorithm)
      self.type = type
      self.matcher = matcher
      set_algorithm!(algorithm)

      Render.generators << self
    end

    private

    def set_algorithm!(algorithm)
      if algorithm.respond_to?(:call)
        self.algorithm = algorithm
      else
        raise Errors::Generator::MalformedAlgorithm.new(algorithm)
      end
    end

  end
end
