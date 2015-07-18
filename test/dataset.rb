# TODO: check json specification at https://github.com/opentox-api/api-specification/issues/2

require_relative "setup.rb"

class DatasetTest < MiniTest::Test

  def test_all
    d1 = OpenTox::Dataset.new 
    d1.save
    datasets = OpenTox::Dataset.all 
    assert_equal OpenTox::Dataset, datasets.first.class
    d1.delete
  end

  def test_create_empty
    d = OpenTox::Dataset.new
    assert_equal OpenTox::Dataset, d.class
    refute_nil d.id
    assert_kind_of BSON::ObjectId, d.id
  end

  def test_client_create
    d = OpenTox::Dataset.new
    assert_equal OpenTox::Dataset, d.class
    d[:title] = "Create dataset test"

    # features not set
    assert_raises OpenTox::BadRequestError do
      d << [OpenTox::Compound.from_smiles("c1ccccc1NN"), 1,2]
    end

    # add data entries
    d.features = ["test1", "test2"].collect do |title|
      f = OpenTox::Feature.new 
      f[:title] = title
      f.numeric = true
      f.save
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
    d.save
    # check if dataset has been saved correctly
    new_dataset = OpenTox::Dataset.find d.id
    assert_equal 3, new_dataset.compounds.size
    assert_equal 2, new_dataset.features.size
    assert_equal [[1,2],[4,5],[6,7]], new_dataset.data_entries
    d.delete
    assert_raises Mongoid::Errors::DocumentNotFound do
      OpenTox::Dataset.find d.id
    end
    assert_raises Mongoid::Errors::DocumentNotFound do
      OpenTox::Dataset.find new_dataset.id
    end
  end

  def test_dataset_accessors
    d = OpenTox::Dataset.new
    d.upload "#{DATA_DIR}/multicolumn.csv"
    # create empty dataset
    new_dataset = OpenTox::Dataset.find d.id
    # get metadata
    assert_match "multicolumn.csv",  new_dataset.source
    assert_equal "multicolumn.csv",  new_dataset.title
    # get features
    assert_equal 6, new_dataset.features.size
    assert_equal 7, new_dataset.compounds.size
    assert_equal ["1", nil, "false", nil, nil, 1.0], new_dataset.data_entries.last
    d.delete
  end

  def test_create_from_file
    d = OpenTox::Dataset.new
    d.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal OpenTox::Dataset, d.class
    refute_nil d["warnings"]
    assert_match "EPAFHM.mini.csv",  d["source"]
    assert_equal "EPAFHM.mini.csv",  d.title
    d.delete 
    #assert_equal false, URI.accessible?(d.uri)
  end

  def test_create_from_file_with_wrong_smiles_compound_entries
    d = OpenTox::Dataset.new
    d.upload File.join(DATA_DIR,"wrong_dataset.csv")
    refute_nil d["warnings"]
    assert_match /2|3|4|5|6|7|8/, d["warnings"].join
    d.delete
  end

  def test_multicolumn_csv
    d = OpenTox::Dataset.new
    d.upload "#{DATA_DIR}/multicolumn.csv"
    refute_nil d["warnings"]
    assert d["warnings"].grep(/Duplicate compound/)  
    assert d["warnings"].grep(/3, 5/)  
    assert_equal 6, d.features.size
    assert_equal 7, d.compounds.size
    assert_equal 5, d.compounds.collect{|c| c.inchi}.uniq.size
    assert_equal [["1", "1", "true", "true", "test", 1.1], ["1", "2", "false", "7.5", "test", 0.24], ["1", "3", "true", "5", "test", 3578.239], ["0", "4", "false", "false", "test", -2.35], ["1", "2", "true", "4", "test_2", 1], ["1", "2", "false", "false", "test", -1.5], ["1", nil, "false", nil, nil, 1.0]], d.data_entries
    assert_equal "c1cc[nH]c1,1,,false,,,1.0", d.to_csv.split("\n")[7]
    csv = CSV.parse(d.to_csv)
    original_csv = CSV.read("#{DATA_DIR}/multicolumn.csv")
    csv.shift
    original_csv.shift
    csv.each_with_index do |row,i|
      compound = OpenTox::Compound.from_smiles row.shift
      original_compound = OpenTox::Compound.from_smiles original_csv[i].shift
      assert_equal original_compound.inchi, compound.inchi
      row.each_with_index do |v,j|
        if v.numeric?
          assert_equal original_csv[i][j].strip.to_f, row[j].to_f
        else
          assert_equal original_csv[i][j].strip, row[j].to_s
        end
      end
    end
    d.delete 
  end

  def test_from_csv
    d = OpenTox::Dataset.new
    d.upload "#{DATA_DIR}/hamster_carcinogenicity.csv"
    assert_equal OpenTox::Dataset, d.class
    assert_equal 1, d.features.size
    assert_equal 85, d.compounds.size
    assert_equal 85, d.data_entries.size
    csv = CSV.read("#{DATA_DIR}/hamster_carcinogenicity.csv")
    csv.shift
    assert_equal csv.collect{|r| r[1]}, d.data_entries.flatten
    d.delete 
    #assert_equal false, URI.accessible?(d.uri)
  end

  def test_from_csv_classification
    ["int", "float", "string"].each do |mode|
      d = OpenTox::Dataset.new
      d.upload "#{DATA_DIR}/hamster_carcinogenicity.mini.bool_#{mode}.csv"
      csv = CSV.read("#{DATA_DIR}/hamster_carcinogenicity.mini.bool_#{mode}.csv")
      csv.shift
      entries = d.data_entries.flatten
      csv.each_with_index do |r, i|
        assert_equal r[1].to_s, entries[i]
      end
      d.delete 
    end
  end

  def test_from_csv2
    File.open("#{DATA_DIR}/temp_test.csv", "w+") { |file| file.write("SMILES,Hamster\nCC=O,true\n ,true\nO=C(N),true") }
    dataset = OpenTox::Dataset.new
    dataset.upload "#{DATA_DIR}/temp_test.csv"
    assert_equal "Cannot parse SMILES compound '' at position 3, all entries are ignored.",  dataset["warnings"].join
    File.delete "#{DATA_DIR}/temp_test.csv"
    dataset.features.each{|f| feature = OpenTox::Feature.find f.id; feature.delete}
    dataset.delete
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
      d = OpenTox::Dataset.new
      d.upload "#{DATA_DIR}/hamster_carcinogenicity.mini.csv"
      features << d.features.first
      assert features[0].id==features[-1].id,"re-upload should find old feature, but created new one"
      datasets << d
    end
    datasets.each{|d| d.delete}
  end

end

