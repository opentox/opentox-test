require_relative "setup.rb"

class FminerTest < MiniTest::Test

  def test_fminer

    @dataset = OpenTox::Dataset.new nil, SUBJECTID
    @dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    assert_equal @dataset.uri.uri?, true

    fminer = OpenTox::Algorithm.new File.join($algorithm[:uri],"fminer","bbrc"), SUBJECTID
    dataset_uri =  fminer.run :dataset_uri => @dataset.uri
    feature_dataset = OpenTox::Dataset.new dataset_uri, SUBJECTID
    assert_equal dataset_uri.uri?, true
    assert_equal @dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 54, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&A]-[#6&A]=[#6&A]', OpenTox::Feature.new(feature_dataset.features.first.uri, SUBJECTID).title
    feature_dataset.compounds.each_with_index do |c,i|
      match = OpenTox::Descriptor::Smarts.fingerprint c, feature_dataset.features.collect{|f| f.title}
      assert_equal match.first, feature_dataset.data_entries[i].collect{|v| v.to_i}
      feature_dataset.features.each_with_index do |f,j|
        match = OpenTox::Descriptor::Smarts.fingerprint c, f.title
        assert_equal match[0][0], feature_dataset.data_entries[i][j].to_i 
      end
    end

    fminer = OpenTox::Algorithm.new File.join($algorithm[:uri],"fminer","last"), SUBJECTID
    dataset_uri =  fminer.run :dataset_uri => @dataset.uri
    feature_dataset = OpenTox::Dataset.new dataset_uri, SUBJECTID
    assert_equal dataset_uri.uri?, true
    assert_equal @dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 21, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&a]:[#6&a]:[#6&a]:[#6&a]:[#6&a]', OpenTox::Feature.new(feature_dataset.features.first.uri, SUBJECTID).title

    @dataset.delete
    feature_dataset.delete
  end

end
