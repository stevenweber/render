require "render/generator"

module Render
  describe Generator do
    before(:each) do
      @original_generators = Render.generators.dup
    end

    after(:each) do
      Render.generators = @original_generators
    end

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

    it "adds generator to Render" do
      expect {
        Generator.new(UUID, /id/i, lambda { UUID.generate })
      }.to change { Render.generators.size }.by(1)
    end
  end
end
