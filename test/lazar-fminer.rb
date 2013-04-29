require_relative "setup.rb"

class FminerLazarTest < MiniTest::Unit::TestCase
  i_suck_and_my_tests_are_order_dependent!

  def test_01_upload
    @@dataset = OpenTox::Dataset.new nil, @@subjectid
    @@dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    assert_equal @@dataset.uri.uri?, true
  end

  def test_02_lazar_bbrc_model
    lazar = OpenTox::Algorithm.new File.join($algorithm[:uri],"lazar"), @@subjectid
    model_uri = lazar.run :dataset_uri => @@dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc")
    assert_equal model_uri.uri?, true
    @@model = OpenTox::Model.new model_uri, @@subjectid
    assert_equal @@model.uri.uri?, true
    feature_dataset_uri = @@model[RDF::OT.featureDataset]
    feature_dataset = OpenTox::Dataset.new feature_dataset_uri , @@subjectid
    assert_equal @@dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 54, feature_dataset.features.size
    assert_equal '[#6&A]-[#6&A]-[#6&A]=[#6&A]', OpenTox::Feature.new(feature_dataset.features.first.uri, @@subjectid).title

  end

  def test_03_lazar_bbrc_compound_prediction
    #@@model = OpenTox::Model.new "http://localhost:8086/model/75272f87-c6ef-4a60-8a1c-7c2257b1c212"
    #prediction_uri = "http://localhost:8084/dataset/bb04c06d-5419-4718-96bf-a88ec23f7824"
    [ {
      :compound => OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"),
      :prediction => "false",
      :confidence => 0.25281385281385277
    },{
      # lazar Parameter, min_frequency = 8
      :compound => OpenTox::Compound.from_smiles("c1ccccc1NN"),
      :prediction => "false",
      :confidence => 0.3639589577089577
    } ].each do |example|
      prediction_uri = @@model.run :compound_uri => example[:compound].uri
      prediction_dataset = OpenTox::Dataset.new prediction_uri, @@subjectid
      assert_equal prediction_dataset.uri.uri?, true
      prediction = prediction_dataset.predictions.select{|p| p[:compound].uri == example[:compound].uri}.first
      assert_equal example[:prediction], prediction[:value]
      assert_equal example[:confidence], prediction[:confidence]
    end
  end

  def test_04_lazar_bbrc_dataset_prediction
    # make a dataset prediction
    dataset = OpenTox::Dataset.new nil, @@subjectid
    dataset.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal dataset.uri.uri?, true
    prediction_uri = @@model.run :dataset_uri => dataset.uri
    prediction = OpenTox::Dataset.new prediction_uri, @@subjectid
    assert_equal prediction.uri.uri?, true
  end
=begin
=end

end
