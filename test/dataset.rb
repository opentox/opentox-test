require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
DATASET = "http://ot-dev.in-silico.ch/dataset"
DATA_DIR = File.join(File.dirname(__FILE__),"data")
# TODO: add subjectids

begin
  @@service_uri = $dataset[:uri]
  puts "Service URI is: #{@@service_uri}"
rescue
  puts "Configuration Error: $dataset[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class DatasetTest < Test::Unit::TestCase

  def test_all
    datasets = OpenTox::Dataset.all @@service_uri, @@subjectid
    assert_equal OpenTox::Dataset, datasets.first.class
  end

  def test_create_empty
    d = OpenTox::Dataset.create @@service_uri, @@subjectid
    assert_equal OpenTox::Dataset, d.class
    assert_match /#{@@service_uri}/, d.uri.to_s
    d.delete :subjectid => @@subjectid
  end

  def test_create_from_file
    d = OpenTox::Dataset.from_file @@service_uri, File.join(DATA_DIR,"EPAFHM.mini.csv"), @@subjectid
    assert_equal OpenTox::Dataset, d.class
    assert_equal d.uri, d[RDF::XSD.anyURI]
    assert_equal "EPAFHM.mini",  d.metadata[RDF::URI("http://purl.org/dc/elements/1.1/title")].first.to_s # DC.title is http://purl.org/dc/terms/title
    assert_equal "EPAFHM.mini",  d[RDF::URI("http://purl.org/dc/elements/1.1/title")]
    d.delete :subjectid => @@subjectid
    assert_raise OpenTox::NotFoundError do
      d.get
    end
  end

  def test_from_yaml
    @dataset = OpenTox::Dataset.from_file @@service_uri, File.join(DATA_DIR,"hamster_carcinogenicity.yaml"), @@subjectid
    assert_equal OpenTox::Dataset, @dataset.class
    assert_equal "hamster_carcinogenicity", @dataset[RDF::URI("http://purl.org/dc/elements/1.1/title")]
    hamster_carc?
    @dataset.delete :subjectid => @@subjectid
  end

=begin
# TODO: fix (mime type??0 and add Egons example
  def test_sdf_with_multiple_features
    @dataset = OpenTox::Dataset.from_file @@service_uri, "#{DATA_DIR}/CPDBAS_v5c_1547_29Apr2008part.sdf"
    assert_equal OpenTox::Dataset, @dataset.class
    puts @dataset.features.size
    puts @dataset.compounds.size
    @dataset.delete
  end
=end

  def test_multicolumn_csv
    @dataset = OpenTox::Dataset.from_file @@service_uri, "#{DATA_DIR}/multicolumn.csv", @@subjectid
    assert_equal 5, @dataset.features.size
    assert_equal 4, @dataset.compounds.size
    @dataset.delete :subjectid => @@subjectid
  end

  def test_from_csv
    @dataset = OpenTox::Dataset.from_file @@service_uri, "#{DATA_DIR}/hamster_carcinogenicity.csv", @@subjectid
    assert_equal OpenTox::Dataset, @dataset.class
    hamster_carc?
    @dataset.delete :subjectid => @@subjectid
  end

=begin
  def test_save
    d = OpenTox::Dataset.create @@service_uri
    d.metadata
    d.metadata[RDF::DC.title] = "test"
    d.save
    # TODO: save does not work with datasets
    #puts d.response.code.inspect
    #assert_equal "test", d.metadata[RDF::DC.title] # should reload metadata
    d.delete
  end
=end
=begin
=end


  def hamster_carc?
    assert_kind_of OpenTox::Dataset, @dataset
    #require 'yaml'
    #puts @dataset.data_entries.to_yaml
    assert_equal 85, @dataset.data_entries.size
    assert_equal 85, @dataset.compounds.size
    assert_equal 1, @dataset.features.size
    assert_equal @dataset.uri, @dataset[RDF::XSD.anyURI]
  end
end
