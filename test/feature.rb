require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

class FeatureTest < Test::Unit::TestCase

  def setup
    @features = [
      #@@classification_training_dataset.features.keys.first,
      "http://apps.ideaconsult.net:8080/ambit2/feature/35796",
      #File.join(OpenTox::Model::Lazar.all.last,"predicted","value")

    ]
  end

  def test_feature
    @features.each do |uri|
      f = OpenTox::Feature.new(uri)
      assert_equal RDF::OT1.TUM_CDK_nAtom, f[RDF::OWL.sameAs]
      assert_equal RDF::OT1.TUM_CDK_nAtom, f.metadata[RDF::OWL.sameAs].first.to_s
      assert_equal [RDF::OT1.Feature,RDF::OT1.NumericFeature].sort, f[RDF.type].sort
    end
  end

=begin
  def test_owl
    #@features.each do |uri|
      validate_owl @features.first, @@subjectid unless CONFIG[:services]["opentox-dataset"].match(/localhost/)
      validate_owl @features.last, @@subjectid unless CONFIG[:services]["opentox-dataset"].match(/localhost/)
      # Ambit does not validate
    #end
  end
=end


end
