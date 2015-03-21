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

      context "enums" do
        before(:each) do
          @genres = %w(horror comedy romcom)
          @definition = {
            title: "films",
            type: Object,
            properties: {
              genre: {
                enum: @genres
              }
            }
          }
        end

        it "returns enum value" do
          film = { genre: @genres.sample }
          schema = Schema.new(@definition)
          schema.serialize!(film).should == film
        end

        it "does not validate enum value" do
          film = { genre: "not-defined-genre" }
          schema = Schema.new(@definition)
          schema.serialize!(film).should == film
        end
      end
    end

    describe "required" do
      it "can be set with draft-3 HashAttribute-level keyword" do
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

      it "is silently ignores draft-3 boolean requires" do
        draft_3_definition = {
          type: Object,
          required: true,
          properties: {
            title: { type: String }
          }
        }

        expect {
          Schema.new(draft_3_definition).render!
        }.to_not raise_error
      end
    end
  end
end
