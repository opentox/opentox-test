require_relative "setup.rb"

class FminerTest < MiniTest::Unit::TestCase

  def test_fminer

    @dataset = OpenTox::Dataset.new nil, @@subjectid
    @dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    assert_equal @dataset.uri.uri?, true

    fminer = OpenTox::Algorithm.new File.join($algorithm[:uri],"fminer","bbrc"), @@subjectid
    dataset_uri =  fminer.run :dataset_uri => @dataset.uri
    feature_dataset = OpenTox::Dataset.new dataset_uri, @@subjectid
    assert_equal dataset_uri.uri?, true
    assert_equal @dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 54, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&A]-[#6&A]=[#6&A]', OpenTox::Feature.new(feature_dataset.features.first.uri, @@subjectid).title
    data = {}
    feature_dataset.compounds.each_with_index do |c,i|
      data[c.smiles] = {}
      feature_dataset.features.each_with_index do |f,j|
        value = feature_dataset.data_entries[i][j].to_i 
        match = c.match([f.title])[f.title]
        assert_equal match.to_i, value
      end
    end

    fminer = OpenTox::Algorithm.new File.join($algorithm[:uri],"fminer","last"), @@subjectid
    dataset_uri =  fminer.run :dataset_uri => @dataset.uri
    feature_dataset = OpenTox::Dataset.new dataset_uri, @@subjectid
    assert_equal dataset_uri.uri?, true
    assert_equal @dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 21, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&a]:[#6&a]:[#6&a]:[#6&a]:[#6&a]', OpenTox::Feature.new(feature_dataset.features.first.uri, @@subjectid).title

    @dataset.delete
    feature_dataset.delete
  end

end
