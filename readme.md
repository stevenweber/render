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

## Caveats/Notes/Assumptions

- Currently under initial development
- Assumes additionalProperties is always false
  - It would be impossible to model reponses otherwise
  - Additional response data does not affect what's been defined

Render is not meant to be a validator. As such, it does not care about:

  - dependencies (validating one attribute's presence on another's)
  - minProperties/maxProperties (either define it, or it's not worth caring about)
  - Divergent responses, e.g. no errors will be raised if "abc" is returned for String with { "minLength": 4 }

It will however,

  - Defensively type response values based on definition so you don't run into issues like ("2" > 1)

## Roadmap

- Enhanced nesting
  - Leveraging $ref for nesting
  - Relationship calculation between nested Graphs
- The following keyword implementations:
  - anyOf/allOf/oneOf/not
  - pattern/patternProperties
  - Variable types, i.e. { type: [String, Float] }
- Tuples of varying types, e.g. [3, { name: "bob" }]
- Relating to requests
  - Custom options, e.g. headers, timeouts
  - Drop-in custom requesting

## Contributing

* Bugs and questions welcomed. If you know (or kind of know) what's going on:
  * Write a failing test, kudos for solving it
  * Put up a [pull request](https://help.github.com/articles/using-pull-requests)
