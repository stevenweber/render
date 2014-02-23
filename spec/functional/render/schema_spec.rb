require "render/schema"

module Render
  describe Schema do
    before(:each) do
      Render.stub({ live: false })
    end

    describe "#serialize!" do
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
        Schema.new(definition).serialize!(data).should == data
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
        schema.serialize!(names).should == names
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
        schema.serialize!(films).should == films
      end
    end

    describe "required" do
      # +Standard
      it "is set with HashAttribute-level keyword" do
        schema = Schema.new({
          type: Object,
          properties: {
            name: { type: String, required: true },
          }
        })

        schema.hash_attributes.first.required.should be
      end

      it "is set on schema-level keyword" do
        schema = Schema.new({
          type: Object,
          properties: {
            name: { type: String },
            address: { type: String },
          },
          required: [:address]
        })

        schema.attributes[0].required.should_not be
        schema.attributes[1].required.should be
      end
    end
  end
end
