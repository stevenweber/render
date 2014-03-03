# Render

Render improves the way you work with APIs.

* [Generate type-specific, dynamic API response data for testing](spec/integration/render/schema_spec.rb) with just a schema (JSON or Ruby)
* [Make API requests](spec/integration/render/graph_spec.rb) with a URL and a schema
* Build Graphs that [interpret data from one endpoint to call others](spec/integration/render/nested_graph_spec.rb)

## Setup

Update your Gemfile:

      gem "render"

## Usage

Check out examples as part of the [integration tests](spec/integration/render).

```ruby
# Make requests
Render::Definition.load_from_directory!("/path/to/json/schema/dir")
Render::Graph.new("loaded-schema-id", { host: "films.local" }).render!

# Or mock data
Render.live = false
planned_schema = {
  type: :object,
  properties: {
    name: { type: :string, minLength: 1 },
    email: { type: :string, format: :email },
    sex: { type: :string, enum: %w(MALE FEMALE) },
    address: {
      type: :object,
      properties: {
        number: { type: :integer },
        street: { type: :string }
      }
    },
    nicknames: {
      type: :array,
      minItems: 1,
      maxItems: 1,
      items: { type: :string }
    }
  }
}

mock_data = Render::Schema.new(planned_schema).render!
# => {
#   :person=> {
#     :name => "name (generated)",
#     :email => "you@localhost",
#     :sex => "FEMALE",
#     :address => {
#       :number => 513948,
#       :street => "street (generated)"
#     },
#     :nicknames => ["nicknames (generated)"]
#   }
# }
```

## Caveats/Notes/Assumptions

- Assumes additionalProperties is always false because unknown properties cannot be modeled

Render is not meant to be a validator. As such, it does not care about:

  - Keywords that do not strictly define schemas: `not`, `minProperties`, `maxProperties`, `dependencies`
  - Divergent responses, e.g. no errors will be raised if "abc" is returned for String with { "minLength": 4 }

It will however,

  - Defensively type response values based on definition so you don't run into issues like ("2" > 1)

## Roadmap

- `links` implementation as opposed to `endpoint`
- Expanded keyword implementations:
  - anyOf, allOf, oneOf
  - pattern/patternProperties
  - Tuples of varying types, e.g. [3, { name: "bob" }]
- Relating to requests
  - Custom options, e.g. headers, timeouts
  - Drop-in custom requesting
- Enhanced relationship calculation between nested Graphs
- Enhanced $ref implementation

## Contributing

* Bugs and questions welcomed. If you know (or kind of know) what's going on:
  * Write a failing test, kudos for solving it
  * Put up a [pull request](https://help.github.com/articles/using-pull-requests)
