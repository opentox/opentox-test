require 'minitest/autorun'
require 'openbabel'
all = Dir["test/*.rb"]
exclude = [
  "test/lazarweb.rb",
  "test/*setup.rb",
  "test/aop-curl.rb",
  "test/aopweb.rb",
] + Dir["test/toxbank*.rb"]
(all - exclude).each {|f| require_relative f }
