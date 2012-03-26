require 'test/unit'
require 'bundler'
Bundler.require
require 'opentox-client'
require File.join(ENV["HOME"],".opentox","config","test.rb")

if defined? $aa
  @@subjectid = OpenTox::Authorization.authenticate($aa[:user], $aa[:password])
else
  @@subjectid = ""
end
