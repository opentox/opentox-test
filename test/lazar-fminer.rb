require_relative "setup.rb"

class LazarFminerTest < MiniTest::Test

  def test_lazar_fminer
    dataset = OpenTox::Dataset.new
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    model = OpenTox::Model::Lazar.create OpenTox::Algorithm::Fminer.bbrc(:dataset => dataset)
    feature_dataset = OpenTox::Dataset.find model.feature_dataset_id
    assert_equal dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 54, feature_dataset.features.size
    feature_dataset.data_entries.each do |e|
      assert_equal e.size, feature_dataset.features.size
    end
    assert_equal '[#6&A]-[#6&A]-[#6&A]=[#6&A]', feature_dataset.features.first.title

    [ {
      :compound => OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"),
      :prediction => "false",
      :confidence => 0.25281385281385277
    },{
      :compound => OpenTox::Compound.from_smiles("c1ccccc1NN"),
      :prediction => "false",
      :confidence => 0.3639589577089577
    } ].each do |example|
      prediction = model.predict :compound => example[:compound]
      p prediction
      p prediction.features
      p prediction.compounds
      prediction = prediction_dataset.predictions.select{|p| p[:compound].uri == example[:compound].uri}.first
      assert_equal example[:prediction], prediction[:value]
      assert_equal example[:confidence], prediction[:confidence]
      prediction_dataset.delete
    end

    # make a dataset prediction
    compound_dataset = OpenTox::Dataset.new
    compound_dataset.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal compound_dataset.uri.uri?, true
    prediction_uri = model.predict :dataset_uri => dataset.uri
    prediction = OpenTox::Dataset.new prediction_uri
    assert_equal prediction.uri.uri?, true

    # cleanup
    [dataset,model,feature_dataset,compound_dataset].each{|o| o.delete}
  end
end
