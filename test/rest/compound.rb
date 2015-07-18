require_relative "setup.rb"

begin
  puts "Service URI is: #{$compound[:uri]}"
rescue
  puts "Configuration Error: $compound[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class CompoundTest < MiniTest::Test

  def test_compound_ambit
    c = OpenTox::Compound.new "https://apps.ideaconsult.net/ambit2/compound/144036"
    assert_equal "InChI=1S/C6H11NO2/c1-3-5-6(4-2)7(8)9/h5H,3-4H2,1-2H3", c.inchi
    assert_equal "CCC=C(CC)[N+](=O)[O-]", c.smiles
  end
end

class CompoundServiceTest < MiniTest::Test

  def test_formats # test supported formats from service
    formats = ["chemical/x-daylight-smiles", "chemical/x-inchi", "chemical/x-mdl-sdfile", "chemical/x-mdl-molfile", "image/png", "text/html"]
    formats.each do |format|
      response = OpenTox::RestClientWrapper.get "#{$compound[:uri]}/InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H", {}, { :accept => format }
      assert_equal format, response.headers[:content_type]
      assert_equal 200, response.code
    end
  end

end

class CompoundAPITest < MiniTest::Test

  def test_apifile # test if api file is present
    format = "application/json"
    response = OpenTox::RestClientWrapper.get "#{$compound[:uri]}/api/compound.json", {}, { :accept => format }
     assert_equal format, response.headers[:content_type]
     assert_equal 200, response.code
  end

  def test_swagger_valid
    res = OpenTox::RestClientWrapper.get "http://online.swagger.io/validator/debug?url=#{$compound[:uri]}/api/compound.json"
    assert_equal res, "[]", "Swagger API document #{$compound[:uri]}/api/compound.json is not valid: \n#{res}"
  end

end

