require "render/errors"

module Render
  class Generator
    attr_accessor :type, :matcher, :algorithm

    def initialize(properties = {})
      DottableHash.new(properties).symbolize_keys!
      %w(type matcher algorithm).each { |attribute| self.__send__("#{attribute}=", properties[attribute.to_sym]) }
      raise Errors::Generator::MalformedAlgorithm.new(algorithm) if !algorithm.respond_to?(:call)
    end

  end
end
