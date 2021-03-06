require "addressable/template"

require "render/schema"
require "render/errors"
require "render/extensions/dottable_hash"

module Render
  class Graph
    attr_accessor :schema,
      :raw_endpoint,
      :relationships,
      :graphs,
      :config,
      :rendered_data,
      :relationship_info

    def initialize(schema_or_definition, options = {})
      self.schema = determine_schema(schema_or_definition)
      self.relationships = (options.delete(:relationships) || {})
      self.graphs = (options.delete(:graphs) || [])
      self.raw_endpoint = (options.delete(:endpoint) || schema.definition[:endpoint]).to_s
      self.config = options
      self.relationship_info = {}
    end

    def title
      schema.id || schema.title
    end

    def serialize!(explicit_data = nil, parental_data = nil)
      process_relationship_info!(parental_data)

      if (schema.type == Array)
        schema.render!(explicit_data, endpoint)
      else
        explicit_data ||= {}
        schema.render!(explicit_data.merge(relationship_info), endpoint)
      end
    end

    def render!(explicit_data = nil, parental_data = nil, as_array = false)
      if as_array
        data = parental_data.inject([]) do |accumulator, parental_element|
          accumulator << serialize!(explicit_data, parental_element)
        end
      else
        data = serialize!(explicit_data, parental_data)
      end

      loop_with_configured_threading(graphs) do |graph|
        graph.render!(explicit_data, data, (schema.type == Array))
      end

      self.rendered_data = graphs.inject(Extensions::DottableHash.new) do |data, graph|
        data[graph.title] = graph.rendered_data
      end
      self.rendered_data[title] = data
      rendered_data
    end

    private

    def endpoint
      template = Addressable::Template.new(raw_endpoint)
      variables = config.merge(relationship_info)
      undefined_variables = (template.variables - variables.keys.collect(&:to_s))
      raise Errors::Graph::EndpointKeyNotFound.new(undefined_variables) if (undefined_variables.size > 0)
      template.expand(variables).to_s
    end

    def process_relationship_info!(data)
      return if !data

      self.relationship_info = relationships.inject({}) do |info, (parent_key, child_key)|
        value = data.is_a?(Hash) ? data.fetch(parent_key, nil) : data
        info.merge!({ child_key => value })
      end
    end

    def loop_with_configured_threading(elements)
      if Render.threading?
        threads = []
        elements.each do |element|
          threads << Thread.new do
            yield element
          end
        end
        threads.collect(&:join)
      else
        elements.each do |element|
          yield element
        end
      end
    end

    def determine_schema(schema_or_definition)
      if schema_or_definition.is_a?(Schema)
        schema_or_definition
      else
        Schema.new(schema_or_definition)
      end
    end

  end
end
