require_relative "setup.rb"

begin
  puts "Service URI is: #{$compound[:uri]}"
rescue
  puts "Configuration Error: $compound[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class CompoundTest < MiniTest::Test

  def test_0_compound_from_smiles
    c = OpenTox::Compound.from_smiles "F[B-](F)(F)F.[Na+]"
    assert_equal "InChI=1S/BF4.Na/c2-1(3,4)5;/q-1;+1", c.inchi
    assert_equal "[B-](F)(F)(F)F.[Na+]", c.smiles, "A failure here might be caused by a compound webservice running on 64bit architectures using an outdated version of OpenBabel. Please install OpenBabel version 2.3.2 or higher." # seems to be fixed in 2.3.2
  end

  def test_1_compound_from_smiles
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    assert_equal "InChI=1S/C6H9NO/c1-5(4-7)3-6(2)8/h5H,3H2,1-2H3", c.inchi
    assert_equal "CC(CC(=O)C)C#N", c.smiles
  end

  def test_2_compound_from_smiles
    c = OpenTox::Compound.from_smiles "N#[N+]C1=CC=CC=C1.F[B-](F)(F)F"
    assert_equal "InChI=1S/C6H5N2.BF4/c7-8-6-4-2-1-3-5-6;2-1(3,4)5/h1-5H;/q+1;-1", c.inchi
    assert_equal "c1ccc(cc1)[N+]#N.[B-](F)(F)(F)F", c.smiles
  end

  def test_compound_from_name
    c = OpenTox::Compound.from_name "Benzene"
    assert_equal "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H", c.inchi
    assert_equal "c1ccccc1", c.smiles
  end

  def test_compound_from_inchi
    c = OpenTox::Compound.from_inchi "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    assert_equal "c1ccccc1", c.smiles
  end

  def test_compound_ambit
    c = OpenTox::Compound.new "https://apps.ideaconsult.net/ambit2/compound/144036"
    assert_equal "InChI=1S/C6H11NO2/c1-3-5-6(4-2)7(8)9/h5H,3-4H2,1-2H3", c.inchi
    assert_equal "CCC=C(CC)[N+](=O)[O-]", c.smiles
  end

  def test_compound_image
    c = OpenTox::Compound.from_inchi "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    puts c.uri
    testbild = "/tmp/testbild.png"
    f = File.open(testbild, "w")
    f.puts c.png
    f.close
    assert_match "image/png", `file -b --mime-type /tmp/testbild.png`
    File.unlink(testbild)
    #assert_match /^\x89PNG/, c.png #32bit only?
  end

=begin
  # OpenBabel segfaults randomly during inchikey calculation
  def test_inchikey
    c = OpenTox::Compound.from_inchi "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    assert_equal "UHOVQNZJYSORNB-UHFFFAOYSA-N", c.inchikey
  end
=end

  def test_cid
    c = OpenTox::Compound.from_inchi "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    assert_equal "241", c.cid
  end

  def test_chemblid
    c = OpenTox::Compound.from_inchi "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    #assert_equal "CHEMBL277500", c.chemblid
    assert_equal "CHEMBL581676", c.chemblid
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
