require_relative "setup.rb"

class FminerTest < MiniTest::Test

  def test_fminer_kazius

    dataset = OpenTox::MeasuredDataset.from_csv_file File.join(DATA_DIR,"kazius.csv")
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc(:dataset => dataset, :min_frequency => 75)
    #feature_dataset = OpenTox::Algorithm::Fminer.bbrc(:dataset => dataset)#, :min_frequency => 15)
    assert_equal feature_dataset.compounds.size, dataset.compounds.size
    p feature_dataset.compounds.size
    p feature_dataset.features.size
    dataset.delete
    feature_dataset.delete
  end

end
