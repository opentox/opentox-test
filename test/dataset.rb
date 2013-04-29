require_relative "setup.rb"

class DatasetTest < MiniTest::Unit::TestCase

=begin

# TODO: and add Egons example
  def test_sdf_with_multiple_features
    @dataset = OpenTox::Dataset.new nil, @@subjectid
    @dataset.upload "#{DATA_DIR}/CPDBAS_v5c_1547_29Apr2008part.sdf"
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
    assert_equal OpenTox::Dataset, d.class
    assert_equal "hamster_carcinogenicity.ntriples",  d.title 
    assert_equal 1, d.features.size
    assert_equal 76, d.compounds.size
    assert_equal 76, d.data_entries.size
    d.delete 
    assert_equal false, URI.accessible?(d.uri, @@subjectid)
  end
=end

  def test_all
    d1 = OpenTox::Dataset.new File.join($dataset[:uri],SecureRandom.uuid), @@subjectid
    d1.put
    datasets = OpenTox::Dataset.all @@subjectid
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
    assert_raises OpenTox::BadRequestError do
      d << [OpenTox::Compound.from_smiles("c1ccccc1NN"), 1,2]
    end

    # add data entries
    d.features = ["test1", "test2"].collect do |title|
      f = OpenTox::Feature.new nil,@subjectid
      f.title = title
      f[RDF.type] = RDF::OT.NumericFeature
      f.put
      f
    end

    # wrong feature size
    assert_raises OpenTox::BadRequestError do
      d << [OpenTox::Compound.from_smiles("c1ccccc1NN"), 1,2,3]
    end
    
    d << [OpenTox::Compound.from_smiles("c1ccccc1NN"), 1,2]
    d << [OpenTox::Compound.from_smiles("CC(C)N"), 4,5]
    d << [OpenTox::Compound.from_smiles("C1C(C)CCCC1"), 6,7]
    assert_equal 3, d.compounds.size
    assert_equal 2, d.features.size
    assert_equal [[1,2],[4,5],[6,7]], d.data_entries
    d.put
    # check if dataset has been saved correctly
    new_dataset = OpenTox::Dataset.new d.uri, @@subjectid
    assert_equal 3, new_dataset.compounds.size
    assert_equal 2, new_dataset.features.size
    assert_equal [[1,2],[4,5],[6,7]], new_dataset.data_entries
    d.delete
    assert_equal false, URI.accessible?(d.uri, @@subjectid)
    assert_equal false, URI.accessible?(new_dataset.uri, @@subjectid)
  end

  def test_dataset_accessors
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload "#{DATA_DIR}/multicolumn.csv"
    # create empty dataset
    new_dataset = OpenTox::Dataset.new d.uri, @@subjectid
    # get metadata
    assert_equal "multicolumn.csv",  new_dataset[RDF::OT.hasSource]
    assert_equal "multicolumn.csv",  new_dataset.title
    # get features
    assert_equal 5, new_dataset.features.size
    assert_equal 6, new_dataset.compounds.size
    assert_equal [1, nil, "false", nil, nil], new_dataset.data_entries.last
    d.delete
  end

  def test_create_from_file
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal OpenTox::Dataset, d.class
    refute_nil d[RDF::OT.Warnings]
    assert_equal "EPAFHM.mini.csv",  d[RDF::OT.hasSource]
    assert_equal "EPAFHM.mini.csv",  d.title
    d.delete 
    assert_equal false, URI.accessible?(d.uri, @@subjectid)
  end

  def test_multicolumn_csv
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload "#{DATA_DIR}/multicolumn.csv"
    refute_nil d[RDF::OT.Warnings]
    assert_match /Duplicate compound/,  d[RDF::OT.Warnings]
    assert_match /3, 5/,  d[RDF::OT.Warnings]
    assert_equal 5, d.features.size
    assert_equal 6, d.compounds.size
    assert_equal 5, d.compounds.collect{|c| c.uri}.uniq.size
    assert_equal [[1.0, 1.0, "true", "true", "test"], [1.0, 2.0, "false", "7.5", "test"], [1.0, 3.0, "true", "5", "test"], [0.0, 4.0, "false", "false", "test"], [1.0, 2.0, "true", "4", "test_2"],[1.0, nil, "false", nil, nil]], d.data_entries
    assert_equal "c1cc[nH]c1,1.0,,false,,", d.to_csv.split("\n")[6]
    #assert_equal 'c1ccc[nH]1,1,,false,,', d.to_csv.split("\n")[6]
    csv = CSV.parse(OpenTox::RestClientWrapper.get d.uri, {}, {:accept => 'text/csv', :subjectid => @@subjectid})
    original_csv = CSV.read("#{DATA_DIR}/multicolumn.csv")
    csv.shift
    original_csv.shift
    csv.each_with_index do |row,i|
      compound = OpenTox::Compound.from_inchi row.shift
      original_compound = OpenTox::Compound.from_smiles original_csv[i].shift
      assert_equal original_compound.uri, compound.uri
      # AM: multicol does not parse correctly NA into nil
      assert_equal original_csv[i].collect{|v| (v.class == String) ? ((v.strip == "") ? nil : v.strip) : v}, row
    end
    d.delete 
    assert_equal false, URI.accessible?(d.uri, @@subjectid)
  end

  def test_from_csv
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload "#{DATA_DIR}/hamster_carcinogenicity.csv"
    assert_equal OpenTox::Dataset, d.class
    assert_equal 1, d.features.size
    assert_equal 85, d.compounds.size
    assert_equal 85, d.data_entries.size
    csv = CSV.read("#{DATA_DIR}/hamster_carcinogenicity.csv")
    csv.shift
    assert_equal csv.collect{|r| r[1]}, d.data_entries.flatten
    d.delete 
    assert_equal false, URI.accessible?(d.uri, @@subjectid)
  end

  def test_from_xls
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload "#{DATA_DIR}/hamster_carcinogenicity.xls"
    assert_equal OpenTox::Dataset, d.class
    assert_equal 1, d.features.size
    assert_equal 85, d.compounds.size
    assert_equal 85, d.data_entries.size
    d.delete 
    assert_equal false, URI.accessible?(d.uri, @@subjectid)
  end

  def test_from_csv2
    File.open("#{DATA_DIR}/temp_test.csv", "w+") { |file| file.write("SMILES,Hamster\nCC=O,true\n ,true\nO=C(N),true") }
    dataset = OpenTox::Dataset.new nil, @@subjectid
    dataset.upload "#{DATA_DIR}/temp_test.csv"
    dataset.get
    assert_equal true, URI.accessible?(dataset.uri, @@subjectid)
    assert_equal "Cannot parse compound '' at position 3, all entries are ignored.",  dataset[RDF::OT.Warnings]
    File.delete "#{DATA_DIR}/temp_test.csv"
  end


end

=begin
class DatasetRestTest < MiniTest::Unit::TestCase

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
