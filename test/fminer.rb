require_relative "setup.rb"

class FminerTest < MiniTest::Test

  def test_fminer

    dataset = OpenTox::Dataset.new nil, SUBJECTID
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    assert_equal dataset.uri.uri?, true

    dataset_uri = OpenTox::Algorithm::Fminer.bbrc :dataset_uri => dataset.uri
    feature_dataset = OpenTox::Dataset.new dataset_uri, SUBJECTID
    assert_equal dataset_uri.uri?, true
    assert_equal dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 54, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&A]-[#6&A]=[#6&A]', OpenTox::Feature.new(feature_dataset.features.first.uri, SUBJECTID).title
    compounds = feature_dataset.compounds
    smarts = feature_dataset.features.collect{|f| f.title}
    match = OpenTox::Algorithm::Descriptor.smarts_match compounds, smarts
    compounds.each_with_index do |c,i|
      smarts.each_with_index do |s,j|
        assert_equal match[c.uri][s], feature_dataset.data_entries[i][j].to_i 
      end
    end

    dataset_uri = OpenTox::Algorithm::Fminer.last :dataset_uri => dataset.uri
    feature_dataset = OpenTox::Dataset.new dataset_uri, SUBJECTID
    assert_equal dataset_uri.uri?, true
    assert_equal dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 21, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&a]:[#6&a]:[#6&a]:[#6&a]:[#6&a]', OpenTox::Feature.new(feature_dataset.features.first.uri, SUBJECTID).title

    dataset.delete
    feature_dataset.delete
  end

end
