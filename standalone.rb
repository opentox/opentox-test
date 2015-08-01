require 'minitest/autorun'
[
  "feature",
  "algorithm",
  "compound",
  "dataset-long",
  "dataset",
  "descriptor-long",
  "descriptor",
  "edit_objects",
  "error",
  "fminer",
  "lazar-fminer",
  "lazar-long",
#"lazar-models",
  "lazar-physchem-long",
  "lazar-physchem-short",
#"lazarweb",
  #"task",
  #"validation-long",
  #"validation-short",
  #"validation_util",*
].each {|t| require_relative File.join("test", t+".rb")}

#require './test/store_query.rb'
#require './test/authorization.rb'
#require './test/policy.rb'
