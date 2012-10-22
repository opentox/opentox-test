require 'test/unit'
require 'csv'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
DATA_DIR = File.join(File.dirname(__FILE__),"data")

begin
  puts "Service URI is: #{$dataset[:uri]}"
rescue
  puts "Configuration Error: $dataset[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class DatasetTest < Test::Unit::TestCase

=begin
  def test_append_to_existing
    #TODO
  end

# TODO: and add Egons example
  def test_sdf_with_multiple_features
    @dataset = OpenTox::Dataset.new nil, @@subjectid
    @dataset.upload "#{DATA_DIR}/CPDBAS_v5c_1547_29Apr2008part.sdf"
    @dataset.get
    assert_equal OpenTox::Dataset, @dataset.class
    puts @dataset.features.size
    puts @dataset.compounds.size
    @dataset.delete
  end

# TODO: create unordered example file with working references
# e.g. download from ambit, upload
  def test_create_from_ntriples
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload File.join(DATA_DIR,"hamster_carcinogenicity.ntriples")
    d.get
    assert_equal OpenTox::Dataset, d.class
    assert_equal "hamster_carcinogenicity.ntriples",  d.title 
    assert_equal 1, d.features.size
    assert_equal 76, d.compounds.size
    assert_equal 76, d.data_entries.size
    d.delete 
    assert_equal false, URI.accessible?(d.uri)
  end
