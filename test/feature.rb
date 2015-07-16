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
      #[:ntriples, "text/plain"],
      #[:rdfxml, "application/rdf+xml"],
      #[:turtle, 'text/turtle']
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

  def test_opentox_feature
    @feature = OpenTox::Feature.new
    @feature[:title] = "tost"
    @feature.put
    uri = @feature.uri
    p uri
    assert_equal true, URI.accessible?(@feature.uri), "#{@feature.uri} is not accessible."

    list = OpenTox::Feature.all 
    listsize1 = list.length
    assert_equal true, list.collect{|f| f["uri"]}.include?(@feature.uri)

    # modify feature
    @feature2 = OpenTox::Feature.new @feature.uri
    assert_equal "tost", @feature2[:title]
    assert_equal 'Feature', @feature2[:type]

    @feature2[:title] = "feature2"
    @feature2.put
    list = OpenTox::Feature.all 
    listsize2 = list.length
    assert_match "feature2", OpenTox::RestClientWrapper.get(@feature2.uri)
    refute_match "tost", OpenTox::RestClientWrapper.get(@feature2.uri)
    assert_equal listsize1, listsize2

    uri = @feature2.uri
    @feature2.delete
    assert_equal false, URI.accessible?(uri), "#{uri} is still accessible."
  end

  def test_duplicated_features
    metadata = {
      :title => "feature duplication test",
      :type => ["Feature", "StringFeature"],
      :description => "feature duplication test"
    }
    feature = OpenTox::Feature.create metadata
    dup_feature = OpenTox::Feature.find_or_create metadata
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


