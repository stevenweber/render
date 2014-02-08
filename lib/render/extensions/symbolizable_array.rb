module Render
  module Extensions
    class SymbolizableArray < Array
      class << self
        def new(array)
          array.inject(super()) do |accumulator, item|
            if item.is_a?(Array)
              accumulator << new(item)
            elsif item.is_a?(Hash)
              accumulator << DottableHash.new(item)
            else
              accumulator << item
            end
          end
        end
      end

      def recursively_symbolize_keys!
        each do |item|
          item.recursively_symbolize_keys! if item.respond_to?(:recursively_symbolize_keys!)
        end
        self
      end
    end
  end
end
