require 'minitest/autorun'
require 'openbabel'
all = Dir["test/*.rb"]
exclude = [
  "test/*setup.rb",
  "test/lazarweb.rb",
] + Dir["test/toxbank*.rb"] + Dir["test/*long.rb"]
(all - exclude).each {|f| require_relative f }
