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

  # check post to investigation service without file
  def test_01_post_investigation_400
    assert_raise OpenTox::RestCallError do
      response =  OpenTox::RestClientWrapper.post $toxbank_investigation[:uri], {}, { :accept => 'text/dummy', :subjectid => @@subjectid }
    end
  end

  # create an investigation by uploading a zip file
  def test_02_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1.zip"
    #task_uri = `curl -k -X POST #{$toxbank_investigation[:uri]} -H "Content-Type: multipart/form-data" -F "file=@#{file};type=application/zip" -H "subjectid:#{@@subjectid}"`
    response =  OpenTox::RestClientWrapper.post $toxbank_investigation[:uri], {:file => File.open(file)}, { :subjectid => @@subjectid }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    @@uri = URI(uri)
    assert @@uri.host == URI($toxbank_investigation[:uri]).host
  end

  # get investigation/{id}/metadata in rdf and check contents
  def test_03a_check_metadata
    # accept:application/rdf+xml
    response = OpenTox::RestClientWrapper.get "#{@@uri}", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /[Term Source Name, OBI, DOID, BTO, NEWT, UO, CHEBI, PATO, TBP, TBC, TBO, TBU, TBK]/, response
    assert_match /[Investigation Identifier, BII\-I\-1]/, response
    assert_match /[Investigation Title, Growth control of the eukaryote cell\: a systems biology study in yeast]/, response
    assert_match /[Investigation Description, Background Cell growth underlies many key cellular and developmental processes]/, response
    assert_match /[Owning Organisation URI, TBO\:G176, 	Public]/, response
    assert_match /[Consortium URI, TBC\:G2, Douglas Connect]/, response
    assert_match /[Principal Investigator URI, TBU\:U115, Glenn	Myatt]/, response
    assert_match /[Investigation keywords, TBK\:Blotting, Southwestern;TBK\:Molecular Imaging;DOID\:primary carcinoma of the liver cells]/, response
    # metadata
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /[title, Growth control of the eukaryote cell]/, response
    assert_match /[hasStudy, S1, S2]/, response
    assert_match /[abstract, Background
    Cell growth underlies many key cellular and developmental processes]/, response
    assert_match /[hasOwner, ISA_3977, ISA_3976, ISA_3975]/, response
    # resource
    response = OpenTox::RestClientWrapper.get "#{@@uri}/ISA_3977", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /[givenname, Zeef, family_name, Leo]/, response
    response = OpenTox::RestClientWrapper.get "#{@@uri}/ISA_3976", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /[givenname, Castrillo, family_name, Juan]/, response
    response = OpenTox::RestClientWrapper.get "#{@@uri}/ISA_3975", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /[givenname, Stephen, family_name, Oliver]/, response
    # Study
    response = OpenTox::RestClientWrapper.get "#{@@uri}/S1", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /[title, A time course analysis of  transcription response in yeast treated with rapamycin]/, response
    response = OpenTox::RestClientWrapper.get "#{@@uri}/S2", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /[title, Study of the impact of changes in flux on the transcriptome]/, response
    # Protocol
    response = OpenTox::RestClientWrapper.get "#{@@uri}/P_1110", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /[label, EukGE\-WS4]/, response
  end

  def test_03b
    # accept:text/turtle
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/turtle", :subjectid => @@subjectid}
    assert_equal "text/turtle", response.headers[:content_type]
  end

  def test_03c
    # accept:text/plain
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/plain", :subjectid => @@subjectid}
    assert_equal "text/plain", response.headers[:content_type] 
  end

  # get investigation/{id} as text/uri-list
  def test_04_get_investigation_uri_list
    #puts @@uri
    #@@uri = "http://toxbank-ch.in-silico.ch/60"
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/uri-list", :subjectid => @@subjectid}
    #puts result.to_yaml
    assert_equal "text/uri-list", result.headers[:content_type]
  end

  # get investigation/{id} as application/zip
  def test_05_get_investigation_zip
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/zip", :subjectid => @@subjectid}
    assert_equal "application/zip", result.headers[:content_type]
  end

  # get investigation/{id} as text/tab-separated-values
  def test_06_get_investigation_tab
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/tab-separated-values", :subjectid => @@subjectid}
    assert_equal "text/tab-separated-values;charset=utf-8", result.headers[:content_type]
  end

  # get investigation/{id} as application/sparql-results+json
  def test_07_get_investigation_sparql
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_equal "application/rdf+xml", result.headers[:content_type]
  end

  # check if uri is in uri-list
  def test_98_get_investigation
    response = OpenTox::RestClientWrapper.get $toxbank_investigation[:uri], {}, :subjectid => @@subjectid
    assert response.index(@@uri.to_s) != nil, "URI: #{@@uri} is not in uri-list"
  end

  # delete investigation/{id}
  def test_99_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, :subjectid => @@subjectid
    assert result.match(/^Investigation [a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12} deleted$/)
    assert !OpenTox::Authorization.uri_has_policy(@@uri.to_s, @@subjectid)
  end

end


