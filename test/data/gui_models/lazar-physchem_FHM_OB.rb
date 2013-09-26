require_relative "setup.rb"

class LazarPhyschemDescriptorTest < MiniTest::Test

  def test_lazar_pc_descriptors
    dataset = OpenTox::Dataset.new
    dataset.upload File.join(DATA_DIR, "gui_models", "EPA_v4b_Fathead_Minnow_Acute_Toxicity_LC50-mmol.csv")
    puts dataset.uri

#OB
    model_uri = OpenTox::Model::Lazar.create :dataset_uri => dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"descriptor","physchem"), :descriptors => ["Openbabel.HBA1", "Openbabel.HBA2", "Openbabel.HBD", "Openbabel.L5", "Openbabel.MP", "Openbabel.MR", "Openbabel.MW", "Openbabel.TPSA", "Openbabel.abonds", "Openbabel.atoms", "Openbabel.bonds", "Openbabel.dbonds", "Openbabel.logP", "Openbabel.nF", "Openbabel.sbonds", "Openbabel.tbonds" ]

    puts model_uri
  end
end
