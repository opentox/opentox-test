# TODO: check json specification at https://github.com/opentox-api/api-specification/issues/2

require_relative "setup.rb"

class DatasetTest < MiniTest::Test

=begin

# TODO: and add Egons example
  def test_sdf_with_multiple_features
    @dataset = OpenTox::Dataset.new nil
    @dataset.upload "#{DATA_DIR}/CPDBAS_v5c_1547_29Apr2008part.sdf"
    assert_equal OpenTox::Dataset, @dataset.class
    puts @dataset.features.size
    puts @dataset.compounds.size
    @dataset.delete
  end

# TODO: create unordered example file with working references
# e.g. download from ambit, upload
  def test_create_from_ntriples
    d = OpenTox::Dataset.new nil
    d.upload File.join(DATA_DIR,"hamster_carcinogenicity.ntriples")
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
    d1 = OpenTox::Dataset.new File.join($dataset[:uri],SecureRandom.uuid)
    d1.put
    datasets = OpenTox::Dataset.all 
    assert_equal OpenTox::Dataset, datasets.first.class
    d1.delete
  end

  def test_create_empty
    d = OpenTox::Dataset.new #File.join($dataset[:uri],SecureRandom.uuid)
    assert_equal OpenTox::Dataset, d.class
    assert_match /#{$dataset[:uri]}/, d.uri.to_s
  end
  
  def test_head_id
    d = OpenTox::Dataset.new nil
    d.title = "head test"
    d.put
    response = `curl -Lki -H subjectid:#{OpenTox::RestClientWrapper.subjectid} #{d.uri}`
    assert_match /200/, response
    d.delete
  end

  def test_client_create
    d = OpenTox::Dataset.new nil
    assert_equal OpenTox::Dataset, d.class
    assert_match /#{$dataset[:uri]}/, d.uri.to_s
    d[:title] = "Create dataset test"

    # features not set
    assert_raises OpenTox::BadRequestError do
      d << [OpenTox::Compound.from_smiles("c1ccccc1NN"), 1,2]
    end

    # add data entries
    d.features = ["test1", "test2"].collect do |title|
      f = OpenTox::Feature.new nil
      f[:title] = title
      f[:type] = ["NumericFeature", "Feature"]
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
#p(JSON.pretty_generate(d["data"]))
p d["data"]
    d.put
    # check if dataset has been saved correctly
    new_dataset = OpenTox::Dataset.new d.uri
    assert_equal 3, new_dataset.compounds.size
    assert_equal 2, new_dataset.features.size
    assert_equal [[1,2],[4,5],[6,7]], new_dataset.data_entries
    d.delete
    assert_equal false, URI.accessible?(d.uri)
    assert_equal false, URI.accessible?(new_dataset.uri)
  end

  def test_dataset_accessors
    d = OpenTox::Dataset.new nil
    d.upload "#{DATA_DIR}/multicolumn.csv"
    # create empty dataset
    new_dataset = OpenTox::Dataset.new d.uri
    # get metadata
    assert_equal "multicolumn.csv",  new_dataset["hasSource"]
    assert_equal "multicolumn.csv",  new_dataset.title
    # get features
    assert_equal 6, new_dataset.features.size
    assert_equal 7, new_dataset.compounds.size
    assert_equal ["1", nil, "false", nil, nil, 1.0], new_dataset.data_entries.last
    d.delete
  end

  def test_create_from_file
    d = OpenTox::Dataset.new nil
    d.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal OpenTox::Dataset, d.class
    refute_nil d["Warnings"]
    assert_equal "EPAFHM.mini.csv",  d["hasSource"]
    assert_equal "EPAFHM.mini.csv",  d.title
    d.delete 
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_create_from_file_with_wrong_smiles_compound_entries
    d = OpenTox::Dataset.new nil
    d.upload File.join(DATA_DIR,"wrong_dataset.csv")
    refute_nil d["Warnings"]
    assert_match /2|3|4|5|6|7|8/, d["Warnings"]
    d.delete
  end

  def test_multicolumn_csv
    d = OpenTox::Dataset.new nil
    d.upload "#{DATA_DIR}/multicolumn.csv"
    refute_nil d["Warnings"]
    assert d["Warnings"].grep(/Duplicate compound/)  
    assert d["Warnings"].grep(/3, 5/)  
    assert_equal 6, d.features.size
    assert_equal 7, d.compounds.size
    assert_equal 5, d.compounds.collect{|c| c.uri}.uniq.size
    assert_equal [["1", "1", "true", "true", "test", "1.1"], ["1", "2", "false", "7.5", "test", "0.24"], ["1", "3", "true", "5", "test", "3578.239"], ["0", "4", "false", "false", "test", "-2.35"], ["1", "2", "true", "4", "test_2", "1"], ["1", "2", "false", "false", "test", "-1.5"], ["1", nil, "false", nil, nil, "1.0"]], d.data_entries
    assert_equal "c1cc[nH]c1,1,,false,,,1.0", d.to_csv.split("\n")[7]
    csv = CSV.parse(OpenTox::RestClientWrapper.get d.uri, {}, {:accept => 'text/csv'})
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
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_from_csv
    d = OpenTox::Dataset.new nil
    d.upload "#{DATA_DIR}/hamster_carcinogenicity.csv"
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

  def test_from_csv_classification
    ["int", "float", "string"].each do |mode|
      d = OpenTox::Dataset.new nil
      d.upload "#{DATA_DIR}/hamster_carcinogenicity.mini.bool_#{mode}.csv"
      csv = CSV.read("#{DATA_DIR}/hamster_carcinogenicity.mini.bool_#{mode}.csv")
      csv.shift
      entries = d.data_entries.flatten
      csv.each_with_index do |r, i|
        assert_equal r[1].to_s, entries[i]
      end
      d.delete 
      assert_equal false, URI.accessible?(d.uri)
    end
  end

  def test_from_xls
    d = OpenTox::Dataset.new nil
    d.upload "#{DATA_DIR}/hamster_carcinogenicity.xls"
    assert_equal OpenTox::Dataset, d.class
    assert_equal 1, d.features.size
    assert_equal 85, d.compounds.size
    assert_equal 85, d.data_entries.size
    d.delete 
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_from_csv2
    File.open("#{DATA_DIR}/temp_test.csv", "w+") { |file| file.write("SMILES,Hamster\nCC=O,true\n ,true\nO=C(N),true") }
    dataset = OpenTox::Dataset.new nil
    dataset.upload "#{DATA_DIR}/temp_test.csv"
    assert_equal true, URI.accessible?(dataset.uri)
    assert_equal "Cannot parse SMILES compound '' at position 3, all entries are ignored.",  dataset["Warnings"]
    File.delete "#{DATA_DIR}/temp_test.csv"
    dataset.features.each{|f| feature = OpenTox::Feature.find f.uri; feature.delete}
    dataset.delete
    assert_equal false, URI.accessible?(dataset.uri)
  end

  def test_compound_index_mapping
    e = :error 
    n = nil
    c1 =  ["F","C","N","O","S","S","S","C"]
    c2 =  ["F","N","C","O","O","P","C","S"]
    res = [ 0 , 2 , 1 , 3 , 3 , n , 7,  e ]
    # compound_index() assings each compound in c2 to a single compound in c1 (required by validation)
    # explanation for each index of the expected mapping result 'res':
    # 0: "F" in c2 occurs only once in c1 at the same pos -> 0
    # 1: "N" in c2 occurs once in c1 at position 2 -> 2
    # 2: "C" in c2 occurs twice in c1 (1,7), assume that ordering is equal -> 1
    # 3: "O" in c2 occurs only once in c1 at position 3 (n to 1 mapping possible in direction c2->c1) -> 3
    # 4: "O" in c2 occurs only once in c1 at position 3 (n to 1 mapping possible in direction c2->c1) -> 3
    # 5: "P" in c2 does not occur in c1 -> nil
    # 6: "C" in c2 occurs twice in c1 (1,7), assume that ordering is equal -> 7
    # 7: "S" in c2 occurs more than once in c1 (n to 1 mapping not possible in direction c1->c2) -> error
    assert_equal c1.size,c2.size
    f1 = "/tmp/c1.csv"
    f2 = "/tmp/c2.csv"
    File.open(f1, "w") { |file| file.write((["SMILES"]+c1).join("\n")) }
    File.open(f2, "w") { |file| file.write((["SMILES"]+c2).join("\n")) }
    d1 = OpenTox::Dataset.new
    d1.upload f1
    d2 = OpenTox::Dataset.new
    d2.upload f2
    assert_equal d1.compounds.size,c1.size
    assert_equal d2.compounds.size,c2.size
    c1.size.times do |i|
      begin
        m  = d1.compound_index(d2,i)
      rescue
        m = e
      end
      assert_equal m,res[i]
    end
  end

  def test_same_feature
    datasets = []
    features = []
    2.times do |i|
      d = OpenTox::Dataset.new nil
      d.upload "#{DATA_DIR}/hamster_carcinogenicity.mini.csv"
      features << d.features.first
      puts features.last.metadata
      assert features[0].uri==features[-1].uri,"re-upload should find old feature, but created new one"
      datasets << d
    end
    datasets.each{|d| d.delete}
  end

end

=begin
class DatasetRestTest < MiniTest::Test

  def test_01_get_uri_list
    result = OpenTox::RestClientWrapper.get $dataset[:uri], {}, { :accept => 'text/uri-list', :subjectid => SUBJECTID }
    assert_equal 200, result.code
  end

  # check if default response header is text/uri-list
  def test_02_get_datasetlist_type
    result = OpenTox::RestClientWrapper.get $dataset[:uri], {}, { :accept => 'text/uri-list', :subjectid => SUBJECTID }
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
