require_relative "setup.rb"

class LazarPhyschemDescriptorTest < MiniTest::Test

  def test_lazar_pc_descriptors

    # check available descriptors
    desc = OpenTox::Algorithm::Descriptor.physchem_descriptors.keys
    assert_equal 111,desc.size,"wrong num physchem descriptors"
    sum = 0
    {"Openbabel"=>16,"Cdk"=>50,"Joelib"=>45}.each do |k,v|
      assert_equal v,desc.select{|x| x=~/^#{k}\./}.size,"wrong num #{k} descriptors"
      sum += v
    end
    assert_equal 111,sum

    # select descriptors for test
    num_features_offset = 0
    desc.keep_if{|x| x=~/^Openbabel\./}
    desc.delete("Openbabel.L5") # TODO Openbabel.L5 does not work, investigate!!!
    unless defined?($short_tests)
      # the actual descriptor calculation is rather fast, computing 3D structures takes time
      # A CDK descriptor can calculate serveral values, e.g., ALOGP produces ALOGP.ALogP, ALOGP.ALogp2, ALOGP.AMR
      # both is accepted (and tested here): Cdk.ALOGP (produces 3 features), or ALOGP.AMR (produces only 1 feature)
      desc += ["Cdk.ALOGP.AMR", "Cdk.WienerNumbers", "Joelib.LogP", "Joelib.count.HeteroCycles"]
      num_features_offset = 1 # Cdk.WienerNumbers produces 2 (instead of 1) features
    end
    puts "Descriptors: #{desc}"

    # UPLOAD DATA
    dataset = OpenTox::Dataset.new 
    dataset.upload File.join(DATA_DIR,"EPAFHM.medi.csv")
    assert_equal dataset.uri.uri?, true
    puts "Dataset: "+dataset.uri

    # BUILD MODEL
    model_uri = OpenTox::Model::Lazar.create :dataset_uri => dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"descriptor","physchem"), :descriptors => desc
    puts "Model: "+model_uri
    model = OpenTox::Model::Lazar.new model_uri
    assert_equal model_uri.uri?, true
    puts "Predicted variable: "+model.predicted_variable
    
    # CHECK FEATURE DATASET
    feature_dataset_uri = model.metadata[RDF::OT.featureDataset].first
    puts "Feature dataset: #{feature_dataset_uri}"
    features = OpenTox::Dataset.new(feature_dataset_uri).features
    feature_titles = features.collect{|f| f.title}
    desc.each do |d|
      if (d=~/^Cdk\./ and d.count(".")==1) # CDK descriptors (e.g. Cdk.ALOG are included as Cdk.ALOGP.ALogP, Cdk.ALOGP.ALogp2 ..)
        match = false
        feature_titles.each do |f|
          match = true if f=~/d/
        end
        assert match,"feature not found #{d} in feature dataset #{feature_titles.inspect}"
      else
        assert feature_titles.include?(d),"feature not found #{d} in feature dataset #{feature_titles.inspect}"
      end
    end
    assert_equal (desc.size+num_features_offset),features.size,"wrong num features in feature dataset"

    # predict compound
    compound_uri = "#{$compound[:uri]}/InChI=1S/C13H8Cl2O2/c14-12-5-4-11(7-13(12)15)17-10-3-1-2-9(6-10)8-16/h1-8H"
    prediction_uri = model.predict :compound_uri => compound_uri
    prediction = OpenTox::Dataset.new prediction_uri
    assert_equal prediction.uri.uri?, true
    puts "Prediction "+prediction.uri
    
    # check prediction
    assert prediction.features.collect{|f| f.uri}.include?(model.predicted_variable),"prediction feature #{model.predicted_variable} not included prediction dataset #{prediction.features.collect{|f| f.uri}}"
    assert prediction.compounds.collect{|c| c.uri}.include?(compound_uri),"compound #{compound_uri} not included in prediction dataset #{prediction.compounds.collect{|c| c.uri}}"
    assert_equal 1,prediction.compound_indices(compound_uri).size,"compound should only be once in the dataset"
    predicted_value = prediction.data_entry_value(prediction.compound_indices(compound_uri).first,model.predicted_variable)
    puts "Predicted value: #{predicted_value}"
    assert predicted_value > 0.005,"predicted values should be above 0.005, is #{predicted_value}"
    assert predicted_value < 0.1,"predicted values should be below 0.1, is #{predicted_value}"

  end

end
