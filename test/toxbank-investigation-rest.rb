require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

class BasicTest < Test::Unit::TestCase

  # check response from service
  def test_01_get_investigations_200
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {}, :subjectid => @@subjectid
    assert_equal 200, response.code
  end

  # check if default response header is text/uri-list
  def test_02_get_investigations_type
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {}, { :accept => 'text/uri-list', :subjectid => @@subjectid }
    assert_equal "text/uri-list", response.headers[:content_type]
  end

  # check sparql query call to all investigations
  def test_03_get_investigations_query
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {:query => "SELECT ?s WHERE { ?s ?p ?o } LIMIT 5" }, { :accept => 'application/sparql-results+xml', :subjectid => @@subjectid }
    assert_equal 200, response.code
  end

end

class BasicTestCRUDInvestigation < Test::Unit::TestCase

  RDF::TB  = RDF::Vocabulary.new "http://onto.toxbank.net/api/"
  RDF::ISA = RDF::Vocabulary.new "http://onto.toxbank.net/isa/"

  # check post to investigation service without file
  def test_01a_post_investigation_400
    assert_raise OpenTox::RestCallError do
    response =  OpenTox::RestClientWrapper.post $toxbank_investigation[:uri], {}, { :accept => 'text/dummy', :subjectid => $pi[:subjectid] }
    end
  end
=begin
  def test_01b_upload_empty_zip
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "empty.zip"
    assert_raise OpenTox::RestCallError do
    response = OpenTox::RestClientWrapper.post $toxbank_investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    end
  end
=end
  # create an investigation by uploading a zip file
  def test_02_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b.zip"
    #task_uri = `curl -k -X POST #{$toxbank_investigation[:uri]} -H "Content-Type: multipart/form-data" -F "file=@#{file};type=application/zip" -H "subjectid:#{@@subjectid}"`
    response = OpenTox::RestClientWrapper.post $toxbank_investigation[:uri], {:file => File.open(file), :allowReadByUser => "http://toxbanktest1.opentox.org:8080/toxbank/user/U2,http://toxbanktest1.opentox.org:8080/toxbank/user/U124"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    #puts task_uri
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    @@uri = URI(uri)
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert @@uri.host == URI($toxbank_investigation[:uri]).host
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    assert @g.has_predicate?(RDF::ISA.hasAccessionID)
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1b/}
    
    # POST zip on existing id
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1.zip"
    OpenTox::RestClientWrapper.post "#{@@uri}", {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    assert @g.has_predicate?(RDF::ISA.hasAccessionID)
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1/}
  end

  def test_03a_check_published
    #response = OpenTox::RestClientWrapper.get "#{@@uri}/published", {}, {:accept => "text/plain", :subjectid => $pi[:subjectid]}
    #assert !response
  end

  def test_03b_put_published
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :published => "true", :allowReadByGroup => "http://toxbanktest1.opentox.org:8080/toxbank/project/G2"},{ :subjectid => $pi[:subjectid] }
    assert response
  end

  def test_03c_check_published
    #response = OpenTox::RestClientWrapper.get "#{@@uri}/published", {}, {:accept => "text/plain", :subjectid => $pi[:subjectid]}
    #assert response
  end

  # get investigation/{id}/metadata in rdf and check content
  def test_04a_check_metadata
    # accept:application/rdf+xml
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    assert @g.has_predicate?(RDF::DC.title)
    assert @g.has_predicate?(RDF::DC.abstract)
    assert @g.has_predicate?(RDF::TB.hasKeyword)
    assert @g.has_predicate?(RDF::TB.hasOwner)
    assert @g.has_predicate?(RDF::ISA.hasAccessionID)
    assert @g.has_predicate?(RDF::TB.hasProject)
    assert @g.has_predicate?(RDF::TB.hasOrganisation)
    @g.query(:predicate => RDF::DC.title){|r| assert_match r[2].to_s, /Growth control of the eukaryote cell: a systems biology study in yeast/}
    @g.query(:predicate => RDF::TB.hasOwner){|r| assert_match r[2].to_s.split("/").last, /U115/}
    @g.query(:predicate => RDF::TB.hasOrganisation){|r| assert_match r[2].to_s.split("/").last, /G176/}
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1/}
    @g.query(:predicate => RDF::TB.hasProject){|r| assert_match r[2].to_s, /G2/}
    @g.query(:predicate => RDF::TB.hasKeyword){|r| assert_match r[2].to_s.split("#").last, /[Epigenetics|CellViabilityAssay|CellMigrationAssays]/}
    @g.query(:predicate => RDF::ISA.hasStudy){|r| assert_match r[2].to_s.split("/").last, /[S192|S193]/}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match r[2].to_s, /Background Cell growth underlies many key cellular and developmental processes/}
  end

  def test_04b
    # accept:text/turtle
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/turtle", :subjectid => $pi[:subjectid]}
    assert_equal "text/turtle", response.headers[:content_type]
  end

  def test_04c
    # accept:text/plain
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/plain", :subjectid => $pi[:subjectid]}
    assert_equal "text/plain", response.headers[:content_type]
  end

  # get investigation/{id} as text/uri-list
  def test_05_get_investigation_uri_list
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    assert_equal "text/uri-list", result.headers[:content_type]
  end

  # get investigation/{id} as application/zip
  def test_06_get_investigation_zip
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/zip", :subjectid => $pi[:subjectid]}
    assert_equal "application/zip", result.headers[:content_type]
  end

  # get investigation/{id} as text/tab-separated-values
  def test_07_get_investigation_tab
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/tab-separated-values", :subjectid => $pi[:subjectid]}
    assert_equal "text/tab-separated-values;charset=utf-8", result.headers[:content_type]
  end

  # get investigation/{id} as application/sparql-results+json
  def test_08_get_investigation_sparql
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_equal "application/rdf+xml", result.headers[:content_type]
  end

  def test_30_check_owner_policy
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "POST", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "PUT", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "DELETE", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "GET", $pi[:subjectid])
  end

  def test_31_check_policies
    assert_equal Array, OpenTox::Authorization.list_uri_policies(@@uri.to_s, @@subjectid).class
    assert_equal 4, OpenTox::Authorization.list_uri_policies(@@uri.to_s, @@subjectid).size
  end

  # check if uri is in uri-list
  def test_98_get_investigation
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {}, {:accept => "text/uri-list", :subjectid => @@subjectid}
    assert_match @@uri.to_s, response
    #assert response.index(@@uri.to_s) != nil, "URI: #{@@uri} is not in uri-list"
  end

  # delete investigation/{id}
  def test_99_a_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, :subjectid => $pi[:subjectid]
    assert_equal 200, result.code
    #assert result.match(/^Investigation [a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12} deleted$/)
    assert !OpenTox::Authorization.uri_has_policy(@@uri.to_s, $pi[:subjectid])
  end

  def test_99_b_check_urilist
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {}, {:accept => "text/uri-list", :subjectid => @@subjectid}
    assert_no_match /#{@@uri.to_s}/, response
  end

end


