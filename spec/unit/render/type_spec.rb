require "render/type"

module Render
  describe Type do
    before(:each) do
      @original_types = Type.instances.dup
    end

    after(:each) do
      Type.instances = @original_types
    end

    describe ".parse" do
      it "returns constant for string" do
        Type.parse("integer").should == Integer
      end

      it "returns constant for symbols" do
        Type.parse(:integer).should == Integer
      end

      it "returns nil if no type is found" do
        Type.parse("not-a-type").should == nil
      end
    end

    describe ".parse!" do
      it "returns ruby classes for standard json types" do
        Type.parse!("string").should == String
        Type.parse!("number").should == Float
        Type.parse!("integer").should == Integer
        Type.parse!("object").should == Object
        Type.parse!("array").should == Array
        Type.parse!("boolean").should == Type::Boolean
        Type.parse!("null").should == NilClass
      end

      it "returns ruby classes for standard json formats" do
        Type.parse!("uri").should == URI
        Type.parse!("date-time").should == DateTime
        Type.parse!("ipv4").should == Type::IPv4
        Type.parse!("ipv6").should == Type::IPv6
        Type.parse!("email").should == Type::Email
        Type.parse!("hostname").should == Type::Hostname
      end

      it "returns constant for string" do
        Type.parse("integer").should == Integer
      end

      it "returns argument when not a string" do
        class ::Foo; end
        Type.parse(Foo).should == Foo
        Object.__send__(:remove_const, :Foo)
      end

      it "raises meaningful error for unmatched types" do
        expect {
          Type.parse!("NotAClass")
        }.to raise_error(Render::Errors::InvalidType)
      end

      describe "non-standard formats" do
        it "maps regardless of capitalization" do
          string_representations = %w(uuid UUID)
          string_representations.each do |name|
            Type.parse(name).should == UUID
          end
        end

        it "returns UUID for uuid" do
          Type.parse("uUId").should == UUID
        end
      end
    end

    describe ".find" do
      it "returns Render's custom types" do
        Type.find(:boolean).should == Render::Type::Boolean
      end

      it "returns falsie when no type is found" do
        Type.find(:foo).should_not be
      end

      describe "user types" do
        before(:each) do
          @original_types = Type.instances.dup
          module ::Foo; module Boolean; end; end
          Type.add!(:boolean, Foo::Boolean)
        end

        after(:each) do
          Type.instances = @original_types
          Object.__send__(:remove_const, :Foo)
        end

        it "is returned instead of Render's" do
          Type.find(:boolean).should == Foo::Boolean
        end
      end
    end

    describe ".to" do
      it "maintains nil values" do
        Type.to([Float], nil).should == nil
      end

      it "returns nil for undefined classes" do
        Type.to([nil], {}).should == nil
      end

      it "converts to floats" do
        Type.to([Float], "2").should == 2
      end

      it "converts to Integers" do
        Type.to([Integer], "1.2").should == 1
      end

      it "converts to Strings" do
        Type.to([String], 2).should == "2"
      end

      describe "enum" do
        it "returns valid enum" do
          enums = [:foo, :bar]
          Type.to([Type::Enum], :foo, enums).should == :foo
        end

        it "return nil for invalid enums" do
          enums = [:foo]
          Type.to([Type::Enum], :bar, enums).should == nil
        end
      end

      describe "boolean" do
        it "converts strings" do
          Type.to([Type::Boolean], "true").should eq(true)
          Type.to([Type::Boolean], "false").should eq(false)
        end

        it "returns nil for invalid booleans" do
          Type.to([Type::Boolean], "foo").should == nil
        end
      end

      it "returns value for unknown types" do
        class Foo; end

        Type.to([Foo], :bar).should == :bar

        Render.send(:remove_const, :Foo)
      end

      context "multiple types" do
        it "returns value in original type if valid" do
          Type.to([Integer, Float], 2.0).should == 2.0
        end

        it "returns value of first class if original type is not valid" do
          Type.to([Integer, String], 2.0).should == 2
        end
      end

    end
  end
end
