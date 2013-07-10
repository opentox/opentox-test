require_relative "setup.rb"

class LazarExtendedTest < MiniTest::Test

  def test_lazar_bbrc_ham_minfreq
    dataset = OpenTox::Dataset.new 
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    assert_equal dataset.uri.uri?, true
    model_uri = OpenTox::Model::Lazar.create :dataset_uri => dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"), :min_frequency => 5
    assert_equal model_uri.uri?, true
    model = OpenTox::Model::Lazar.new model_uri
    assert_equal model.uri.uri?, true
    feature_dataset_uri = model[RDF::OT.featureDataset]
    feature_dataset = OpenTox::Dataset.new feature_dataset_uri 
    assert_equal dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 41, feature_dataset.features.size
    assert_equal '[#7&A]-[#6&A]=[#7&A]', OpenTox::Feature.new(feature_dataset.features.first.uri).title
    compound = OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H")
    prediction_uri = model.run :compound_uri => compound.uri
    prediction_dataset = OpenTox::Dataset.new prediction_uri
    assert_equal prediction_dataset.uri.uri?, true
    prediction = prediction_dataset.predictions.select{|p| p[:compound].uri == compound.uri}.first
    assert_equal "false", prediction[:value]
    assert_equal 0.12380952380952381, prediction[:confidence]
    dataset.delete
    model.delete
    feature_dataset.delete
    prediction_dataset.delete
  end

  def test_lazar_bbrc_large_ds
    dataset = OpenTox::Dataset.new 
    dataset.upload File.join(DATA_DIR,"multi_cell_call_no_dup.csv")
    assert_equal dataset.uri.uri?, true
    model_uri = OpenTox::Model::Lazar.create :dataset_uri => dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"), :min_frequency => 75
    assert_equal model_uri.uri?, true
    model = OpenTox::Model::Lazar.new model_uri
    assert_equal model.uri.uri?, true
    feature_dataset_uri = model[RDF::OT.featureDataset]
    feature_dataset = OpenTox::Dataset.new feature_dataset_uri 
    assert_equal dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 52, feature_dataset.features.size
    assert_equal '[#17&A]-[#6&A]', OpenTox::Feature.new(feature_dataset.features.first.uri).title
    compound = OpenTox::Compound.from_inchi("InChI=1S/C10H9NO2S/c1-8-2-4-9(5-3-8)13-6-10(12)11-7-14/h2-5H,6H2,1H3")
    prediction_uri = model.run :compound_uri => compound.uri
    prediction_dataset = OpenTox::Dataset.new prediction_uri
    assert_equal prediction_dataset.uri.uri?, true
    prediction = prediction_dataset.predictions.select{|p| p[:compound].uri == compound.uri}.first
    assert_equal "0", prediction[:value]
    #assert_equal 0.025885845574483608, prediction[:confidence]
    # with compound change in training_dataset see:
    # https://github.com/opentox/opentox-test/commit/0e78c9c59d087adbd4cc58bab60fb29cbe0c1da0
    assert_equal 0.02422364949075546, prediction[:confidence]
    dataset.delete
    model.delete
    feature_dataset.delete
    prediction_dataset.delete
  end

end
