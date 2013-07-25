# Representation

Create and test API requests simply with schemas.

```ruby
Representation.load_schemas!("spec/schemas") # JSON schema directory
Representation::Graph.new(:film, { endpoint: "http://films.local/films" }).pull
# or stub out schema-specific data
Representation.live = false
Representation::Graph.new(:film).pull
```

*Use with caution* (Representation is under initial development) by updating your Gemfile:

    gem "representation"

## Usage

Try out examples with `Representation.live = false`.

*Simple*

```ruby
schema = Representation::Schema.new({
  title: :film,
  type: Object,
  attributes: {
    id: { type: UUID },
    title: { type: String }
  }
})

options = {
  endpoint: "http://films.local/films/:id"
}

Representation::Graph.new(schema, options).pull({ id: "4cb6b490-d706-0130-2a93-7c6d628f9b06" })
```

*Nested*

```ruby
film_schema = Representation::Schema.new({
  title: :film,
  type: Object,
  attributes: {
    id: { type: UUID },
    title: { type: String }
  }
})

films_schema = Representation::Schema.new({
  title: :films,
  type: Array,
  elements: {
    title: :film,
    type: Object,
    attributes: {
      id: { type: UUID }
    }
  }
})

films_graph = Representation::Graph.new(films_schema, { endpoint: "http://films.local/films" })
film_graph = Representation::Graph.new(film_schema, { endpoint: "http://films.local/films/:id", relationships: { id: :id } })
films_graph.graphs << film_graph
films_graph.pull
```
*Autoload schemas*

```ruby
Representation.load_schemas!("path/to/json/schemas")
Representation::Graph.new(:schema_title, { endpoint: "http://films.local/films" }).pull
```

*Variable interpolation*

```ruby
options = { endpoint: "http://films.local/films/:id?:client_token", client_token: "token" }
graph = Representation::Graph.new(:schema_title, options)
graph.pull({ id: "an-id" })
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
