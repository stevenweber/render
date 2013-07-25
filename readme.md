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

## Caveats

- Render will modify ::Hash and ::Enumerable to provide symbolize/stringify keys methods.

## Usage

*Autoload schemas*

```ruby
Render.load_schemas!("path/to/json/schemas")
Render::Graph.new(:schema_title, { endpoint: "http://films.local/films" }).render
```

*Variable interpolation*

```ruby
api_endpoint = "http://films.local/films/:id?:client_token"
env_specific_client_token = "token"

graph = Render::Graph.new(:schema_title, { endpoint: api_endpoint, client_token: env_specific_client_token })
graph.render({ id: "an-id" }) # makes request to "http://films.local/films/an-id?client_token=token"
```

Check out the examples in [integration tests](spec/integration/).


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
