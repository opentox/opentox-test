require 'test/unit'
require_relative "setup.rb"

begin
  puts "Service URI is: #{$algorithm[:uri]}"
rescue
  puts "Configuration Error: $algorithm[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class AlgorithmTest < Test::Unit::TestCase

  def test_01_openbabel_single
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor","openbabel","logP"), @@subjectid
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal 1, d.data_entries.size
    assert_equal 1, d.data_entries[0].size
    assert_equal 1.12518, d.data_entries[0][0]
    d.delete
  end

  def test_02_cdk_single
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor","cdk","AtomCountDescriptor"), @@subjectid
    c = OpenTox::Compound.from_smiles "c1ccccc1"
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal 12, d.data_entries[0][0]
    d.delete
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal 17, d.data_entries[0][0]
    d.delete
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor","cdk","CarbonTypesDescriptor"), @@subjectid
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal [1.0, 0.0, 0.0, 1.0, 0.0, 2.0, 1.0, 1.0, 0.0], d.data_entries[0]
    d.delete
  end

  def test_03_joelib_single
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor","joelib","LogP"), @@subjectid
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    d = OpenTox::Dataset.new(a.run :compound_uri => c.uri)
    assert_equal 2.6590800000000003, d.data_entries[0][0]
    d.delete
  end

  def test_04_all
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor"), @@subjectid
    c = OpenTox::Compound.from_smiles "CC(=O)CC(C)C#N"
    dataset_uri = a.run :compound_uri => c.uri
    d = OpenTox::Dataset.new dataset_uri
    assert_equal 356, d.data_entries[0].size
    d.delete
  end

  def test_05_dataset
    a = OpenTox::Algorithm.new File.join($algorithm[:uri],"descriptor"), @@subjectid
    dataset = OpenTox::Dataset.new nil, @@subjectid
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    result_uri = a.run :dataset_uri => dataset.uri
    d = OpenTox::Dataset.new result_uri
    assert_equal dataset.compounds.size, d.data_entries.size
    assert_equal 356, d.data_entries[0].size
    d.delete
  end

  def test_05_selection
  end

  def test_unique
  end

  def test_concurrent
    # parallel access to algorithm service
  end

end
