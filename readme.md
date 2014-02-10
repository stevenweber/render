# Render

Render improves the way you work with APIs.

* [Generate type-specific, dynamic API response data for testing](spec/integration/render/schema_spec.rb) with just a schema (JSON or Ruby)
* [Make API requests](spec/integration/render/graph_spec.rb) with a URL and a schema
* Build graphs that [interpret data from one endpoint to call others](spec/integration/render/nested_graph_spec.rb)

## Setup

Update your Gemfile:

      gem "render"

## Usage

Check out examples as part of the [integration tests](spec/integration/render).

## Caveats

- Render is under initial development

## Roadmap

1. Custom headers (e.g. { pragma: "no-cache", host: "dont_redirect_to_www.site.com" })
2. Enhance Attribute metadata (e.g. minlength)
3. Enhance Graph to Graph relationships
4. Custom request strategy

## Contributing

* Bugs and questions welcomed. If you know (or kind of know) what's going on:
  * Write a failing test, kudos for solving it
  * Put up a [pull request](https://help.github.com/articles/using-pull-requests)
