require "render"

module Render
  describe Schema do
    before(:all) do
      Render::Definition.load_from_directory!(Helpers::SCHEMA_DIRECTORY)
      Render.live = false

      module ::TransformerExample
        class << self
          def process_name
            uri = URI("http://films.local")
            response = JSON.parse(Net::HTTP.get(uri))
            { transformed_to: response.fetch("name") }
          end
        end
      end
    end

    after(:all) do
      Render::Definition.instances.clear
      Render.live = true
      Object.send(:remove_const, :TransformerExample)
    end

    it "stubs data for testing" do
      name = "am I transforming this right?"
      rendered_stub = Render::Schema.new(:films_show).serialize!({ name: name })
      stub_request(:get, "http://films.local").to_return({ body: rendered_stub.to_json })

      TransformerExample.process_name[:transformed_to].should == name
    end

    it "enforces schema's definition" do
      name = "am I transforming this right?"
      rendered_stub = Render::Schema.new(:films_show).serialize!({ wrong_key: name })
      stub_request(:get, "http://films.local").to_return({ body: rendered_stub.to_json })

      TransformerExample.process_name[:transformed_to].should_not == name
    end

    it "prevents errors related to code anticipating actual data" do
      rendered_stub = Render::Schema.new(:films_show).serialize!
      stub_request(:get, "http://films.local").to_return({ body: rendered_stub.to_json })

      expect {
        response = TransformerExample.process_name
      }.not_to raise_error
    end

    it "creates fake data for varying types" do
      schema = {
        title: :film,
        type: Object,
        properties: {
          id: { type: UUID },
          title: { type: String },
          director: {
            type: Object,
            properties: {
              rating: { type: Float }
            }
          },
          genre: {
            type: String,
            enum: ["horror", "action", "sci-fi"]
          },
          tags: {
            type: Array,
            minItems: 1,
            items: {
              type: Object,
              properties: {
                name: { type: String },
                id: { type: Integer }
              }
            }
          }
        }
      }

      response = Render::Schema.new(schema).serialize!
      UUID.validate(response[:id]).should be_true
      response[:title].should be_a(String)
      response[:director][:rating].should be_a(Float)
      %w(horror action sci-fi).should include(response[:genre])
      response[:tags].first[:name].should be_a(String)
      response[:tags].first[:id].should be_a(Integer)
    end
  end
end
