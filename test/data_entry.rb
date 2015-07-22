require_relative "setup.rb"

class DataEntryTest < MiniTest::Test

  def test_create

    # add features
    features = ["test1", "test2"].collect do |title|
      NumericBioAssay.find_or_create_by( :title => title, :numeric => true)
    end

    compounds = []
    input = [
      ["c1ccccc1NN",1,2],
      ["CC(C)N",4,5],
      ["C1C(C)CCCC1",6,7],
    ]
    input.each do |row|
      smi = row.shift
      compound = Compound.find_or_create_by(:smiles => smi)
      compounds << compound
      row.each_with_index do |value,i|
        DataEntry.find_or_create compound, features[i], value
      end
    end
    
    assert_equal 3, compounds.size
    assert_equal 2, features.size
    input.each_with_index do |row,i|
      row.each_with_index do |v,j|
        assert_equal DataEntry[compounds[i],features[j]], input[i][j]
      end
    end
  end

  def test_create_from_file
    d = OpenTox::Dataset.from_csv_file File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal OpenTox::Dataset, d.class
    refute_nil d.warnings
    assert_match /row 13/, d.warnings.join
    assert_match "EPAFHM.mini.csv",  d.source
    assert_equal 1, d.features.size
    feature = d.features.first
    assert_kind_of NumericBioAssay, feature
    assert_match "EPAFHM.mini.csv",  feature.source
    assert_equal 0.0113, DataEntry[d.compounds.first, feature]
    assert_equal 0.00323, DataEntry[d.compounds[5], feature]
  end

  def test_upload_kazius
    d = OpenTox::Dataset.from_csv_file File.join DATA_DIR, "kazius.csv"
    assert_empty d.warnings
    #  493 COC1=C(C=C(C(=C1)Cl)OC)Cl,1
    c = d.compounds[491]
    assert_equal c.smiles, "COc1cc(c(cc1Cl)OC)Cl"
    assert_equal DataEntry[c,d.features.first], 1
  end

  def test_upload_feature_dataset
    t1 = Time.now
    f = File.join DATA_DIR, "rat_feature_dataset.csv"
    d = OpenTox::Dataset.from_csv_file f
    assert_equal 458, d.features.size
    d.save
    t2 = Time.now
    p "Upload: #{t2-t1}"
    d2 = OpenTox::Dataset.find d.id
    t3 = Time.now
    p "Dowload: #{t3-t2}"
    assert_equal d.features.size, d2.features.size
    csv = CSV.read f
    assert_equal csv.size-1, d2.compounds.size
    assert_equal csv.first.size-1, d2.features.size
    # asserting complete ds
    3.times do
      cid = rand(d.compounds.size)
      3.times do
        fid = rand(d.features.size)
        # TODO data access is slow
        assert_equal csv[cid+1][fid+1].to_i, DataEntry[d2.compounds[cid],d2.features[fid]]
      end
    end
    #assert_equal csv.size-1, d.data_entries.size
    d2.delete
    assert_raises Mongoid::Errors::DocumentNotFound do
      Dataset.find d.id
    end
  end


end

