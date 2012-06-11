require 'test/unit'
require 'bundler'
Bundler.require
require 'opentox-client'
require File.join(ENV["HOME"],".opentox","config","test.rb")

begin
  AA = $aa[:uri]
  @@subjectid = OpenTox::Authorization.authenticate($aa[:user],$aa[:password]) #unless AA.empty?
  raise if !OpenTox::Authorization.is_token_valid(@@subjectid) #unless AA.empty?
  $pi[:subjectid] = OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
rescue
  puts "Configuration Error: $aa[:uri], $aa[:user] or $aa[:password] are not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end
