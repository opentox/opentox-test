require_relative "setup.rb"

class LazarPhyschemDescriptorTest < MiniTest::Test

  def test_lazar_pc_descriptors

    # check available descriptors
    @descriptors = OpenTox::Algorithm::Descriptor.physchem_descriptors.keys
    assert_equal 111,@descriptors.size,"wrong num physchem descriptors"
    sum = 0
    {"Openbabel"=>16,"Cdk"=>50,"Joelib"=>45}.each do |k,v|
      assert_equal v,@descriptors.select{|x| x=~/^#{k}\./}.size,"wrong num #{k} descriptors"
      sum += v
    end
    assert_equal 111,sum

    # select descriptors for test
    @num_features_offset = 0
    @descriptors.keep_if{|x| x=~/^Openbabel\./}
    @descriptors.delete("Openbabel.L5") # TODO Openbabel.L5 does not work, investigate!!!
    unless defined?($short_tests)
      # the actual descriptor calculation is rather fast, computing 3D structures takes time
      # A CDK descriptor can calculate serveral values, e.g., ALOGP produces ALOGP.ALogP, ALOGP.ALogp2, ALOGP.AMR
      # both is accepted (and tested here): Cdk.ALOGP (produces 3 features), or ALOGP.AMR (produces only 1 feature)
      @descriptors += ["Cdk.ALOGP.AMR", "Cdk.WienerNumbers", "Joelib.LogP", "Joelib.count.HeteroCycles"]
      @num_features_offset = 1 # Cdk.WienerNumbers produces 2 (instead of 1) features
    end
    puts "Descriptors: #{@descriptors}"

    # UPLOAD DATA
    @dataset = OpenTox::Dataset.new 
    @dataset.upload File.join(DATA_DIR,"EPAFHM.medi.csv")
    assert_equal @dataset.uri.uri?, true
    puts "Dataset: "+@dataset.uri

    @compound_smiles = "CC(C)(C)CN"
    @compound_inchi = "InChI=1S/C5H13N/c1-5(2,3)4-6/h4,6H2,1-3H3"

    prediction_a = build_model_and_predict(true)
    prediction_b = build_model_and_predict(false)
    
    assert_equal prediction_a,prediction_b,"predicted value differs depending on calculation method"
    puts "Predicted value: #{prediction_a}"
    # the actual value (from the complete EPAFHM dataset) is 5.45, but it is predicted higher when tested
    # do not expect a fixed value, this might vary with, e.g., the calculated 3d structure by OB
    assert prediction_a > 5,"predicted values should be above 5, is #{prediction_a}"
    assert prediction_a < 15,"predicted values should be below 15, is #{prediction_a}"
  end

  def build_model_and_predict(precompute_feature_dataset=true)

    model_params = {:dataset_uri => @dataset.uri}
    feat_gen_uri = File.join($algorithm[:uri],"descriptor","physchem")
    
    if precompute_feature_dataset
      # PRECOMPUTE FEATURES
      p = "/tmp/mergedfile.csv"
      f = File.open(p,"w")
      f.puts File.read(File.join(DATA_DIR,"EPAFHM.medi.csv"))
      f.puts "\"#{@compound_smiles}\","
      f.close
      d = OpenTox::Dataset.new 
      d.upload p
      model_params[:feature_dataset_uri] = OpenTox::Algorithm::Generic.new(feat_gen_uri).run({:dataset_uri => d.uri, :descriptors => @descriptors})
    else
      model_params[:feature_generation_uri] = feat_gen_uri
      model_params[:descriptors] = @descriptors
    end
      
    # BUILD MODEL
    model_uri = OpenTox::Model::Lazar.create model_params
    puts "Model: "+model_uri
    model = OpenTox::Model::Lazar.new model_uri
    assert_equal model_uri.uri?, true
    puts "Predicted variable: "+model.predicted_variable
    
    # CHECK FEATURE DATASET
    feature_dataset_uri = model.metadata[RDF::OT.featureDataset].first
    puts "Feature dataset: #{feature_dataset_uri}"
    feature_dataset = OpenTox::Dataset.new(feature_dataset_uri)
    assert_equal @dataset.compounds.size,feature_dataset.compounds.size-(precompute_feature_dataset ? 1 : 0),"num compounds in feature dataset not correct"
    features = feature_dataset.features
    feature_titles = features.collect{|f| f.title}
    @descriptors.each do |d|
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
    assert_equal (@descriptors.size+@num_features_offset),features.size,"wrong num features in feature dataset"

    # predict compound
    compound_uri = "#{$compound[:uri]}/#{@compound_inchi}"
    prediction_uri = model.predict :compound_uri => compound_uri
    prediction = OpenTox::Dataset.new prediction_uri
    assert_equal prediction.uri.uri?, true
    puts "Prediction "+prediction.uri
    
    # check prediction
    assert prediction.features.collect{|f| f.uri}.include?(model.predicted_variable),"prediction feature #{model.predicted_variable} not included prediction dataset #{prediction.features.collect{|f| f.uri}}"
    assert prediction.compounds.collect{|c| c.uri}.include?(compound_uri),"compound #{compound_uri} not included in prediction dataset #{prediction.compounds.collect{|c| c.uri}}"
    assert_equal 1,prediction.compound_indices(compound_uri).size,"compound should only be once in the dataset"
    prediction.data_entry_value(prediction.compound_indices(compound_uri).first,model.predicted_variable)
  end

end
