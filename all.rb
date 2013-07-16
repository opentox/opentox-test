require 'test/unit'
(Dir["test/*.rb"] - Dir["test/*setup.rb"]).each { |f| require File.join(File.dirname(__FILE__),f) }
