require "render"

module Render
  module JSONSchema
    Definition.load_from_directory!("lib/json/draft-04")

    CORE = Schema.new("http://json-schema.org/draft-04/schema#")
    HYPER = Schema.new("http://json-schema.org/draft-04/hyper-schema#")
    PROPERTIES = [CORE.attributes.collect(&:name), HYPER.attributes.collect(&:name)].flatten.uniq

  end
end
