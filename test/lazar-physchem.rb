require_relative "setup.rb"

class LazarPhyschemDescriptorTest < MiniTest::Test

  def test_lazar_pc_descriptors
    dataset = OpenTox::Dataset.new 
    dataset.upload File.join(DATA_DIR,"EPAFHM.medi.csv")
    assert_equal dataset.uri.uri?, true
    puts dataset.uri

    model_uri = OpenTox::Model::Lazar.create :dataset_uri => dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"descriptor","physchem"), :descriptors => [ "Openbabel.atoms", "Openbabel.bonds", "Openbabel.dbonds", "Openbabel.HBA1", "Openbabel.HBA2", "Openbabel.HBD", "Openbabel.MP", "Openbabel.MR", "Openbabel.MW", "Openbabel.nF", "Openbabel.sbonds", "Openbabel.tbonds", "Openbabel.TPSA"]
#    model_uri = "http://localhost:8085/model/437f008a-ca0f-4a85-83c1-d851ef2be60c"
    puts model_uri
    model = OpenTox::Model::Lazar.new model_uri
    assert_equal model_uri.uri?, true
    puts model.predicted_variable

    compound_uri = "#{$compound[:uri]}/InChI=1S/C13H8Cl2O2/c14-12-5-4-11(7-13(12)15)17-10-3-1-2-9(6-10)8-16/h1-8H"
    prediction_uri = model.predict :compound_uri => compound_uri
#    prediction_uri = "http://localhost:8083/dataset/1e2d48d2-f720-4575-b192-524586630ac3"

    prediction = OpenTox::Dataset.new prediction_uri
    assert_equal prediction.uri.uri?, true
    puts prediction.uri

    assert prediction.features.collect{|f| f.uri}.include?(model.predicted_variable),"prediction feature #{model.predicted_variable} not included prediction dataset #{prediction.features.collect{|f| f.uri}}"
    assert prediction.compounds.collect{|c| c.uri}.include?(compound_uri),"compound #{compound_uri} not included in prediction dataset #{prediction.compounds.collect{|c| c.uri}}"
    assert_equal 1,prediction.compound_indices(compound_uri).size,"compound should only be once in the dataset"

    predicted_value = prediction.data_entry_value(prediction.compound_indices(compound_uri).first,model.predicted_variable) #[model.predicted_variable]
    puts predicted_value
    assert predicted_value > 0.01
    assert predicted_value < 0.1
  end

end
