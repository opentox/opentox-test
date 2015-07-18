require_relative "setup.rb"

begin
  puts "Service URI is: #{$algorithm[:uri]}"
rescue
  puts "Configuration Error: $algorithm[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class AlgorithmTest < MiniTest::Test

  def test_set_parameters
    a = OpenTox::Algorithm::Generic.new 
    a.parameters = [
      {"title" => "test", "paramScope" => "mandatory"},
      {"title" => "test2", "paramScope" => "optional"}
    ]
    p a
    assert_equal 2, a.parameters.size
    assert_equal "mandatory", a.parameters.select{|p| p["title"] == "test"}.first["paramScope"]
  end
end
