# Generators make fake data in non-live mode.
# They are used for attributes of a specified type, and whose name matches its defined matcher.

require "uuid"
require "render/errors"
require "render/type"
require "date"

module Render
  class Generator
    @instances = []

    class << self
      attr_accessor :instances

      # When in non-live mode, e.g. testing, you can use custom generators to make fake data for a given attribute type
      # and name-matcher.
      # @param type [Class] Use generator exclusively for this type of data
      # @param matcher [Regexp] Use generator for attribute whose name matches this
      # @param algorithm [Proc, #call] Call this to generate a value
      def create!(type, matcher, algorithm)
        generator = new(type, matcher, algorithm)
        instances.unshift(generator)
        generator
      end

      def trigger(type, to_match, algorithm_argument = nil)
        generator = find(type, to_match)
        if generator
          generator.trigger(algorithm_argument)
        else
          Render.logger.warn("Could not find generator for type #{type} with matcher for #{to_match}, using nil")
          nil
        end
      end

      def find(type, to_match)
        instances.detect do |generator|
          (type == generator.type) && to_match.to_s.match(generator.matcher)
        end
      end
    end

    attr_accessor :type, :matcher, :algorithm

    def initialize(type, matcher, algorithm)
      self.type = type
      self.matcher = matcher
      set_algorithm!(algorithm)
    end

    def trigger(algorithm_argument = nil)
      algorithm[algorithm_argument]
    end

    private

    def set_algorithm!(algorithm)
      if algorithm.respond_to?(:call)
        self.algorithm = algorithm
      else
        raise Errors::Generator::MalformedAlgorithm.new(algorithm)
      end
    end

    # Ensure each type can generate fake data.
    # Standard JSON types
    Generator.create!(String, /.*/, proc { |attribute|
      min_length = attribute.min_length || -1
      max_length = (attribute.max_length.to_i - 1)
      "#{attribute.name} (generated)".ljust(min_length, "~")[0..max_length]
    })
    Generator.create!(Type::Boolean, /.*/, proc { [true, false].sample })
    Generator.create!(Integer, /.*/, proc { rand(100) })
    Generator.create!(Float, /.*/, proc { rand(0.1..99).round(2) }) # parsed from number
    Generator.create!(nil, /.*/, proc {}) # parsed from null
    # Standard JSON formats
    Generator.create!(DateTime, /.*/, proc { DateTime.now.to_s })
    Generator.create!(URI, /.*/, proc { "http://localhost" })
    Generator.create!(Type::Hostname, /.*/, proc { "localhost" })
    Generator.create!(Type::Email, /.*/, proc { "you@localhost" })
    Generator.create!(Type::IPv4, /.*/, proc { "127.0.0.1" })
    Generator.create!(Type::IPv6, /.*/, proc { "::1" })
    Generator.create!(Type::Enum, /.*/, proc { |attribute| attribute.enums.sample })
    # Extended
    Generator.create!(UUID, /.*/, proc { UUID.generate })
    Generator.create!(Time, /.*/, proc { |attribute| time = Time.now; (attribute.type == String) ? time.to_s : time })
    Generator.create!(Type::Date, /.*/, proc { Time.now.to_date })
  end
end
