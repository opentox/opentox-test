require 'test/unit'
#$algorithm = {:uri => "http://webservices.in-silico.ch/algorithm"}
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

begin
  puts "Service URI is: #{$algorithm[:uri]}"
rescue
  puts "Configuration Error: $algorithm[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class AlgorithmTest < Test::Unit::TestCase

  def test_01_set_parameters
    a = OpenTox::Algorithm.new nil, @@subjectid
    a.parameters = [
      {RDF::DC.title => "test", RDF::OT.paramScope => "mandatory"},
      {RDF::DC.title => "test2", RDF::OT.paramScope => "optional"}
    ]
    assert_equal 2, a.parameters.size
    p = a.parameters.collect{|p| p if p[RDF::DC.title.to_s] == "test"}.compact.first
    assert_equal "mandatory", p[RDF::OT.paramScope.to_s] 
    puts a.to_turtle
  end
end
