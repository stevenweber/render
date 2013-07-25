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

    describe "#fetch" do
      it "raises KeyErrors" do
        lambda {
          DottableHash.new.fetch("non_existent_key")
        }.should raise_error
      end

      it "returns dottable_hashs in lieu of hashes" do
        @dottable_hash["nested_hash"] = { "foo" => "bar" }
        @dottable_hash.fetch("nested_hash").class.should == DottableHash
      end

      it "returns value of corresponding key object" do
        @dottable_hash["foo"] = "bar"
        @dottable_hash.fetch("foo").should == "bar"
      end

    end

    describe "#fetch_path[!]" do
      it "returns value of corresponding key object" do
        @dottable_hash["foo"] = "bar"
        @dottable_hash.fetch_path("foo").should == "bar"
      end

      it "returns value of expanded key object" do
        @dottable_hash["foo"] = { "bar" => "baz" }
        @dottable_hash.fetch_path("foo.bar").should == "baz"
      end

      it "raises key errors for nonexistent hashes" do
        expect {
          @dottable_hash.fetch_path!("foo")
        }.to raise_error(KeyError)
      end

      it "raises key errors when searching into a string" do
        @dottable_hash["foo"] = "bar"
        expect {
          @dottable_hash.fetch_path!("foo.bar")
        }.to raise_error(KeyError)
      end

      it "does not raise errors for dottable_hashs with suppressed key errors" do
        expect {
          @dottable_hash.fetch_path("foo")
        }.not_to raise_error

        @dottable_hash["foo"] = "bar"
        expect {
          @dottable_hash.fetch_path("foo.bar")
        }.not_to raise_error
      end
    end

    describe "#set_path!" do
      it "sets key's corresponding value" do
        @dottable_hash.set_path!("foo", "bar")
        @dottable_hash[:foo].should == "bar"
      end

      it "sets values for nested paths" do
        @dottable_hash.set_path!("foo.bar.baz", "i'm really in here!")
        {
          :foo => {
            :bar => {
              :baz => "i'm really in here!"
            }
          }
        }.should == @dottable_hash
      end

      it "does not overwrite the root key" do
        @dottable_hash.set_path!("foo.bar", "bar")
        @dottable_hash.set_path!("foo.baz.one", "baz1")
        @dottable_hash.set_path!("foo.baz.two", "baz2")
        {
          :foo => {
            :bar => "bar",
            :baz => {
              :one => "baz1",
              :two => "baz2"
            }
          }
        }.should == @dottable_hash
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
