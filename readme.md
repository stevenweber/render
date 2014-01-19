# Render

Create and test API requests simply with schemas.

```ruby
irb -r ./initialize
Render.load_definitions!("spec/schemas") # JSON schema directory
Render::Graph.new(:films_index, { endpoint: "http://films.local/films" }).render
# or stub out schema-specific data
Render.live = false
Render::Graph.new(:films_show).render
```

Use by updating your Gemfile:

    gem "render"

## Caveats

- Render is under initial development and may include bugs

## Usage

*Autoload schema definitions*

```ruby
Render.load_definitions!("path/to/json/schemas")
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

## Roadmap

1. Custom HTTP headers (e.g. { pragma: "no-cache", host: "dont_redirect_to_www.site.com" })
2. Enhanced Attribute metadata (e.g. minlength)
3. Enhanced Graph to Graph relationships

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
