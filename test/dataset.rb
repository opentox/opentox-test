require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
DATA_DIR = File.join(File.dirname(__FILE__),"data")

begin
  puts "Service URI is: #{$dataset[:uri]}"
rescue
  puts "Configuration Error: $dataset[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class DatasetTest < Test::Unit::TestCase

  def test_all
    datasets = OpenTox::Dataset.all $dataset[:uri], @@subjectid
    assert_equal OpenTox::Dataset, datasets.first.class
  end

=begin
  def test_create_empty
    d = OpenTox::Dataset.create $dataset[:uri], @@subjectid
    puts d
    assert_equal OpenTox::Dataset, d.class
    assert_match /#{$dataset[:uri]}/, d.uri.to_s
    d.delete :subjectid => @@subjectid
  end
=end

  def test_create_from_ntriples
    d = OpenTox::Dataset.from_file $dataset[:uri], File.join(DATA_DIR,"hamster_carcinogenicity.ntriples"), @@subjectid
    assert_equal OpenTox::Dataset, d.class
    assert_equal d.uri, d[RDF::XSD.anyURI]
    assert_equal "Hamster Carcinogenicity",  d.metadata[RDF::URI("http://purl.org/dc/elements/1.1/title")].first.to_s # DC.title is http://purl.org/dc/terms/title
    assert_equal "Hamster Carcinogenicity",  d[RDF::URI("http://purl.org/dc/elements/1.1/title")]
    d.delete :subjectid => @@subjectid
    assert_raise OpenTox::RestCallError do
      d.get
    end
  end

  def test_create_from_file
    d = OpenTox::Dataset.from_file $dataset[:uri], File.join(DATA_DIR,"EPAFHM.mini.csv"), @@subjectid
    assert_equal OpenTox::Dataset, d.class
    puts d.uri
    assert_not_nil d.metadata[RDF::OT.Warnings]
    assert_equal "EPAFHM.mini.csv",  d.metadata[RDF::OT.hasSource].first.to_s
    puts  RDF::DC.title
    # TODO: check origin of "wurl" instead of "purl", rdf uploaded to 4store seems to be ok
    t = RDF::URI.new "http://wurl.org/dc/terms/title"
    puts t
    puts d.metadata[t]
    assert_equal "EPAFHM.mini.csv",  d.metadata[t].first.to_s
    #assert_equal "EPAFHM.mini.csv",  d.metadata[RDF::DC.title].to_s
    d.delete :subjectid => @@subjectid
    assert_raise OpenTox::RestCallError do
      d.get
    end
  end

=begin
  def test_from_yaml
    @dataset = OpenTox::Dataset.from_file $dataset[:uri], File.join(DATA_DIR,"hamster_carcinogenicity.yaml"), @@subjectid
    assert_equal OpenTox::Dataset, @dataset.class
    assert_equal "hamster_carcinogenicity", @dataset[RDF::URI("http://purl.org/dc/elements/1.1/title")]
    hamster_carc?
    @dataset.delete :subjectid => @@subjectid
  end
=end

# TODO: fix (mime type??0 and add Egons example
  def test_sdf_with_multiple_features
    @dataset = OpenTox::Dataset.from_file $dataset[:uri], "#{DATA_DIR}/CPDBAS_v5c_1547_29Apr2008part.sdf", "chemical/x-mdl-sdfile"
    assert_equal OpenTox::Dataset, @dataset.class
    puts @dataset.features.size
    puts @dataset.compounds.size
    @dataset.delete
  end
=begin
=end

  def test_multicolumn_csv
    @dataset = OpenTox::Dataset.from_file $dataset[:uri], "#{DATA_DIR}/multicolumn.csv", @@subjectid
    puts @dataset.uri
    assert_equal 5, @dataset.features.size
    assert_equal 4, @dataset.compounds.size
    @dataset.delete :subjectid => @@subjectid
  end

  def test_from_csv
    @dataset = OpenTox::Dataset.from_file $dataset[:uri], "#{DATA_DIR}/hamster_carcinogenicity.csv", @@subjectid
    assert_equal OpenTox::Dataset, @dataset.class
    hamster_carc?
    @dataset.delete :subjectid => @@subjectid
  end

=begin
  def test_save
    d = OpenTox::Dataset.create $dataset[:uri]
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
    assert_equal 85, @dataset.data_entries.size
    assert_equal 85, @dataset.compounds.size
    assert_equal 1, @dataset.features.size
  end
end
