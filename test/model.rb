require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

class ModelTest < Test::Unit::TestCase

  def test_01_create_and_set_parameters
    a = OpenTox::Model.new nil, @@subjectid
    a.title = "test model"
    a.parameters = [
      {RDF::DC.title => "test", RDF::OT.paramScope => "mandatory"},
      {RDF::DC.title => "test2", RDF::OT.paramScope => "optional"}
    ]
    assert_equal 2, a.parameters.size
    p = a.parameters.collect{|p| p if p[RDF::DC.title.to_s] == "test"}.compact.first
    assert_equal "mandatory", p[RDF::OT.paramScope.to_s] 
    a[RDF::OT.featureCalculationAlgorithm] = "http://webservices.in-silico.ch/algorithm/substucture/match_hits"
    a[RDF::OT.predictionAlgorithm] = "http://webservices.in-silico.ch/algorithm/regression/local_svm"
    a[RDF::OT.similarityAlgorithm] = "http://webservices.in-silico.ch/algorithm/similarity/tanimoto"
    a[RDF::OT.trainingDataset] = "http://webservices.in-silico.ch/dataset/4944"
    a[RDF::OT.dependentVariables] = "http://webservices.in-silico.ch/feature/LC50_mmol"
    a[RDF::OT.featureDataset] = "http://webservices.in-silico.ch/dataset/4964"
    a.put
    a.get
    assert_equal "test model", a.title
    assert_equal 2, a.parameters.size
    p = a.parameters.collect{|p| p if p[RDF::DC.title.to_s] == "test"}.compact.first
    assert_equal "mandatory", p[RDF::OT.paramScope.to_s] 
    puts a.to_turtle
    puts a.uri
    #a.run :compound_uri => OpenTox::Compound.from_smiles($compound[:uri], "c1ccccc1NN").uri
    a.delete
  end
end