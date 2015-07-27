require_relative "setup.rb"

class LazarFminerTest < MiniTest::Test

  def test_lazar_fminer
    training_dataset = OpenTox::Dataset.from_csv_file File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    feature_dataset = OpenTox::Algorithm::Fminer.bbrc(:dataset => training_dataset)
    #p feature_dataset
    model = OpenTox::Model::Lazar.create training_dataset, feature_dataset
    #feature_dataset = OpenTox::Dataset.find model.feature_dataset_id
    p model
    assert_equal training_dataset.compounds.size, feature_dataset.compounds.size
    assert_equal 54, feature_dataset.features.size
    #feature_dataset.data_entries.each do |e|
      #assert_equal e.size, feature_dataset.features.size
    #end
    assert_equal '[#6&A]-[#6&A]-[#6&A]=[#6&A]', feature_dataset.features.first.smarts

    [ {
      :compound => OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"),
      :prediction => "false",
      :confidence => 0.25281385281385277
    },{
      :compound => OpenTox::Compound.from_smiles("c1ccccc1NN"),
      :prediction => "false",
      :confidence => 0.3639589577089577
    } ].each do |example|
      prediction_dataset = model.predict :compound => example[:compound]

      prediction = prediction_dataset.data_entries.first.first
      confidence = prediction_dataset.data_entries.first.last
      assert_equal example[:prediction], prediction
      assert_equal example[:confidence], confidence
    end

    # make a dataset prediction
    compound_dataset = OpenTox::Dataset.from_sdf File.join(DATA_DIR,"EPAFHM.mini.csv")
    #assert_equal compound_dataset.uri.uri?, true
    prediction = model.predict :dataset => compound_dataset
    assert_equal compound_dataset.compounds, prediction.compounds
    #prediction = OpenTox::Dataset.new prediction_uri
    #assert_equal prediction.uri.uri?, true

    # cleanup
    [dataset,model,feature_dataset,compound_dataset].each{|o| o.delete}
  end
end
