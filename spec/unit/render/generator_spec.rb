require "render/generator"

module Render
  describe Generator do
    before(:each) do
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
  end
end
