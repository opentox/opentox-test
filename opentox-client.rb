require 'test/unit'
require 'openbabel'
all = Dir["test/*.rb"]
exclude = [
  "test/setup.rb",
  "test/lazarweb.rb",
  "test/descriptors.rb",
  "test/pc-lazar.rb",
] + Dir["test/toxbank*.rb"]
puts (all - exclude).inspect
(all - exclude).each {|f| require_relative f }
=begin
require './test/error.rb'
require './test/compound.rb'
require './test/task.rb'
require './test/feature.rb'
require './test/dataset.rb'
require './test/algorithm.rb'
require './test/model.rb'
require './test/dataset-large.rb'
require './test/lazar-fminer.rb'
#require './test/descriptors.rb'
#require './test/pc-lazar.rb'
#require './test/validation-short.rb'
#require './test/validation-long.rb'
=end
