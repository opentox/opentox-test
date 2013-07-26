require 'minitest/autorun'
require 'bundler'
Bundler.require
require 'opentox-client'
require File.join(ENV["HOME"],".opentox","config","test.rb")

TEST_DIR ||= File.expand_path(File.dirname(__FILE__))
DATA_DIR ||= File.join(TEST_DIR,"data")

unless $aa[:uri].to_s == ""
  OpenTox::Authorization.authenticate($aa[:user], $aa[:password])
  unauthorized_error "Failed to authenticate user \"#{$aa[:user]}\"." unless OpenTox::Authorization.is_token_valid
end
