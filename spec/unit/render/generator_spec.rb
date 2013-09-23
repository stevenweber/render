require "render/generator"

module Render
  describe Generator do
    it "exists" do
      expect { Generator }.to_not raise_error
    end

    describe "properties" do
      before(:each) do
        @mandatory_options = { algorithm: proc {} }
      end

      it "is a type-specific generator for flexibility" do
        Generator.new(@mandatory_options.merge({ type: String })).type.should == String
      end

      it "has a matcher to only be used on specific properties" do
        matcher = %r{.*name.*}
        Generator.new(@mandatory_options.merge({ matcher: matcher })).matcher.should == matcher
      end

      describe "#algorith" do
        it "has an algorithm that generates a value to be used" do
          algorithm = lambda { "The Darjeeling limited" }
          Generator.new({ algorithm: algorithm }).algorithm.should == algorithm
        end

        it "raises an error if algorithm does not respond to call" do
          expect {
            Generator.new({ algorithm: "want this to be the fake value" })
          }.to raise_error(Errors::Generator::MalformedAlgorithm)
        end
      end
    end

  end

end
