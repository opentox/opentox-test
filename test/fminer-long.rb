require_relative "setup.rb"

class FminerTest < MiniTest::Test

  def test_fminer_multicell
    # TODO aborts, probably fminer
    dataset = OpenTox::MeasuredDataset.new 
    #multi_cell_call.csv
    dataset.upload File.join(DATA_DIR,"multi_cell_call.csv")
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc(:dataset => dataset)#, :min_frequency => 15)
    dataset.delete
    feature_dataset.delete
  end

  def test_fminer_isscan
    dataset = OpenTox::MeasuredDataset.new 
    dataset.upload File.join(DATA_DIR,"ISSCAN-multi.csv")
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc(:dataset => dataset)#, :min_frequency => 15)
    assert_equal feature_dataset.compounds.size, dataset.compounds.size
    p feature_dataset
    dataset.delete
    feature_dataset.delete
  end

  def test_fminer_kazius
    dataset = OpenTox::MeasuredDataset.from_csv_file File.join(DATA_DIR,"kazius.csv")
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc(:dataset => dataset, :min_frequency => 200)
    #feature_dataset = OpenTox::Algorithm::Fminer.bbrc(:dataset => dataset)#, :min_frequency => 15)
    assert_equal feature_dataset.compounds.size, dataset.compounds.size
    p feature_dataset.compounds.size
    p feature_dataset.features.size
    dataset.delete
    feature_dataset.delete
  end

end
