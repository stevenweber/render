require "representation/errors"

module Representation
  class Generator
    attr_accessor :type, :matcher, :algorithm

    def initialize(attributes = {})
      attributes.symbolize_keys!
      %w(type matcher algorithm).each { |attribute| self.__send__("#{attribute}=", attributes[attribute.to_sym]) }
      raise Errors::Generator::MalformedAlgorithm.new(algorithm) if !algorithm.respond_to?(:call)
    end

  end
end
