module Render
  describe Attribute do
    context "generators" do
      before(:each) do
        @original_generators = Generator.instances.dup
        Render.stub({ live: false })
      end

      after(:each) do
        Generator.instances = @original_generators
      end

      describe "#default_value" do
        it "returns default value defined by schema" do
          schema_default = "foo"
          attribute = HashAttribute.new({ name: { type: String, default: schema_default } })

          Render.stub({ live: false })
          attribute.default_value.should == schema_default
          Render.stub({ live: true })
          attribute.default_value.should == schema_default
        end

        it "returns fake data from matching generator" do
          name = "Canada Dry"
          Generator.create!(String, %r{.*name.*}, proc { name })

          HashAttribute.new({ name: { type: String } }).default_value.should == name
        end

        it "generates fake data for all standard JSON types" do
          # Objects' and Arrays' fake data comes from their attributes.

          string_attribute = HashAttribute.new({ name: { type: "string" } })
          string_attribute.default_value.should be_a(String)

          number_attribute = HashAttribute.new({ name: { type: "number" } })
          number_attribute.default_value.should be_a(Float)

          boolean_attribute = HashAttribute.new({ name: { type: "boolean" } })
          [true, false].should include(boolean_attribute.default_value)

          Render.logger.should_not_receive(:warn)
          null_attribute = HashAttribute.new({ name: { type: "null" } })
          null_attribute.default_value.should == nil
        end

        it "generates fake data for all standard JSON formats" do
          hostname_attribute = HashAttribute.new({ name: { format: "hostname" } })
          hostname_attribute.default_value.should eq("localhost")

          ipv4_attribute = HashAttribute.new({ name: { format: "ipv4" } })
          ipv4_attribute.default_value.should eq("127.0.0.1")

          ipv6_attribute = HashAttribute.new({ name: { format: "ipv6" } })
          ipv6_attribute.default_value.should eq("::1")

          date_time = DateTime.now
          DateTime.stub({ now: date_time })
          date_time_attribute = HashAttribute.new({ name: { format: "date-time" } })
          date_time_attribute.default_value.should eq(date_time.to_s)

          email_attribute = HashAttribute.new({ name: { format: "email" } })
          email_attribute.default_value.should eq("you@localhost")

          email_attribute = HashAttribute.new({ name: { format: "uri" } })
          email_attribute.default_value.should eq("http://localhost")
        end

        it "generates fake data for enums" do
          enum_values = ["foo", "bar"]
          enum_attribute = HashAttribute.new({ name: { enum: enum_values } })
          enum_values.should include(enum_attribute.default_value)
        end

        it "biases format's generator to type's generator" do
          ipv6_attribute = HashAttribute.new({ name: { type: String, format: "ipv6" } })
          ipv6_attribute.default_value.should eq("::1")
        end

      end
    end
  end
end
