require "render/schema"

module Render
  describe Schema do
    before(:each) do
      Render.stub({ live: false })
    end

    describe "#serialize" do
      it "returns data from hashes" do
        definition = {
          title: "film",
          type: Object,
          properties: {
            title: {
              type: String
            }
          }
        }
        data = { title: "a name" }
        Schema.new(definition).serialize(data).should == data
      end


      it "returns data from arrays" do
        definition = {
          title: "names",
          type: Array,
          items: {
            type: String
          }
        }
        schema = Schema.new(definition)
        names = ["bob", "bill"]
        schema.serialize(names).should == names
      end

      it "returns data from arrays of schemas" do
        definition = {
          title: "films",
          type: Array,
          items: {
            type: Object,
            properties: {
              id: { type: UUID }
            }
          }
        }

        the_id = UUID.generate
        films = [{ id: the_id }]
        schema = Schema.new(definition)
        schema.serialize(films).should == films
      end
    end
  end
end
