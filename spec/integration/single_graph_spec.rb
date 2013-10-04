require "render"

describe Render do
  before(:all) do
    Render.load_definitions!(Helpers::SCHEMA_DIRECTORY)
  end

  after(:all) do
    Render.definitions = {}
  end

  before(:each) do
    @film_id = UUID.generate
    @film_name = "The Life Aqautic with Steve Zissou"

    # Typically in environmental config
    @secret_code = "3892n-2-n2iu1bf1cSdas0dDSAF"
    @films_endpoint = "http://films.local/films?:secret_code"
    @film_endpoint = "http://films.local/films/:id?:secret_code"
  end

  describe "requests" do
    it "returns structured data" do
      aquatic_uri = @films_endpoint.gsub(":secret_code", "secret_code=#{@secret_code}")
      stub_request(:get, aquatic_uri).to_return({ body: [{ id: @film_id }].to_json })

      graph = Render::Graph.new(:films, { endpoint: @films_endpoint, secret_code: @secret_code })
      graph.render.should == { films: [{ id: @film_id }] }
    end

    it "returns structured data for specific resources" do
      id = UUID.generate
      aquatic_uri = @film_endpoint.gsub(":id", id).gsub(":secret_code", "secret_code=#{@secret_code}")
      stub_request(:get, aquatic_uri).to_return({ body: { name: @film_name }.to_json })

      graph = Render::Graph.new(:film, { id: id, endpoint: @film_endpoint, secret_code: @secret_code })
      graph.render.should == { film: { name: @film_name, year: nil } }
    end
  end

  describe "stubbed responses" do
    before(:each) do
      Render.stub({ live: false })
    end

    it "use meaningful values" do
      response = Render::Graph.new(:film).render({ name: @film_name })

      stub_request(:post, "http://films.local/create").to_return({ body: response.to_json })
      response = post_film(:anything)["film"]

      response["name"].should be_a(String)
      response["year"].should be_a(Integer)
    end

    it "allows users to specify specific values" do
      response = Render::Graph.new(:film).render({ name: @film_name })

      data = { name: @film_name }.to_json
      stub_request(:post, "http://films.local/create").with({ body: data }).to_return({ body: response.to_json })
      response = post_film(data)["film"]

      response["name"].should == @film_name
    end
  end

  def post_film(data)
    response = Net::HTTP.start("films.local", 80) do |http|
      request = Net::HTTP::Post.new("/create")
      request.body = data
      http.request(request)
    end
    JSON.parse(response.body)
  end
end
