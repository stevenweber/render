@old_format = {
  type: Object,
  title: "film",
  attributes: {
    title: { type: String },
    director_id: { type: UUID },
    director: {
      type: Object,
      endpoint: "http://foo.bar/directors/:id",
      attributes: {
        name: { type: String },
        id: { type: UUID }
      }
    }
  }
}

@film = Schema
  title: "film",
  type: Object
  attributes: {
    title: { type: String },
    director_id: { type: UUID },

@director = Schema
  title: "director",
  type: Object
  attributes: [
    id: { type: UUID },
    name: { type: String }
  ]

Graph
  schema: @film
  endpoint: "http://foo.bar/films/:id",
  relationships: {},
  params: { id: ? }
  graphs: [
    Graph
      schema: @director,
      endpoint: "http://foo.bar/directors/:id"
      relationships: { director_id: :id }
      graphs: [],
      params: { id: ? }
  ]

