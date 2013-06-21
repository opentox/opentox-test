require 'minitest/autorun'
require 'openbabel'
all = Dir["test/*.rb"]
exclude = [
  "test/setup.rb",
  "test/descriptors.rb",
  "test/lazar-pc-descriptors.rb",
  "test/lazar-extended.rb",
  "test/validation-long.rb",
  "test/dataset-large.rb",
  "test/lazarweb.rb",
  "test/pc-lazar.rb",
] + Dir["test/toxbank*.rb"]
(all - exclude).each {|f| require_relative f }
