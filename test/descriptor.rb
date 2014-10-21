require_relative "setup.rb"

begin
  puts "Service URI is: #{$algorithm[:uri]}"
rescue
  puts "Configuration Error: $algorithm[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class DescriptorTest < MiniTest::Test

  def test_list
    skip "TODO: Test descriptor list"
  end

  def test_lookup
    skip "TODO: Test descriptor lookup"
  end

  def test_smarts
    c = OpenTox::Compound.from_smiles "N=C=C1CCC(=F=FO)C1"
    result = OpenTox::Algorithm::Descriptor.smarts_match c, "FF"
    assert_equal 1, result[c.uri]["FF"]
    smarts = {"CC"=>1, "C"=>1, "C=C"=>1, "CO"=>0, "FF"=>1, "C1CCCC1"=>1, "NN"=>0}
    result = OpenTox::Algorithm::Descriptor.smarts_match c, smarts.keys
    assert_equal smarts, result[c.uri]
    smarts_count = {"CC"=>10, "C"=>6, "C=C"=>2, "CO"=>0, "FF"=>2, "C1CCCC1"=>10, "NN"=>0}
    result = OpenTox::Algorithm::Descriptor.smarts_count c, smarts_count.keys
    assert_equal smarts_count, result[c.uri]
  end

  def test_compound_openbabel_single
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Openbabel.logP"]
    assert_equal 1, result[c.uri].size
    assert_equal 1.12518, result[c.uri]["Openbabel.logP"]
  end

  def test_compound_cdk_single
    c = OpenTox::Compound.from_smiles "c1ccccc1"
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Cdk.AtomCount"]
    assert_equal 12, result[c.uri]["Cdk.AtomCount.nAtom"]
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Cdk.AtomCount"]
    assert_equal 17, result[c.uri]["Cdk.AtomCount.nAtom"]
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Cdk.CarbonTypes"]
    c_types = {"Cdk.CarbonTypes.C1SP1"=>1, "Cdk.CarbonTypes.C2SP1"=>0, "Cdk.CarbonTypes.C1SP2"=>0, "Cdk.CarbonTypes.C2SP2"=>1, "Cdk.CarbonTypes.C3SP2"=>0, "Cdk.CarbonTypes.C1SP3"=>2, "Cdk.CarbonTypes.C2SP3"=>1, "Cdk.CarbonTypes.C3SP3"=>1, "Cdk.CarbonTypes.C4SP3"=>0}
    assert_equal c_types, result[c.uri]
  end

  def test_compound_joelib_single
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Joelib.LogP"]
    assert_equal 2.65908, result[c.uri]["Joelib.LogP"]
  end

  def test_compound_all
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c
    assert_equal 332, result[c.uri].size
    {
      "Cdk.LongestAliphaticChain.nAtomLAC"=>5,
      "Joelib.count.HeavyBonds"=>7,
      "Openbabel.MR"=>30.905,
      #"Cdk.LengthOverBreadthDescriptor.LOBMAX"=>1.5379006098352144,
      #"Joelib.GeometricalShapeCoefficient"=>5.210533887682899,
    }.each do |d,v|
      assert_equal v, result[c.uri][d]
    end
  end

  def test_compound_descriptor_parameters
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, [ "Openbabel.logP", "Cdk.AtomCount", "Cdk.CarbonTypes", "Joelib.LogP" ]
    assert_equal 12, result[c.uri].size
    expect = {"Openbabel.logP"=>1.12518, "Cdk.AtomCount.nAtom"=>17, "Cdk.CarbonTypes.C1SP1"=>1, "Cdk.CarbonTypes.C2SP1"=>0, "Cdk.CarbonTypes.C1SP2"=>0, "Cdk.CarbonTypes.C2SP2"=>1, "Cdk.CarbonTypes.C3SP2"=>0, "Cdk.CarbonTypes.C1SP3"=>2, "Cdk.CarbonTypes.C2SP3"=>1, "Cdk.CarbonTypes.C3SP3"=>1, "Cdk.CarbonTypes.C4SP3"=>0, "Joelib.LogP"=>2.65908}
    assert_equal expect, result[c.uri]
  end

  def test_dataset_descriptor_parameters
    dataset = OpenTox::Dataset.new 
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.mini.csv")
    d = OpenTox::Algorithm::Descriptor.physchem dataset, [ "Openbabel.logP", "Cdk.AtomCount", "Cdk.CarbonTypes", "Joelib.LogP" ]
    assert_equal dataset.compounds.size, d.data_entries.size
    assert_equal 12, d.data_entries[0].size
    d.delete
  end

end
