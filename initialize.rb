%w(. ./lib/).each do |path|
  $: << path
end

Dir.glob("extensions/*").sort.each { |file| require file }

require "render"
