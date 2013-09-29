require File.expand_path("../../initialize", __FILE__)
require "webmock/rspec"
require "support/helpers"

Render.logger = Logger.new("/dev/null")

RSpec.configure do |config|
  #
end
