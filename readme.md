# Render

Create and test API requests simply with schemas.

```ruby
Render.load_schemas!("spec/schemas") # JSON schema directory
Render::Graph.new(:film, { endpoint: "http://films.local/films" }).render
# or stub out schema-specific data
Render.live = false
Render::Graph.new(:film).render
```

*Use with caution* (Render is under initial development) by updating your Gemfile:

    gem "render"

## Usage

Try out examples with `Render.live = false`.

*Simple*

```ruby
schema = Render::Schema.new({
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

Render::Graph.new(schema, options).render({ id: "4cb6b490-d706-0130-2a93-7c6d628f9b06" })
```

*Nested*

```ruby
film_schema = Render::Schema.new({
  title: :film,
  type: Object,
  attributes: {
    id: { type: UUID },
    title: { type: String }
  }
})

films_schema = Render::Schema.new({
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

films_graph = Render::Graph.new(films_schema, { endpoint: "http://films.local/films" })
film_graph = Render::Graph.new(film_schema, { endpoint: "http://films.local/films/:id", relationships: { id: :id } })
films_graph.graphs << film_graph
films_graph.render
```
*Autoload schemas*

```ruby
Render.load_schemas!("path/to/json/schemas")
Render::Graph.new(:schema_title, { endpoint: "http://films.local/films" }).render
```

*Variable interpolation*

```ruby
options = { endpoint: "http://films.local/films/:id?:client_token", client_token: "token" }
graph = Render::Graph.new(:schema_title, options)
graph.render({ id: "an-id" })
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
