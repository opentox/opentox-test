require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

begin
  puts "Service URI is: #{$compound[:uri]}"
rescue
  puts "Configuration Error: $compound[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class CompoundTest < Test::Unit::TestCase

  def test_0_compound_from_smiles
    c = OpenTox::Compound.from_smiles $compound[:uri], "F[B-](F)(F)F.[Na+]"
    puts c.inspect
    assert_equal "InChI=1S/BF4.Na/c2-1(3,4)5;/q-1;+1", c.inchi
    assert_equal "[Na+].F[B-](F)(F)F", c.smiles, "A failure here might be caused by a compound webservice running on 64bit architectures. This is a known bug in OpenBabel which drops positive charges on 64bit machines. The only known workaround is to install the compound webservice on a 32bit machine" # still does not work on 64bit machines
  end

  def test_1_compound_from_smiles
    c = OpenTox::Compound.from_smiles $compound[:uri], "CC(=O)CC(C)C#N"
    assert_equal "InChI=1S/C6H9NO/c1-5(4-7)3-6(2)8/h5H,3H2,1-2H3", c.inchi
    assert_equal "CC(CC(=O)C)C#N", c.smiles
  end

  def test_2_compound_from_smiles
    c = OpenTox::Compound.from_smiles $compound[:uri], "N#[N+]C1=CC=CC=C1.F[B-](F)(F)F"
    assert_equal "InChI=1S/C6H5N2.BF4/c7-8-6-4-2-1-3-5-6;2-1(3,4)5/h1-5H;/q+1;-1", c.inchi
    assert_equal "c1ccc(cc1)[N+]#N.[B-](F)(F)(F)F", c.smiles
  end

  def test_compound_from_name
    c = OpenTox::Compound.from_name $compound[:uri], "Benzene"
    assert_equal "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H", c.inchi
    assert_equal "c1ccccc1", c.smiles
  end

  def test_compound_from_inchi
    c = OpenTox::Compound.from_inchi $compound[:uri], "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    assert_equal "c1ccccc1", c.smiles
  end

  def test_compound_ambit
    c = OpenTox::Compound.new "http://apps.ideaconsult.net:8080/ambit2/compound/144036"
    assert_equal "InChI=1S/C6H11NO2/c1-3-5-6(4-2)7(8)9/h5H,3-4H2,1-2H3", c.inchi
    assert_equal "CCC=C(CC)[N+](=O)[O-]", c.smiles
  end

  def test_compound_image
    c = OpenTox::Compound.from_inchi $compound[:uri], "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    testbild = "/tmp/testbild.png"
    f = File.open(testbild, "w").puts c.png
    assert_match "image/png", `file -b --mime-type /tmp/testbild.png`
    File.unlink(testbild)
    #assert_match /^\x89PNG/, c.png #32bit only?
  end

=begin
  # OpenBabel segfaults randomly durng inchikey calculation
  def test_inchikey
    c = OpenTox::Compound.from_inchi $compound[:uri], "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    assert_equal "UHOVQNZJYSORNB-UHFFFAOYSA-N", c.inchikey
  end
=end

  def test_cid
    c = OpenTox::Compound.from_inchi $compound[:uri], "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    assert_equal "241", c.cid
  end

  def test_chemblid
    c = OpenTox::Compound.from_inchi $compound[:uri], "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    assert_equal "CHEMBL277500", c.chemblid
  end

=begin
  def test_match_hits
    c = OpenTox::Compound.from_smiles $compound[:uri], "N=C=C1CCC(=F=FO)C1"
    assert_equal ({"FF"=>2, "CC"=>10, "C"=>6, "C1CCCC1"=>10, "C=C"=>2}), c.match_hits(['CC','F=F','C','C=C','FF','C1CCCC1','OO'])
  end
=end
end
