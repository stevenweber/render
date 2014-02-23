require "render/generator"

module Render
  describe Generator do
    before(:each) do
      Render.stub({ live: false })
      @original_generators = Generator.instances.dup
    end

    after(:each) do
      Generator.instances = @original_generators
    end

    describe ".create!" do
      it "adds generator to Render" do
        expect {
          Generator.create!(UUID, /id/i, lambda { UUID.generate })
        }.to change { Generator.instances.size }.by(1)
      end

      it "preferences newer generators" do
        Generator.instances.clear

        first_generator = Generator.create!(String, /.*/, proc { "first" })
        second_generator = Generator.create!(String, /.*/, proc { "second" })
        Generator.find(String, :anything).trigger.should == second_generator.trigger
      end
    end

    describe ".trigger" do
      context "no generator" do
        it "returns nil" do
          attribute = double(:attribute, { name: "foo" })
          Generator.trigger(:foo, "_to_match", attribute).should == nil
        end

        it "warns" do
          Render.logger.should_receive(:warn).with(/find.*generator.*foo.*_to_match/i)

          attribute = double(:attribute, { name: "foo" })
          Generator.trigger(:foo, "_to_match", attribute).should == nil
        end
      end

      it "triggers matching generator for Render types" do
        enum_attribute = HashAttribute.new({ name: { type: String, enum: ["foo"] } })
        Generator.trigger(enum_attribute.bias_type, "anything", enum_attribute).should == "foo"
      end
    end

    describe "#initialize" do
      it "sets the type of data it can be used to generate data for" do
        type = [UUID, Float].sample
        Generator.new(type, nil, proc {}).type.should == type
      end

      it "sets a matcher to classify what attribute-name(s) it should be used for" do
        matcher = %r{film_title.*}i
        Generator.new(String, matcher, proc {}).matcher.should == matcher
      end

      it "sets an algorithm to be used to generate values" do
        algorithm = lambda { UUID.generate }
        Generator.new(UUID, //, algorithm).algorithm.should == algorithm
      end

      it "guarantees algorithm responds to #call for real-time value generation" do
        algorithm = UUID.generate
        expect {
          Generator.new(UUID, //, algorithm)
        }.to raise_error(Errors::Generator::MalformedAlgorithm)
      end
    end

    describe "#trigger" do
      it "calls algorithm" do
        x = "foo"
        algorithm = proc { |y| "algorithm called with #{y}" }
        Generator.new(UUID, //, algorithm).trigger(x).should == algorithm.call(x)
      end
    end

    describe "default set" do
      it "adheres to minLength" do
        min_length = 100
        attribute = HashAttribute.new({ name: { type: String, minLength: min_length } })
        value = Generator.trigger(String, "_to_match", attribute)
        value.length.should >= min_length
      end

      it "adheres to maxLength" do
        max_length = 2
        attribute = HashAttribute.new({ name: { type: String, maxLength: max_length } })
        value = Generator.trigger(String, "_to_match", attribute)
        value.length.should <= max_length
      end
    end
  end
end
