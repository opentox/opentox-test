require 'minitest/autorun'
require 'openbabel'
all = Dir["test/*.rb"]
exclude = [
  "test/setup.rb",
  "test/authorization.rb",
  "test/policy.rb",
  "test/lazarweb.rb",
  "test/pc-lazar.rb",
] + Dir["test/toxbank*.rb"]
(all - exclude).each {|f| require_relative f }
