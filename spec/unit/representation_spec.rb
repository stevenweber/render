require "representation"

describe Representation do
  # Just give me this one existential thought to commemerate Prague.
  it "exists" do
    Representation.should be_true
  end

  describe "configuration" do
    describe ".live" do
      before(:each) do
        @original_live = Representation.live
      end

      after(:each) do
        Representation.live = @original_live
      end

      it "defaults to true" do
        Representation.live.should == true
      end

      it "can be set to faux-request mode" do
        Representation.live = false
        Representation.live.should == false
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
        Representation.schemas = {}
      end

      it "stores JSON files" do
        expect {
          Representation.load_schemas!(@directory)
        }.to change { Representation.schemas.keys.size }.by(1)
      end

      it "accesses parsed schemas with symbols" do
        Representation.load_schemas!(@directory)
        parsed_json = JSON.parse(@json_schema).recursive_symbolize_keys!
        Representation.schemas[@schema_title.to_sym].should == parsed_json
      end
    end
  end
end
