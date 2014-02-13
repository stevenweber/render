# Generators make fake data in non-live mode.
# They are used for attributes of a specified type, and whose name matches its defined matcher.

require "uuid"
require "render/errors"
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
        generator.trigger(algorithm_argument)
      end

      def find(type, to_match)
        instances.detect do |generator|
          (generator.type == type) && to_match.match(generator.matcher)
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

    # Default set to ensure each type can generate fake data.
    Generator.create!(String, /.*/, proc { |attribute| "#{attribute.name} (generated)" })
    Generator.create!(Integer, /.*/, proc { rand(100) })
    Generator.create!(Float, /.*/, proc { rand(0.1..99).round(2) })
    Generator.create!(UUID, /.*/, proc { UUID.generate })
    Generator.create!(Time, /.*/, proc { |attribute| time = Time.now; (attribute.type == String) ? time.to_s : time })
    Generator.create!(Type::Boolean, /.*/, proc { [true, false].sample })
    Generator.create!(Type::Enum, /.*/, proc { |attribute| attribute.enums.sample })
    Generator.create!(Type::Date, /.*/, proc { Time.now.to_date })
  end
end
