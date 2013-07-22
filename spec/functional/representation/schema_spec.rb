require "representation/schema"

module Representation
  describe Schema do
    before(:each) do
      Representation.stub({ live: false })
    end

    it "parses hash data" do
      schema = Schema.new({
        title: "television",
        type: Object,
        attributes: {
          brand: { type: String }
        }
      })

      brand_name = "Sony"
      response = { brand: brand_name }

      schema.pull(response).should == {
        television: { brand: brand_name }
      }
    end

    it "parses simple arrays" do
      schema = Schema.new({
        title: "televisions",
        type: Array,
        elements: {
          type: UUID
        }
      })

      television_ids = rand(10).times.collect { UUID.generate }

      schema.pull(television_ids).should == {
        televisions: television_ids
      }
    end

    it "parses arrays of objects" do
      schema = Schema.new({
        title: :televisions,
        type: Array,
        elements: {
          title: :television,
          type: Object,
          attributes: {
            brand: { type: String }
          }
        }
      })

      brand_1, brand_2 = *%w(Sony Samsung)
      response = [{ brand: brand_1 }, { brand: brand_2 }]

      schema.pull(response).should == {
        televisions: [{ brand: brand_1 }, { brand: brand_2 }]
      }
    end

    it "parses nested object data" do
      schema = Schema.new({
        title: :television,
        type: Object,
        attributes: {
          brand: {
            title: :brand,
            type: Object,
            attributes: {
              name: { type: String }
            }
          }
        }
      })

      brand_name = "Sony"
      response = { brand: { name: brand_name } }

      schema.pull(response).should == {
        television: { brand: { name: brand_name } }
      }
    end
  end
end
