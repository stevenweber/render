require "render/dottable_hash"

module Render
  describe DottableHash do
    before(:each) do
      @dottable_hash = DottableHash.new
    end

    describe "new" do
      it "creates from a hash" do
        dottable_hash = DottableHash.new({ "foo" => "bar" })
        dottable_hash.should == { :foo => "bar" }
      end

      it "initializes new hashes as dottable_hashes" do
        dottable_hash = DottableHash.new({ :foo => { :bar => "baz" } })
        dottable_hash[:foo].class.should == DottableHash
      end

      it "converts all keys to symbols" do
        dottable_hash = DottableHash.new({ "foo" => { "bar" => "baz" } })
        dottable_hash.keys.include?(:foo).should be_true
      end
    end

    describe "#[]" do
      it "converts keys to strings" do
        @dottable_hash[:foo] = "bar"
        @dottable_hash.keys.include?(:foo).should be_true
      end

      it "converts hash values to dottable_hashs" do
        @dottable_hash[:foo] = { bar: { baz: "baz" } }
        @dottable_hash.foo.bar.class.should == DottableHash
      end

      it "retrieves values by stringified keys" do
        @dottable_hash["foo"] = "bar"
        @dottable_hash[:foo].should == "bar"
      end

      it "converts hashes in arrays to dottable hashes" do
        pallet = DottableHash.new
        pallet.foo = [{ bar: "baz" }]
        pallet.foo.first.class.should == DottableHash
      end
    end

    describe "#delete" do
      it "symbolizes keys" do
        @dottable_hash["foo"] = { "bar" => "bar", "baz" => "baz" }
        @dottable_hash.foo.delete(:bar)
        @dottable_hash.should == { :foo => { :baz => "baz" } }
      end
    end

    describe ".has_key?" do
      it "converts symbols to strings" do
        DottableHash.new({ foo: "bar" }).has_key?(:foo).should == true
      end
    end

    describe "#method_missing" do
      it "returns value for key when it exists" do
        @dottable_hash[:foo] = "bar"
        @dottable_hash.foo.should == "bar"
      end

      it "raises an error when no key exists" do
        lambda {
          @dottable_hash.foo
        }.should raise_error(NoMethodError)
      end

      it "returns the same object as in the hash" do
        @dottable_hash[:foo] = { bar: "baz" }
        dottable_hash_object_id = @dottable_hash.foo.object_id
        @dottable_hash.foo.object_id.should == dottable_hash_object_id
      end

      it "sets values" do
        @dottable_hash.foo = "bar"
        @dottable_hash.foo.should == "bar"
      end
    end

    describe "dot access" do
      it "provides acess to keys as methods" do
        dottable_hash = DottableHash.new({ "foo" => "bar" })
        dottable_hash.foo.should == "bar"
      end

      it "provides acess to nested keys as methods" do
        dottable_hash = DottableHash.new({ "foo" => {"bar" => {"baz" => "bat"}}})
        dottable_hash.foo.bar.baz.should == "bat"
      end

      it "provides indifferent accesss" do
        dottable_hash = DottableHash.new({ :foo => {:bar => {"baz" => "bat"}}})
        dottable_hash.foo.bar.baz.should == "bat"
      end

      it "provides acess to keys with nil values" do
        dottable_hash = DottableHash.new({ "foo" => {"bar" => nil} })
        dottable_hash.foo.bar.should == nil
      end

      it "raises key error when it doesn't exist" do
        dottable_hash = DottableHash.new({ "foo" => "bar" })
        expect { dottable_hash.fu }.to raise_error(NoMethodError)
      end

      it "provides the dot access to a hash inside of an array" do
        dottable_hash = DottableHash.new({ "foo" => [{"bar" => "baz"}]})
        dottable_hash.foo.first.bar.should == "baz"
      end

      it "provides the dot access to to a list of strings inside an array" do
        dottable_hash = DottableHash.new({ "foo" => ["bar", "baz"]})
        dottable_hash.foo.should == ["bar", "baz"]
      end

      it "initializes hashes in nested arrays as dottable_hashs" do
        dottable_hash = DottableHash.new({ foo: [{ bar: [{ baz: "one" }] }] })
        dottable_hash.foo.first.bar.first.class.should == DottableHash
      end
    end

    describe "#merge!" do
      it "works with merged keys as symbols" do
        dottable_hash = DottableHash.new({ stuff: {} })
        dottable_hash.stuff.merge!({ things: "widgets" })
        dottable_hash.stuff.things.should == "widgets"
      end
    end

    describe "#merge" do
      it "works with merged keys as symbols" do
        dottable_hash = DottableHash.new({ stuff: {} })
        stuff_dottable_hash = dottable_hash.stuff.merge({ things: "widgets" })
        stuff_dottable_hash.things.should == "widgets"
      end
    end

  end
end
