require 'test/unit'
require 'bundler'
Bundler.require
require 'opentox-client'
require File.join(ENV["HOME"],".opentox","config","test.rb")

begin
  $pi[:subjectid] = OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
rescue
  puts "Authorization error: #{$!.message}"
  exit
end

# build subjectid for testuser: guestguest
begin
  $piGuest[:subjectid] = OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
rescue
  puts "Authorization error: #{$!.message}"
  exit
end
