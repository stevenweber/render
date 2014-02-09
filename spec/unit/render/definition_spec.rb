require "render/definition"

module Render
  describe Definition do
    before(:each) do
      @original_defs = Definition.instances.dup
    end

    after(:each) do
      Definition.instances = @original_defs
    end

    describe ".load!" do
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

        Definition.load!(definition)
        Definition.instances.keys.should include(universal_title.to_sym)
      end
    end

    describe ".load_schemas!" do
      before(:each) do
        Definition.instances.clear
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
        Definition.instances = {}
      end

      it "stores JSON files" do
        expect {
          Definition.load_from_directory!(@directory)
        }.to change { Definition.instances.keys.size }.by(1)
      end

      it "accesses parsed schemas with symbols" do
        Definition.load_from_directory!(@directory)
        parsed_json = Render::Extensions::DottableHash.new(JSON.parse(@json_schema)).recursively_symbolize_keys!
        Definition.instances[@schema_title.to_sym].should == parsed_json
      end
    end
  end

  describe ".definition" do
    it "returns definition by its title" do
      def_title = :the_name
      definition = { title: def_title, properties: {} }
      Definition.load!(definition)

      Definition.find(def_title).should == definition
    end

    it "raises meaningful error if definition is not found" do
      expect {
        Definition.find(:definition_with_this_title_has_not_been_loaded)
      }.to raise_error(Render::Errors::DefinitionNotFound)
    end
  end
end
