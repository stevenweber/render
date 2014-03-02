require "render/definition"

module Render
  describe Definition do
    before(:each) do
      @original_defs = Definition.instances.dup
    end

    after(:each) do
      Definition.instances = @original_defs
    end

    describe ".load_schemas!" do
      before(:each) do
        Definition.instances.clear
        @schema_id = "films.show"
        @json_schema = <<-JSON
          {
            "id": "#{@schema_id}",
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
        Definition.instances[@schema_id.to_sym].should == parsed_json
      end
    end
  end

  describe ".definition" do
    it "returns definition by its title" do
      def_id = :the_name
      definition = { id: def_id, properties: {} }
      Definition.load!(definition)

      Definition.find(def_id).should == definition
    end

    it "raises meaningful error if definition is not found" do
      expect {
        Definition.find(:definition_with_this_title_has_not_been_loaded)
      }.to raise_error(Render::Errors::Definition::NotFound)
    end
  end
end
