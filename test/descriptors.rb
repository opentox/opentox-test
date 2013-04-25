require_relative "setup.rb"

begin
  puts "Service URI is: #{$algorithm[:uri]}"
rescue
  puts "Configuration Error: $algorithm[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class DescriptorTest < MiniTest::Unit::TestCase

  def test_compound_openbabel_single
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor","openbabel","logP"), @@subjectid
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal 1, d.data_entries.size
    assert_equal 1, d.data_entries[0].size
    assert_equal 1.12518, d.data_entries[0][0]
    d.delete
  end

  def test_compound_cdk_single
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor","cdk","AtomCount"), @@subjectid
    c = OpenTox::Compound.from_smiles "c1ccccc1"
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal 12, d.data_entries[0][0]
    d.delete
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal 17, d.data_entries[0][0]
    d.delete
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor","cdk","CarbonTypes"), @@subjectid
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal [1.0, 0.0, 0.0, 1.0, 0.0, 2.0, 1.0, 1.0, 0.0], d.data_entries[0]
    d.delete
  end

  def test_compound_joelib_single
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor","joelib","LogP"), @@subjectid
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal 2.65908, d.data_entries[0][0]
    d.delete
  end

  def test_compound_all
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor"), @@subjectid
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    dataset_uri = a.run :compound_uri => c.uri
    d = OpenTox::Dataset.new dataset_uri
    assert_equal 340, d.data_entries[0].size
    d.delete
  end

  def test_compound_descriptor_parameters
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor"), @@subjectid
    descriptor_uris = [
      File.join($algorithm[:uri],"descriptor","openbabel","logP"),
      File.join($algorithm[:uri],"descriptor","cdk","AtomCount"),
      File.join($algorithm[:uri],"descriptor","cdk","CarbonTypes"),
      File.join($algorithm[:uri],"descriptor","joelib","LogP"),
    ]
    compound = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    result_uri = a.run :compound_uri => compound.uri, :descriptor_uris => descriptor_uris
    d = OpenTox::Dataset.new result_uri
    assert_equal 12, d.features.size
    assert_equal 12, d.data_entries[0].size
    assert_equal [[1.12518, 17.0, 1.0, 0.0, 0.0, 1.0, 0.0, 2.0, 1.0, 1.0, 0.0, 2.65908]], d.data_entries
    d.delete
  end

  def test_dataset_descriptor_parameters
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor"), @@subjectid
    descriptor_uris = [
      File.join($algorithm[:uri],"descriptor","openbabel","logP"),
      File.join($algorithm[:uri],"descriptor","cdk","AtomCount"),
      File.join($algorithm[:uri],"descriptor","cdk","CarbonTypes"),
      File.join($algorithm[:uri],"descriptor","joelib","LogP"),
    ]
    dataset = OpenTox::Dataset.new nil, @@subjectid
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.mini.csv")
    result_uri = a.run :dataset_uri => dataset.uri, :descriptor_uris => descriptor_uris
    d = OpenTox::Dataset.new result_uri
    assert_equal dataset.compounds.size, d.data_entries.size
    assert_equal 12, d.data_entries[0].size
    d.delete
  end

  def test_dataset_all
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor"), @@subjectid
    dataset = OpenTox::Dataset.new nil, @@subjectid
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.mini.csv")
    result_uri = a.run :dataset_uri => dataset.uri
    d = OpenTox::Dataset.new result_uri
    assert_equal dataset.compounds.size, d.data_entries.size
    assert_equal 340, d.data_entries[0].size
    d.delete
  end

end
