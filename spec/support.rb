require File.expand_path("../../initialize", __FILE__)
require "webmock/rspec"
require "support/helpers"

Render.logger = Logger.new("/dev/null")
Render.threading = false

RSpec.configure do |config|
  #
end
