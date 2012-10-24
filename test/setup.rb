require 'test/unit'
require 'bundler'
Bundler.require
require 'opentox-client'
require File.join(ENV["HOME"],".opentox","config","test.rb")

begin
  $pi[:subjectid] = OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
  $secondpi[:subjectid] = OpenTox::Authorization.authenticate($secondpi[:name], $secondpi[:password])
rescue
  puts "Authorization error: #{$!.message}"
  exit
end

# build subjectid for testuser: guestguest
begin
  @@subjectid = nil
  unless $aa[:uri].to_s == ""
    @@subjectid = OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
    raise if !OpenTox::Authorization.is_token_valid(@@subjectid)
  end
rescue
  puts "Authorization error: #{$!.message}"
  exit
end
