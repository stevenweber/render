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

    describe ".load_schemas!" do
      before(:each) do
        @schema_title = "film"
        @json_schema = <<-JSON
          {
            "title": "#{@schema_title}",
            "type": "object",
            "attributes": {
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
        Render.schemas = {}
      end

      it "stores JSON files" do
        expect {
          Render.load_schemas!(@directory)
        }.to change { Render.schemas.keys.size }.by(1)
      end

      it "accesses parsed schemas with symbols" do
        Render.load_schemas!(@directory)
        parsed_json = JSON.parse(@json_schema).recursive_symbolize_keys!
        Render.schemas[@schema_title.to_sym].should == parsed_json
      end
    end
  end
end