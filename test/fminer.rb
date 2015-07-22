require_relative "setup.rb"

class FminerTest < MiniTest::Test

  def test_fminer_bbrc
    dataset = OpenTox::Dataset.new
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    refute_nil dataset.id

    feature_dataset = OpenTox::Algorithm::Fminer.bbrc :dataset => dataset
    assert_equal dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 54, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&A]-[#6&A]=[#6&A]', feature_dataset.features.first.title
    compounds = feature_dataset.compounds
    smarts = feature_dataset.features.collect{|f| f.smarts}
    match = OpenTox::Algorithm::Descriptor.smarts_match compounds, smarts
    compounds.each_with_index do |c,i|
      smarts.each_with_index do |s,j|
        assert_equal match[i][j], feature_dataset.data_entries[i][j].to_i
      end
    end

    dataset.delete
    feature_dataset.delete
  end

  def test_fminer_last
    dataset = OpenTox::Dataset.new
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    feature_dataset = OpenTox::Algorithm::Fminer.last :dataset => dataset
    assert_equal dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 21, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&a]:[#6&a]:[#6&a]:[#6&a]:[#6&a]', feature_dataset.features.first.smarts

    compounds = feature_dataset.compounds
    smarts = feature_dataset.features.collect{|f| f.smarts}
    match = OpenTox::Algorithm::Descriptor.smarts_match compounds, smarts
    compounds.each_with_index do |c,i|
      smarts.each_with_index do |s,j|
        assert_equal match[i][j], feature_dataset.data_entries[i][j].to_i
      end
    end

    dataset.delete
    feature_dataset.delete
  end

end
