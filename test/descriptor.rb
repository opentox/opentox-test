require_relative "setup.rb"

class DescriptorTest < MiniTest::Test

  def test_list
    # check available descriptors
    @descriptors = OpenTox::Algorithm::Descriptor::DESCRIPTORS.keys
    assert_equal 111,@descriptors.size,"wrong num physchem descriptors"
    @descriptor_values = OpenTox::Algorithm::Descriptor::DESCRIPTOR_VALUES
    assert_equal 356,@descriptor_values.size,"wrong num physchem descriptors"
    sum = 0
    [ @descriptors, @descriptor_values ].each do |desc|
      {"Openbabel"=>16,"Cdk"=>(desc==@descriptors ? 50 : 295),"Joelib"=>45}.each do |k,v|
        assert_equal v,desc.select{|x| x=~/^#{k}\./}.size,"wrong num #{k} descriptors"
        sum += v
      end
    end
    assert_equal (111+356),sum
  end

  def test_smarts
    c = OpenTox::Compound.from_smiles "N=C=C1CCC(=F=FO)C1"
    result = OpenTox::Algorithm::Descriptor.smarts_match c, "FF"
    assert_equal [[1]], result
    smarts = ["CC", "C", "C=C", "CO", "FF", "C1CCCC1", "NN"]
    result = OpenTox::Algorithm::Descriptor.smarts_match c, smarts
    assert_equal [[1, 1, 1, 0, 1, 1, 0]], result
    smarts_count = [[10, 6, 2, 0, 2, 10, 0]]
    result = OpenTox::Algorithm::Descriptor.smarts_count c, smarts
    assert_equal smarts_count, result
  end

  def test_compound_openbabel_single
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Openbabel.logP"]
    assert_equal 1, result[0].size
    assert_equal 1.12518, result[0][0]
  end

  def test_compound_cdk_single
    c = OpenTox::Compound.from_smiles "c1ccccc1"
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Cdk.AtomCount"]
    assert_equal 12, result[c]["Cdk.AtomCount.nAtom"]
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Cdk.AtomCount"]
    assert_equal 17, result[c]["Cdk.AtomCount.nAtom"]
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Cdk.CarbonTypes"]
    c_types = {"Cdk.CarbonTypes.C1SP1"=>1, "Cdk.CarbonTypes.C2SP1"=>0, "Cdk.CarbonTypes.C1SP2"=>0, "Cdk.CarbonTypes.C2SP2"=>1, "Cdk.CarbonTypes.C3SP2"=>0, "Cdk.CarbonTypes.C1SP3"=>2, "Cdk.CarbonTypes.C2SP3"=>1, "Cdk.CarbonTypes.C3SP3"=>1, "Cdk.CarbonTypes.C4SP3"=>0}
    assert_equal c_types, result[c]
  end

  def test_compound_joelib_single
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, ["Joelib.LogP"]
    assert_equal 2.65908, result[c]["Joelib.LogP"]
  end

  def test_compound_all
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c
    assert_equal 332, result[c].size
    {
      "Cdk.LongestAliphaticChain.nAtomLAC"=>5,
      "Joelib.count.HeavyBonds"=>7,
      "Openbabel.MR"=>30.905,
      #"Cdk.LengthOverBreadthDescriptor.LOBMAX"=>1.5379006098352144,
      #"Joelib.GeometricalShapeCoefficient"=>5.210533887682899,
    }.each do |d,v|
      assert_equal v, result[c][d]
    end
  end

  def test_compound_descriptor_parameters
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, [ "Openbabel.logP", "Cdk.AtomCount", "Cdk.CarbonTypes", "Joelib.LogP" ]
    assert_equal 12, result[c].size
    expect = {"Openbabel.logP"=>1.12518, "Cdk.AtomCount.nAtom"=>17, "Cdk.CarbonTypes.C1SP1"=>1, "Cdk.CarbonTypes.C2SP1"=>0, "Cdk.CarbonTypes.C1SP2"=>0, "Cdk.CarbonTypes.C2SP2"=>1, "Cdk.CarbonTypes.C3SP2"=>0, "Cdk.CarbonTypes.C1SP3"=>2, "Cdk.CarbonTypes.C2SP3"=>1, "Cdk.CarbonTypes.C3SP3"=>1, "Cdk.CarbonTypes.C4SP3"=>0, "Joelib.LogP"=>2.65908}
    assert_equal expect, result[c]
  end

  def test_dataset_descriptor_parameters
    dataset = OpenTox::Dataset.new 
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.mini.csv")
    d = OpenTox::Algorithm::Descriptor.physchem dataset, [ "Openbabel.logP", "Cdk.AtomCount", "Cdk.CarbonTypes", "Joelib.LogP" ]
    assert_equal dataset.compounds.size, d.keys.size
    assert_equal 12, d.first.last.size
  end

end
