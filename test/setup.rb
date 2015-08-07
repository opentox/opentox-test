require 'minitest/autorun'
require 'bundler'
Bundler.require
require 'opentox-client'
#require File.join(ENV["HOME"],".opentox","config","test.rb")

include OpenTox
TEST_DIR ||= File.expand_path(File.dirname(__FILE__))
DATA_DIR ||= File.join(TEST_DIR,"data")
#$mongo.database.drop
