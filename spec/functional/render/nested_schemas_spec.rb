require "render/schema"

module Render
  describe Schema do
    before(:each) do
      Render.stub({ live: false })
    end

    it "parses nested schemas" do
      schema = {
        type: Object,
        properties: {
          contact: {
            type: Object,
            properties: {
              name: { type: String },
              phone: { type: String }
            }
          }
        }
      }

      contact_name = "Home"
      contact_phone = "9675309"
      data = {
        extraneous_name: "Tommy Tutone",
        contact: {
          name: contact_name,
          phone: contact_phone,
          extraneous_details: "aka 'Jenny'"
        }
      }

      Schema.new(schema).render!(data).should == {
        contact: {
          name: contact_name,
          phone: contact_phone
        }
      }
    end

    it "parses nested arrays" do
      schema = {
        type: Array,
        items: {
          type: Object,
          properties: {
            name: { type: String },
            nicknames: {
              type: Array,
              items: {
                type: Object,
                properties: {
                  name: { type: String },
                  age: { type: Integer }
                }
              }
            }
          }
        }
      }

      zissou = {
        name: "Steve Zissou",
        nicknames: [
          { name: "Stevezies", age: 2 },
          { name: "Papa Steve", age: 1 }
        ]
      }
      ned = {
        name: "Ned Plimpton",
        nicknames: [
          { name: "Kinsley", age: 4 }
        ]
      }
      people = [zissou, ned]

      Schema.new(schema).render!(people).should == [
        {
          name: "Steve Zissou",
          nicknames: [
            { name: "Stevezies", age: 2 },
            { name: "Papa Steve", age: 1 }
          ]
        },
        {
          name: "Ned Plimpton",
          nicknames: [
            { name: "Kinsley", age: 4 }
          ]
        }
      ]
    end
  end
end
