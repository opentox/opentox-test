require_relative "setup.rb"

class FminerTest < MiniTest::Test

  def test_fminer_multicell
    # TODO aborts, probably fminer
    dataset = OpenTox::Dataset.new 
    #multi_cell_call.csv
    dataset.upload File.join(DATA_DIR,"multi_cell_call.csv")
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc(dataset)#, :min_frequency => 15)
    dataset.delete
    feature_dataset.delete
  end

  def test_fminer_isscan
    dataset = OpenTox::Dataset.from_csv_file File.join(DATA_DIR,"ISSCAN-multi.csv")
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc(dataset)#, :min_frequency => 15)
    assert_equal feature_dataset.compounds.size, dataset.compounds.size
    p feature_dataset
    dataset.delete
    feature_dataset.delete
  end

  def test_fminer_kazius
    dataset = OpenTox::Dataset.from_csv_file File.join(DATA_DIR,"kazius.csv")
    # TODO reactivate default settings
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc(dataset, :min_frequency => 20)
    assert_equal feature_dataset.compounds.size, dataset.compounds.size
    feature_dataset = Dataset.find feature_dataset.id
    assert feature_dataset.data_entries.size, dataset.compounds.size
    dataset.delete
    feature_dataset.delete
  end

end
