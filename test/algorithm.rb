require_relative "setup.rb"

begin
  puts "Service URI is: #{$algorithm[:uri]}"
rescue
  puts "Configuration Error: $algorithm[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class AlgorithmTest < MiniTest::Test

  def test_set_parameters
    a = OpenTox::Algorithm.new nil, SUBJECTID
    a.parameters = [
      {RDF::DC.title => "test", RDF::OT.paramScope => "mandatory"},
      {RDF::DC.title => "test2", RDF::OT.paramScope => "optional"}
    ]
    assert_equal 2, a.parameters.size
    assert_equal "mandatory", a.parameters.select{|p| p[RDF::DC.title] == "test"}.first[RDF::OT.paramScope]
  end
end