=end

  def test_all
    d1 = OpenTox::Dataset.new File.join($dataset[:uri],SecureRandom.uuid), @@subjectid
    d1.put
    datasets = OpenTox::Dataset.all $dataset[:uri], @@subjectid
    assert_equal OpenTox::Dataset, datasets.first.class
    d1.delete
  end

  def test_create_empty
    d = OpenTox::Dataset.new File.join($dataset[:uri],SecureRandom.uuid), @@subjectid
    assert_equal OpenTox::Dataset, d.class
    assert_match /#{$dataset[:uri]}/, d.uri.to_s
  end

  def test_client_create
    d = OpenTox::Dataset.new nil, @@subjectid
    assert_equal OpenTox::Dataset, d.class
    assert_match /#{$dataset[:uri]}/, d.uri.to_s
    d.title = "Create dataset test"

    # features not set
    assert_raise OpenTox::BadRequestError do
      d << [OpenTox::Compound.from_smiles($compound[:uri], "c1ccccc1NN"), 1,2]
    end

    # add data entries
    d.features = ["test1", "test2"].collect do |title|
      f = OpenTox::Feature.new nil,@subjectid
      f.title = title
      f.append RDF.type, RDF::OT.NumericFeature
      f.put
      f
    end

    # wrong feature size
    assert_raise OpenTox::BadRequestError do
      d << [OpenTox::Compound.from_smiles($compound[:uri], "c1ccccc1NN"), 1,2,3]
    end
    
    d << [OpenTox::Compound.from_smiles($compound[:uri], "c1ccccc1NN"), 1,2]
    d << [OpenTox::Compound.from_smiles($compound[:uri], "CC(C)N"), 4,5]
    d << [OpenTox::Compound.from_smiles($compound[:uri], "C1C(C)CCCC1"), 6,7]
    assert_equal 3, d.compounds.size
    assert_equal 2, d.features.size
    assert_equal [[1,2],[4,5],[6,7]], d.data_entries
    d.put
    d.get
    assert_equal 3, d.compounds.size
    assert_equal 2, d.features.size
    assert_equal [[1,2],[4,5],[6,7]], d.data_entries
    d.delete
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_create_from_file
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    d.get
    #puts d.to_turtle
    assert_equal OpenTox::Dataset, d.class
    assert_not_nil d[RDF::OT.Warnings]
    assert_equal "EPAFHM.mini.csv",  d[RDF::OT.hasSource]
    assert_equal "EPAFHM.mini.csv",  d.title
    d.delete 
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_multicolumn_csv
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload "#{DATA_DIR}/multicolumn.csv"
    d.get
    assert_not_nil d[RDF::OT.Warnings]
    assert_match /Duplicate compound/,  d[RDF::OT.Warnings]
    assert_match /3, 5/,  d[RDF::OT.Warnings]
    assert_equal 5, d.features.size
    assert_equal 6, d.compounds.size
    assert_equal 5, d.compounds.collect{|c| c.uri}.uniq.size
    assert_equal [[1.0, 1.0, "true", "true", "test"], [1.0, 2.0, "false", "7.5", "test"], [1.0, 3.0, "true", "5", "test"], [0.0, 4.0, "false", "false", "test"], [1.0, 2.0, "true", "4", "test_2"],[1.0, nil, "false", nil, nil]], d.data_entries
    assert_equal "c1cc[nH]c1,1.0,,false,,", d.to_csv.split("\n")[6]
    #assert_equal 'c1ccc[nH]1,1,,false,,', d.to_csv.split("\n")[6]
    csv = CSV.parse(OpenTox::RestClientWrapper.get d.uri, {}, {:accept => 'text/csv'})
    original_csv = CSV.read("#{DATA_DIR}/multicolumn.csv")
    csv.shift
    original_csv.shift
    csv.each_with_index do |row,i|
      compound = OpenTox::Compound.from_inchi $compound[:uri], row.shift
      original_compound = OpenTox::Compound.from_smiles $compound[:uri], original_csv[i].shift
      assert_equal original_compound.uri, compound.uri
      # AM: multicol does not parse correctly NA into nil
      assert_equal original_csv[i].collect{|v| (v.class == String) ? ((v.strip == "") ? nil : v.strip) : v}, row
    end
    d.delete 
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_from_csv
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload "#{DATA_DIR}/hamster_carcinogenicity.csv"
    d.get
    assert_equal OpenTox::Dataset, d.class
    assert_equal 1, d.features.size
    assert_equal 85, d.compounds.size
    assert_equal 85, d.data_entries.size
    csv = CSV.read("#{DATA_DIR}/hamster_carcinogenicity.csv")
    csv.shift
    assert_equal csv.collect{|r| r[1]}, d.data_entries.flatten
    d.delete 
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_from_xls
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload "#{DATA_DIR}/hamster_carcinogenicity.xls"
    d.get
    assert_equal OpenTox::Dataset, d.class
    assert_equal 1, d.features.size
    assert_equal 85, d.compounds.size
    assert_equal 85, d.data_entries.size
    d.delete 
    assert_equal false, URI.accessible?(d.uri)
  end

end

=begin
class DatasetRestTest < Test::Unit::TestCase

  def test_01_get_uri_list
    result = OpenTox::RestClientWrapper.get $dataset[:uri], {}, { :accept => 'text/uri-list', :subjectid => @@subjectid }
    assert_equal 200, result.code
  end

  # check if default response header is text/uri-list
  def test_02_get_datasetlist_type
    result = OpenTox::RestClientWrapper.get $dataset[:uri], {}, { :accept => 'text/uri-list', :subjectid => @@subjectid }
    assert_equal "text/uri-list", result.headers[:content_type]
  end

  # check post to investigation service without file
  def test_10_post_dataset_400_no_file
    #result =  OpenTox::RestClientWrapper.post $dataset[:uri], {}, { :subjectid => $pi[:subjectid] }
    #assert_equal 200, result.code
  end

  def test_11_post_dataset
    response =  OpenTox::RestClientWrapper.post $dataset[:uri], {:file => File.join(File.dirname(__FILE__), "data", "hamster_carcinogenicity.csv") }, { :content_type => "text/csv", :subjectid => $pi[:subjectid] }
    assert_equal 200, response.code
    task_uri = response.chomp
    puts task_uri
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    puts uri
    @@uri = URI(uri)
  end

end
=end
