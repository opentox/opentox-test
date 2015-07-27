require_relative "setup.rb"

class FminerTest < MiniTest::Test

  def test_fminer_bbrc
    dataset = OpenTox::Dataset.from_csv_file File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    refute_nil dataset.id
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc :dataset => dataset
    assert_equal dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 54, feature_dataset.features.size
    assert_equal "C-C-C=C", feature_dataset.features.first.smarts
    compounds = feature_dataset.compounds
    smarts = feature_dataset.features.collect{|f| f.smarts}
    match = OpenTox::Algorithm::Descriptor.smarts_count compounds, smarts
    p smarts
    compounds.each_with_index do |c,i|
      p c.smiles
      p match[i]
      p feature_dataset.feature_values(c)
      smarts.each_with_index do |s,j|
        #unless match[i][j] == DataEntry.where(:dataset_id => feature_dataset.id, :compound_id => c.id, :feature_id => feature_dataset.features[j]).distinct(:value).first
          #p c
          #p s
          #p feature_dataset.features[j]
          #p match[i][j]
          #p DataEntry.where(:dataset_id => feature_dataset.id, :compound_id => c.id, :feature_id => feature_dataset.features[j]).distinct(:value)
        #end

        #assert_equal match[i][j], feature_dataset[c,feature_dataset.features[j]]
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
