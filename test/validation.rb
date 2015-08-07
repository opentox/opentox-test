require_relative "setup.rb"

class ValidationTest < MiniTest::Test

  def test_classification_crossvalidation
    dataset = Dataset.from_csv_file "#{DATA_DIR}/hamster_carcinogenicity.csv"
    features = Algorithm::Fminer.bbrc dataset
    model = Model::Lazar.create dataset, features
    cv = CrossValidation.create model
    p cv
  end

end
