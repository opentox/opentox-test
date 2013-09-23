require_relative "setup.rb"

class LazarModelTest < MiniTest::Test

  MODELS = []
  # test hamster
#  MODELS << {
#    :titel => "hamster_carcinogenicity",
#    :file => File.join(DATA_DIR,"hamster_carcinogenicity.csv"),
#    :type => "classification",
#    :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"),
#    :min_frequency => 2,
#    :test_values => {
#      :feature_size => 54,
#      :first_feature => "[#6&A]-[#6&A]-[#6&A]=[#6&A]",
#      :prediction1 => [OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H").uri,"false",0.25281385281385277],
#      :prediction2 => [OpenTox::Compound.from_smiles("c1ccccc1NN").uri,"false",0.3639589577089577]
#    }
#  }

  # Hamster
  MODELS << {
    :titel => "DSSTox_Carcinogenic_Potency_DBS_v5d_Hamster",
    :file => File.join(DATA_DIR,"CPDBAS_v5d_cleaned","DSSTox_Carcinogenic_Potency_DBS_Hamster.csv"),
    :type => "classification",
    :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"),
    :min_frequency => 2,
    :test_values => {
      :feature_size => 58,
      :first_feature => '[#6&A]-[#6&A]-[#6&A]=[#6&A]',
      :prediction1 => [OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H").uri,"inactive",0.23658008658008656],
      :prediction2 => [OpenTox::Compound.from_smiles("c1ccccc1NN").uri,"inactive",0.34980297480297484]
    }
  }

#  # Mutagenicity
#  MODELS << {
#    :titel => "DSSTox_Carcinogenic_Potency_DBS_v5d_Mutagenicity",
#    :file => File.join(DATA_DIR,"CPDBAS_v5d_cleaned","DSSTox_Carcinogenic_Potency_DBS_Mutagenicity_no_duplicates.csv"),
#    :type => "classification",
#    :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"),
#    :min_frequency => 8,
#    :test_values => {
#      :feature_size => 58,
#      :first_feature => '[#6&A]-[#6&A]-[#6&A]=[#6&A]',
#      :prediction1 => [OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H").uri,"inactive",0.23658008658008656],
#      :prediction2 => [OpenTox::Compound.from_smiles("c1ccccc1NN").uri,"inactive",0.34980297480297484]
#    }
#  }
#
#  # Mouse
#  MODELS << {
#    :titel => "DSSTox_Carcinogenic_Potency_DBS_v5d_Mouse",
#    :file => File.join(DATA_DIR,"CPDBAS_v5d_cleaned","DSSTox_Carcinogenic_Potency_DBS_Mouse.csv"),
#    :type => "classification",
#    :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"),
#    :min_frequency => 10,
#    :test_values => {
#      :feature_size => 58,
#      :first_feature => '[#6&A]-[#6&A]-[#6&A]=[#6&A]',
#      :prediction1 => [OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H").uri,"inactive",0.23658008658008656],
#      :prediction2 => [OpenTox::Compound.from_smiles("c1ccccc1NN").uri,"inactive",0.34980297480297484]
#    }
#  }
#
#  # Rat
#  MODELS << {
#    :titel => "DSSTox_Carcinogenic_Potency_DBS_v5d_Rat",
#    :file => File.join(DATA_DIR,"CPDBAS_v5d_cleaned","DSSTox_Carcinogenic_Potency_DBS_Rat.csv"),
#    :type => "classification",
#    :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"),
#    :min_frequency => 12,
#    :test_values => {
#      :feature_size => 58,
#      :first_feature => '[#6&A]-[#6&A]-[#6&A]=[#6&A]',
#      :prediction1 => [OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H").uri,"inactive",0.23658008658008656],
#      :prediction2 => [OpenTox::Compound.from_smiles("c1ccccc1NN").uri,"inactive",0.34980297480297484]
#    }
#  }
#
#
# # MultiCellCall
#  MODELS << {
#    :titel => "DSSTox_Carcinogenic_Potency_DBS_v5d_MultiCellCall",
#    :file => File.join(DATA_DIR,"CPDBAS_v5d_cleaned","DSSTox_Carcinogenic_Potency_DBS_MultiCellCall_no_duplicates.csv"),
#    :type => "classification",
#    :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"),
#    :min_frequency => 11,
#    :test_values => {
#      :feature_size => 58,
#      :first_feature => '[#6&A]-[#6&A]-[#6&A]=[#6&A]',
#      :prediction1 => [OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H").uri,"inactive",0.23658008658008656],
#      :prediction2 => [OpenTox::Compound.from_smiles("c1ccccc1NN").uri,"inactive",0.34980297480297484]
#    }
#  }
#
#
#  # SingleCellCall
#  MODELS << {
#    :titel => "DSSTox_Carcinogenic_Potency_DBS_v5d_SingleCellCall",
#    :file => File.join(DATA_DIR,"CPDBAS_v5d_cleaned","DSSTox_Carcinogenic_Potency_DBS_SingleCellCall.csv"),
#    :type => "classification",
#    :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc"),
#    :min_frequency => 15,
#    :test_values => {
#      :feature_size => 58,
#      :first_feature => '[#6&A]-[#6&A]-[#6&A]=[#6&A]',
#      :prediction1 => [OpenTox::Compound.from_inchi("InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H").uri,"inactive",0.23658008658008656],
#      :prediction2 => [OpenTox::Compound.from_smiles("c1ccccc1NN").uri,"inactive",0.34980297480297484]
#    }
#  }




  def test_lazar_models
    MODELS.each do |model|
      dataset = OpenTox::Dataset.new
      dataset.upload model[:file]
      assert_equal dataset.uri.uri?, true
#      puts model[:file]
#      puts dataset.uri
#      puts
      model_uri = OpenTox::Model::Lazar.create :dataset_uri => dataset.uri, :feature_generation_uri => model[:feature_generation_uri], :min_frequency => model[:min_frequency]
      assert_equal model_uri.uri?, true
#      puts "model_uri for '#{model[:titel]}': #{model_uri}"
      this_model = OpenTox::Model::Lazar.new model_uri
      assert_equal this_model.uri.uri?, true
      feature_dataset_uri = this_model[RDF::OT.featureDataset]
      feature_dataset = OpenTox::Dataset.new feature_dataset_uri
      assert_equal dataset.compounds.size, feature_dataset.compounds.size
      assert_equal model[:test_values][:feature_size], feature_dataset.features.size
#      puts feature_dataset.features.size
      assert_equal model[:test_values][:first_feature], OpenTox::Feature.new(feature_dataset.features.first.uri).title
#      puts OpenTox::Feature.new(feature_dataset.features.first.uri).title

      [ {
        :compound => model[:test_values][:prediction1][0],
        :prediction => model[:test_values][:prediction1][1],
        :confidence => model[:test_values][:prediction1][2]
      },{
        :compound => model[:test_values][:prediction2][0],
        :prediction => model[:test_values][:prediction2][1],
        :confidence => model[:test_values][:prediction2][2]
      } ].each do |example|
        prediction_uri = this_model.predict :compound_uri => example[:compound]
#        puts prediction_uri
        prediction_dataset = OpenTox::Dataset.new prediction_uri
        assert_equal prediction_dataset.uri.uri?, true
        prediction = prediction_dataset.predictions.select{|p| p[:compound].uri == example[:compound]}.first
        assert_equal example[:prediction], prediction[:value]
#        puts prediction[:value]
        assert_equal example[:confidence], prediction[:confidence]
#        puts prediction[:confidence]
#        puts prediction_dataset.uri
        prediction_dataset.delete
      end

      # make a dataset prediction
      compound_dataset = OpenTox::Dataset.new
      compound_dataset.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
      assert_equal compound_dataset.uri.uri?, true
      prediction_uri = this_model.predict :dataset_uri => dataset.uri
      prediction = OpenTox::Dataset.new prediction_uri
      assert_equal prediction.uri.uri?, true
#      puts prediction.uri

      # cleanup
      [dataset,this_model,feature_dataset,compound_dataset].each{|o| o.delete}
    end
  end
end
