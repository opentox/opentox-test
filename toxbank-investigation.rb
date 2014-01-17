require "minitest/autorun"
Dir["test/toxbank*.rb"].each { |f| require File.join(File.dirname(__FILE__),f) }
