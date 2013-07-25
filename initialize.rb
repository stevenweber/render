%w(. ./lib/).each do |path|
  $: << path
end

require "render"
