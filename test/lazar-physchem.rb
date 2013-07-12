require_relative "setup.rb"

class LazarPhyschemDescriptorTest < MiniTest::Test

  def test_lazar_pc_descriptors
    dataset = OpenTox::Dataset.new 
    dataset.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal dataset.uri.uri?, true

    model_uri = OpenTox::Model::Lazar.create :dataset_uri => dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"descriptor","physchem"), :descriptors => [ "Openbabel.atoms", "Openbabel.bonds", "Openbabel.dbonds", "Openbabel.HBA1", "Openbabel.HBA2", "Openbabel.HBD", "Openbabel.MP", "Openbabel.MR", "Openbabel.MW", "Openbabel.nF", "Openbabel.sbonds", "Openbabel.tbonds", "Openbabel.TPSA"]

    puts model_uri
    model = OpenTox::Model::Lazar.new model_uri
    assert_equal model_uri.uri?, true
    prediction_uri = model.predict :compound_uri => "#{$compound[:uri]}/InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    prediction = OpenTox::Dataset.new prediction_uri
    assert_equal prediction.uri.uri?, true
    #TODO check correct prediction
    puts prediction.uri
  end

end
