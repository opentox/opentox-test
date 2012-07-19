require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

class FeatureRestTest < Test::Unit::TestCase

  def serialize rdf, format
    string = RDF::Writer.for(format).buffer  do |writer|
      rdf.each{|statement| writer << statement}
    end
    string
  end

  def parse string, format
    rdf = RDF::Graph.new
    RDF::Reader.for(format).new(string) do |reader|
      reader.each_statement { |statement| rdf << statement }
    end
    rdf
  end

  # TODO: test supported accept/content-type formats
  # TODO: test invalid rdfs
  def test_01_create_feature
    @@rdf = RDF::Graph.new
    subject = RDF::URI.new File.join($feature[:uri], SecureRandom.uuid)
    @@rdf << RDF::Statement.new(subject, RDF::DC.title, "test" )
    @@rdf << RDF::Statement.new(subject, RDF.type, RDF::OT.Feature)

    @@formats = [
      [:ntriples, "text/plain"],
      [:rdfxml, "application/rdf+xml"],
      [:turtle, 'text/turtle']
    ]
    @@uris = []
    
    @@formats.each do |f|
      @@uris << subject.to_s
      OpenTox::RestClientWrapper.put(subject.to_s, serialize(@@rdf, f[0]), {:subjectid => @@subjectid, :content_type => f[1]}).chomp
      assert_equal true, URI.accessible?(@@uris.last, @@subjectid)
    end
  end

  def test_02_list_features
    r = OpenTox::RestClientWrapper.get($feature[:uri], {}, :accept => "text/uri-list")#.split("\n")
    @@uris.each{ |uri| assert_equal true, r.include?(uri) }
  end

  def test_03_get_feature
    @@uris.each do |uri|
      @@formats.each do |f|
        rdf = OpenTox::RestClientWrapper.get(uri, {}, :accept => f[1])
        # TODO compare with rdf serialization
        assert_match /#{uri}/, rdf
      end
    end
  end

  def test_04_add_to_feature
    uri = @@uris.first
    new_rdf = RDF::Graph.new
    new_rdf << RDF::Statement.new(RDF::Node.new, RDF::DC.author, "XYZ")
    @@formats.each do |f|
      OpenTox::RestClientWrapper.post(uri, serialize(new_rdf,f[0]), :content_type => f[1])
      assert_match /XYZ/, OpenTox::RestClientWrapper.get(uri,{},:accept => f[1])
      # TODO compare with rdf serialization
    end
  end

  def test_05_replace_feature
    @@formats.each do |f|
      @@uris.each do |uri|
        OpenTox::RestClientWrapper.put(uri, serialize(@@rdf,f[0]), :content_type => f[1])
        assert_equal true, URI.accessible?(uri)
        assert_no_match /XYZ/, OpenTox::RestClientWrapper.get(uri,{},:accept => f[1])
      end
    end
  end

  def test_06_delete_feature
    @@uris.each do |uri|
      OpenTox::RestClientWrapper.delete(uri)
      assert_raise OpenTox::NotFoundError do
      #assert_raise OpenTox::NotFoundError do
        OpenTox::RestClientWrapper.get(uri)
      end
    end
  end

  def test_11_create_feature
    @@feature = OpenTox::Feature.new nil, @@subjectid
    @@feature.title = "test"
    @@feature.put
    assert_equal true, URI.accessible?(@@feature.uri)
  end

  def test_12_list_features
    r = OpenTox::Feature.all $feature[:uri], @@subjectid
    assert_equal true, r.collect{|f| f.uri}.include?(@@feature.uri)
  end

  def test_13_get_feature
    @@feature.get
    assert_equal "test", @@feature.title
    assert_equal RDF::OT.Feature, @@feature[RDF.type]
  end

  def test_14_update_feature
    @@feature.title = "test2"
    @@feature.put
    assert_match "test", OpenTox::RestClientWrapper.get(@@feature.uri)
  end

  def test_15_delete_feature
    uri = @@feature.uri
    @@feature.delete
    assert_equal false, URI.accessible?(uri)
  end

end
=begin
=end


=begin
  def test_ambit_feature
    uri = "http://apps.ideaconsult.net:8080/ambit2/feature/35796",
    f = OpenTox::Feature.new(uri)
    assert_equal RDF::OT1.TUM_CDK_nAtom, f[RDF::OWL.sameAs]
    assert_equal RDF::OT1.TUM_CDK_nAtom, f.metadata[RDF::OWL.sameAs].first.to_s
    assert_equal [RDF::OT1.Feature,RDF::OT1.NumericFeature].sort, f[RDF.type].sort
  end
  def test_owl
    #@features.each do |uri|
      validate_owl @features.first, @@subjectid unless CONFIG[:services]["opentox-dataset"].match(/localhost/)
      validate_owl @features.last, @@subjectid unless CONFIG[:services]["opentox-dataset"].match(/localhost/)
      # Ambit does not validate
    #end
  end
=end


