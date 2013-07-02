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

  def test_match_smarts
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
    result = OpenTox::Algorithm::Descriptor.openbabel c, ["logP"]
    assert_equal 1, result[c.uri].size
    assert_equal 1.12518, result[c.uri]["logP"]
  end

  def test_compound_cdk_single
    c = OpenTox::Compound.from_smiles "c1ccccc1"
    result = OpenTox::Algorithm::Descriptor.cdk c, ["AtomCount"]
    assert_equal 12, result[c.uri]["nAtom"]
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.cdk c, ["AtomCount"]
    assert_equal 17, result[c.uri]["nAtom"]
    result = OpenTox::Algorithm::Descriptor.cdk c, ["CarbonTypes"]
    c_types = {"C1SP1"=>1, "C2SP1"=>0, "C1SP2"=>0, "C2SP2"=>1, "C3SP2"=>0, "C1SP3"=>2, "C2SP3"=>1, "C3SP3"=>1, "C4SP3"=>0}
    assert_equal c_types, result[c.uri]
  end

  def test_compound_joelib_single
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.joelib c, ["LogP"]
    puts result[c.uri]
    assert_equal 2.65908, result[c.uri]["LogP"]
  end

  def test_compound_all
    a = OpenTox::Algorithm::Generic.new File.join($algorithm[:uri],"descriptor"), SUBJECTID
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    dataset_uri = a.run :compound_uri => c.uri
    d = OpenTox::Dataset.new dataset_uri, SUBJECTID
    assert_equal 340, d.data_entries[0].size
    d.delete
  end

  def test_compound_descriptor_parameters
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result = OpenTox::Algorithm::Descriptor.physchem c, [ "openbabel.logP", "cdk.AtomCount", "cdk.CarbonTypes", "joelib.LogP" ]
    puts result.inspect
    assert_equal 12, result[0].size
    assert_equal [[1.12518, 17.0, 1.0, 0.0, 0.0, 1.0, 0.0, 2.0, 1.0, 1.0, 0.0, 2.65908]], result
  end

  def test_dataset_descriptor_parameters
    dataset = OpenTox::Dataset.new nil, SUBJECTID
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.mini.csv")
    d = OpenTox::Algorithm::Descriptor.physchem dataset, [ "openbabel.logP", "cdk.AtomCount", "cdk.CarbonTypes", "joelib.LogP" ]
    puts d.uri
    #d = OpenTox::Dataset.new result_uri, SUBJECTID
    assert_equal dataset.compounds.size, d.data_entries.size
    assert_equal 12, d.data_entries[0].size
    d.delete
  end

  def test_dataset_all
    a = OpenTox::Algorithm::Generic.new File.join($algorithm[:uri],"descriptor"), SUBJECTID
    dataset = OpenTox::Dataset.new nil, SUBJECTID
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.mini.csv")
    result_uri = a.run :dataset_uri => dataset.uri
    d = OpenTox::Dataset.new result_uri, SUBJECTID
    assert_equal dataset.compounds.size, d.data_entries.size
    assert_equal 340, d.data_entries[0].size
    d.delete
  end

end
