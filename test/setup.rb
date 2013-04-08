require 'test/unit'
require 'bundler'
Bundler.require
require 'opentox-client'
require File.join(ENV["HOME"],".opentox","config","test.rb")

TEST_DIR = File.expand_path(File.dirname(__FILE__))
DATA_DIR = File.join(TEST_DIR,"data")

RDF::TB  = RDF::Vocabulary.new "http://onto.toxbank.net/api/"
RDF::ISA = RDF::Vocabulary.new "http://onto.toxbank.net/isa/"

#begin
  unless $aa[:uri].to_s == ""
    $pi[:subjectid] = OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
    $secondpi[:subjectid] = OpenTox::Authorization.authenticate($secondpi[:name], $secondpi[:password])
  end
#rescue
  #puts "Authorization error: #{$!.message}"
  #exit
#end

# build subjectid for testuser: guestguest
#begin
  @@subjectid = nil
  unless $aa[:uri].to_s == ""
    @@subjectid = OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
    raise if !OpenTox::Authorization.is_token_valid(@@subjectid)
  end
#rescue
  #puts "Authorization error: #{$!.message}"
  #exit
#end
