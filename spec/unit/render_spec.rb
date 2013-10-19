require "render"

describe Render do
  # Just give me this one existential thought to commemerate Prague.
  it "exists" do
    Render.should be_true
  end

  describe "configuration" do
    describe ".live" do
      before(:each) do
        @original_live = Render.live
      end

      after(:each) do
        Render.live = @original_live
      end

      it "defaults to true" do
        Render.live.should == true
      end

      it "can be set to faux-request mode" do
        Render.live = false
        Render.live.should == false
      end
    end

    describe "logger" do
      it "exits" do
        Render.logger.should be
      end
    end

    describe ".generators" do
      before(:each) do
        @original_value = Render.generators
        Render.generators.clear
      end

      after(:each) do
        Render.generators = @original_value
      end

      it "defaults to an empty array" do
        Render.generators.should == []
      end
    end

    context "schema definitions" do
      before(:each) do
        @original_defs = Render.definitions
      end

      after(:each) do
        Render.definitions = @original_defs
      end

      describe ".load_defintion!" do
        it "preferences #universal_title over title" do
          universal_title = "a_service_films_show"
          definition = {
            universal_title: universal_title,
            title: "film",
            type: Object,
            properties: {
              name: { type: String },
              year: { type: Integer }
            }
          }

          Render.load_definition!(definition)
          Render.definitions.keys.should include(universal_title.to_sym)
        end
      end

      describe ".load_schemas!" do
        before(:each) do
          Render.definitions.clear
          @schema_title = "film"
          @json_schema = <<-JSON
          {
            "title": "#{@schema_title}",
            "type": "object",
            "properties": {
              "name": { "type": "string" },
              "year": { "type": "integer" }
            }
          }
          JSON

          @directory = "/a"
          @schema_file = "/a/schema.json"
          Dir.stub(:glob).with(%r{#{@directory}}).and_return([@schema_file])
          IO.stub(:read).with(@schema_file).and_return(@json_schema)
        end

        after(:each) do
          Render.definitions = {}
        end

        it "stores JSON files" do
          expect {
            Render.load_definitions!(@directory)
          }.to change { Render.definitions.keys.size }.by(1)
        end

        it "accesses parsed schemas with symbols" do
          Render.load_definitions!(@directory)
          parsed_json = JSON.parse(@json_schema).recursive_symbolize_keys!
          Render.definitions[@schema_title.to_sym].should == parsed_json
        end
      end
    end

    describe ".definition" do
      it "returns definition by its title" do
        def_title = :the_name
        definition = { title: def_title, properties: {} }
        Render.load_definition!(definition)

        Render.definition(def_title).should == definition
      end

      it "raises meaningful error if definition is not found" do
        expect {
          Render.definition(:definition_with_this_title_has_not_been_loaded)
        }.to raise_error(Render::Errors::DefinitionNotFound)
      end
    end

    describe ".parse_type" do
      it "returns constant for string" do
        Render.parse_type("integer").should == Integer
      end

      it "returns argument when not a string" do
        class Foo; end
        Render.parse_type(Foo).should == Foo
        Object.__send__(:remove_const, :Foo)
      end

      it "raises meaningful error for unmatched types" do
        expect {
          Render.parse_type("NotAClass")
        }.to raise_error(Render::Errors::InvalidType)
      end

      describe "non-standard formats" do
        it "maps regardless of capitalization" do
          string_representations = %w(uuid UUID)
          string_representations.each do |name|
            Render.parse_type(name).should == UUID
          end
        end

        it "returns UUID for uuid"
        it "returns Boolean for boolean"
        it "returns Float for number"
        it "returns Time for date-time"
      end
    end
  end
end
