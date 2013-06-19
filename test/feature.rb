require_relative "setup.rb"

class FeatureRestTest < MiniTest::Test

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
  def test_rest_feature
    @rdf = RDF::Graph.new
    subject = RDF::URI.new File.join($feature[:uri], SecureRandom.uuid)
    @rdf << RDF::Statement.new(subject, RDF::DC.title, "tost" )
    @rdf << RDF::Statement.new(subject, RDF.type, RDF::OT.Feature)

    @formats = [
      [:ntriples, "text/plain"],
      [:rdfxml, "application/rdf+xml"],
      [:turtle, 'text/turtle']
    ]
    @uris = []
    
    @formats.each do |f|
      @uris << subject.to_s
      OpenTox::RestClientWrapper.put(subject.to_s, serialize(@rdf, f[0]), {:subjectid => SUBJECTID, :content_type => f[1]}).chomp
      assert_equal true, URI.accessible?(@uris.last, SUBJECTID), "URI is not accessible uri: #{@uris.last}"
    end
    r = OpenTox::RestClientWrapper.get($feature[:uri], {}, :accept => "text/uri-list").split("\n")

    @uris.each do |uri|
      assert_equal true, URI.accessible?(uri, SUBJECTID), "URI is not accessible uri: #{uri}"
      assert_equal true, r.include?(uri)
      @formats.each do |f|
        rdf = OpenTox::RestClientWrapper.get(uri, {}, :accept => f[1])
        # TODO compare with rdf serialization
        assert_match /#{uri}/, rdf
      end
    end

    uri = @uris.first
    new_rdf = RDF::Graph.new
    new_rdf << RDF::Statement.new(RDF::Node.new, RDF::DC.author, "XYZ")
    @formats.each do |f|
      OpenTox::RestClientWrapper.post(uri, serialize(new_rdf,f[0]), :content_type => f[1])
      assert_match /XYZ/, OpenTox::RestClientWrapper.get(uri,{},:accept => f[1])
      # TODO compare with rdf serialization
    end

    @formats.each do |f|
      @uris.each do |uri|
        OpenTox::RestClientWrapper.put(uri, serialize(@rdf,f[0]), :content_type => f[1])
        assert_equal true, URI.accessible?(uri, SUBJECTID), "URI is not accessible uri: #{uri}"
        refute_match /XYZ/, OpenTox::RestClientWrapper.get(uri,{},:accept => f[1])
      end
    end

    @uris.each do |uri|
      OpenTox::RestClientWrapper.delete(uri)
      assert_raises OpenTox::ResourceNotFoundError do
        OpenTox::RestClientWrapper.get(uri)
      end
    end
  end

  def test_opentox_feature
    @feature = OpenTox::Feature.new nil, SUBJECTID
    @feature.title = "tost"
    @feature.put
    uri = @feature.uri
    assert_equal true, URI.accessible?(@feature.uri, SUBJECTID), "URI is not accessible uri: #{@feature.uri}"

    r = OpenTox::Feature.all SUBJECTID
    fsize = r.size
    assert_equal true, r.collect{|f| f.uri}.include?(@feature.uri)

    # modify feature
    @feature2 = OpenTox::Feature.new @feature.uri, SUBJECTID
    assert_equal "tost", @feature2.title
    assert_equal RDF::OT.Feature, @feature[RDF.type]

    @feature2.title = "feature2"
    @feature2.put
    f = OpenTox::Feature.all SUBJECTID
    fsize2 = f.size
    assert_match "feature2", OpenTox::RestClientWrapper.get(@feature2.uri)
    refute_match "tost", OpenTox::RestClientWrapper.get(@feature2.uri)
    assert_equal fsize, fsize2

    uri = @feature2.uri
    @feature2.delete
    assert_equal false, URI.accessible?(uri, SUBJECTID), "URI is still accessible uri: #{uri}"
  end

  def test_duplicated_features
    metadata = {
      RDF::DC.title => "test",
      RDF.type => [RDF::OT.Feature, RDF::OT.StringFeature],
      RDF::DC.description => "feature duplication test"
    }
    feature = OpenTox::Feature.create metadata, SUBJECTID
    dup_feature = OpenTox::Feature.find_or_create metadata, SUBJECTID
    assert_equal feature.uri, dup_feature.uri
    feature.delete
  end

end

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
      validate_owl @features.first, SUBJECTID unless CONFIG[:services]["opentox-dataset"].match(/localhost/)
      validate_owl @features.last, SUBJECTID unless CONFIG[:services]["opentox-dataset"].match(/localhost/)
      # Ambit does not validate
    #end
  end
=end


