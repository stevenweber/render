require "render"

module Render
  describe Schema do
    describe "#initialize" do
      describe "#definition" do
        before(:all) do
          @original_defs = Render.definitions
        end

        after(:all) do
          Render.definitions = @original_defs
        end

        it "is set from argument" do
          schema_definition = { properties: {} }
          Schema.new(schema_definition).definition.should == schema_definition
        end

        it "is set to preloaded definition" do
          definition_title = :preloaded_schema
          definition = { title: definition_title, properties: { title: { type: String } } }
          Render.load_definition!(definition)
          Schema.new(definition_title).definition.should == definition
        end

        it "raises an error if definition is not found and argument is not a schema" do
          expect {
            Schema.new(:does_not_exists)
          }.to raise_error(Errors::DefinitionNotFound)
        end
      end

      it "sets its type from schema" do
        type = [Array, Object].sample
        definition = { type: type, properties: {}, items: {} }
        Schema.new(definition).type.should == type
      end

      describe "#array_attribute" do
        it "is set for array schemas" do
          archetype_schema = {
            type: Array,
            items: {
              type: String
            }
          }

          attribute = Schema.new(archetype_schema).array_attribute
          attribute.type.should == String
          attribute.archetype.should == true
        end
      end

      describe "#hash_attributes" do
        it "is set for object schemas" do
          simple_schema = {
            properties: {
              name: { type: String },
              genre: { type: String }
            }
          }

          schema = Schema.new(simple_schema)
          schema.hash_attributes.size.should == 2
          schema.hash_attributes.any? { |a| a.name == :name && a.type == String }.should == true
          schema.hash_attributes.any? { |a| a.name == :genre && a.type == String }.should == true
        end
      end
    end

    describe "#serialize!" do
      it "returns serialized array" do
        definition = {
          type: Array,
          items: {
            type: UUID
          }
        }
        schema = Schema.new(definition)
        schema.array_attribute.should_receive(:serialize).with(nil).and_return([:data])
        schema.serialize!.should == [:data]
      end

      it "returns serialized hash" do
        definition = {
          type: Object,
          properties: {
            title: { type: String }
          }
        }
        schema = Schema.new(definition)
        schema.hash_attributes.first.should_receive(:serialize).with(nil).and_return({ title: "foo" })
        schema.serialize!.should == { title: "foo" }
      end
    end

    describe "#render!" do
      before(:all) do
        @original_defs = Render.definitions
        Render.load_definition!({
          title: :film,
          properties: {
            genre: { type: String }
          }
        })
      end

      after(:all) do
        Render.definitions = @original_defs
      end

      describe "#raw_data" do
        it "is set from endpoint response" do
          schema = Schema.new(:film)
          schema.stub({ request: { response: :body } })
          schema.render!
          schema.raw_data.should == { response: :body }
        end

        it "is set to explicit_data when offline" do
          Render.stub({ live: false })
          schema = Schema.new(:film)
          schema.render!({ explicit: :value })
          schema.raw_data.should == { explicit: :value }
        end

        it "is yielded" do
          Render.stub({ live: false })
          schema = Schema.new(:film)

          data = { explicit: :value }
          schema.should_receive(:serialize!).with(data)
          schema.serialized_data = :serialized_data

          expect { |a_block|
            schema.render!(data, &a_block)
          }.to yield_with_args(:serialized_data)
        end
      end

      context "request" do
        it "raises error if endpoint does not return a 2xx" do
          endpoint = "http://endpoint.local"
          stub_request(:get, endpoint).to_return({ status: 403 })

          expect {
            schema = Schema.new(:film)
            schema.render!({ endpoint: endpoint })
          }.to raise_error(Errors::Schema::RequestError)
        end

        it "returns meaningful error when response contains invalid JSON" do
          endpoint = "http://enpoint.local"
          stub_request(:get, endpoint).to_return({ body: "Server Error: 500" })

          expect {
            Schema.new(:film).render!({ endpoint: endpoint })
          }.to raise_error(Errors::Schema::InvalidResponse)
        end

        it "uses configured request logic"
      end

      context "return value" do
        it "is serialized data" do
          endpoint = "http://endpoint.local"
          genre = "The Shining"
          data = { genre: genre }
          response = { status: 200, body: data.to_json }
          stub_request(:get, endpoint).to_return(response)

          schema = Schema.new(:film)
          schema.hash_attributes.first.should_receive(:serialize).with(genre).and_return({ genre: genre })

          schema.render!({ endpoint: endpoint }).should == { film: data }
        end

        it "is serialized value nested under #universal_title" do
          Render.stub({ live: false })
          definition = {
            title: :film,
            universal_title: :imdb_films_show,
            properties: {
              genre: { type: String }
            }
          }
          Schema.new(definition).render!.should have_key(:imdb_films_show)
        end
      end

    end
  end
end
