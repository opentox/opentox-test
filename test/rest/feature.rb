require_relative "setup.rb"

class FeatureRestTest < MiniTest::Test

  def serialize rdf, format
    return rdf.to_json if format == 'application/json'
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
    #@rdf = RDF::Graph.new
    #subject = RDF::URI.new File.join($feature[:uri], SecureRandom.uuid)
    #@rdf << RDF::Statement.new(subject, RDF::DC.title, "tost" )
    #@rdf << RDF::Statement.new(subject, RDF.type, RDF::OT.Feature)
    metadata = {:uri => File.join($feature[:uri], SecureRandom.uuid), :title =>  "tost" , :type => "Feature" }

    @formats = [
      # TODO
      [:ntriples, "text/plain"],
      [:rdfxml, "application/rdf+xml"],
      [:turtle, 'text/turtle']
      [:json, 'application/json']
    ]
    @uris = []
    
    @formats.each do |f|
      @uris << metadata[:uri]
      OpenTox::RestClientWrapper.put(metadata[:uri], metadata.to_json, {:content_type => f[1]}).chomp
      #OpenTox::RestClientWrapper.put(subject.to_s, serialize(@rdf, f[0]), {:content_type => f[1]}).chomp
      assert_equal true, URI.accessible?(@uris.last), "#{@uris.last} is not accessible."
    end
    r = OpenTox::RestClientWrapper.get($feature[:uri], {}, :accept => "text/uri-list").split("\n")

    @uris.each do |uri|
      assert_equal true, URI.accessible?(uri), "#{uri} is not accessible."
      assert_equal true, r.include?(uri)
      @formats.each do |f|
        response = OpenTox::RestClientWrapper.get(uri, {}, :accept => f[1])
        # TODO compare with rdf serialization
        assert_match /#{uri}/, response
      end
    end

    uri = @uris.first
    metadata[:title] = "XYZ"
    @formats.each do |f|
      OpenTox::RestClientWrapper.post(uri, metadata.to_json, :content_type => f[1])
      assert_match /XYZ/, OpenTox::RestClientWrapper.get(uri,{},:accept => f[1])
      # TODO compare with rdf serialization
    end

    @formats.each do |f|
      @uris.each do |uri|
        OpenTox::RestClientWrapper.put(uri, metadata.to_json, :content_type => f[1])
        assert_equal true, URI.accessible?(uri), "#{uri} is not accessible."
        # CH: why refute? XYZ has been set as title for the first uri
        # refute_match /XYZ/, OpenTox::RestClientWrapper.get(uri,{},:accept => f[1])
      end
    end

    @uris.each do |uri|
      OpenTox::RestClientWrapper.delete(uri)
      assert_raises OpenTox::ResourceNotFoundError do
        OpenTox::RestClientWrapper.get(uri)
      end
    end
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
