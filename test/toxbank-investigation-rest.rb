require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class BasicTest < Test::Unit::TestCase
  
  # check response from service
  def test_01_get_investigations_200
    assert_raise OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, :subjectid => $pi[:subjectid]
    end
  end

  # check if default response header is text/uri-list
  def test_02_get_investigations_type
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, { :accept => 'text/uri-list', :subjectid => $pi[:subjectid] }
    assert_equal "text/uri-list", response.headers[:content_type]
  end
end

class BasicTestCRUDInvestigation < Test::Unit::TestCase

  RDF::TB  = RDF::Vocabulary.new "http://onto.toxbank.net/api/"
  RDF::ISA = RDF::Vocabulary.new "http://onto.toxbank.net/isa/"
  
  # check post to investigation service without file
  def test_01a_post_investigation_400_no_file
    assert_raise OpenTox::BadRequestError do
      response =  OpenTox::RestClientWrapper.post $investigation[:uri], {}, { :subjectid => $pi[:subjectid] }
    end
  end

  def test_01b_wrong_mime_type
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "empty.zup"
    assert_raise OpenTox::BadRequestError do
      response =  OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    end
  end

  def test_01c_upload_empty_zip
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "empty.zip" 
    assert_raise OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    end
  end

  # create an investigation by uploading a zip file
  def test_02_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b.zip"
    #task_uri = `curl -k -X POST #{$investigation[:uri]} -H "Content-Type: multipart/form-data" -F "file=@#{file};type=application/zip" -F "allowReadByUser=http://toxbanktest1.opentox.org:8080/toxbank/user/U2,http://toxbanktest1.opentox.org:8080/toxbank/user/U124" -H "subjectid:#{$pi[:subjectid]}"`
    #response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :allowReadByUser => "http://toxbanktest1.opentox.org:8080/toxbank/user/U2,http://toxbanktest1.opentox.org:8080/toxbank/user/U124"}, { :subjectid => $pi[:subjectid] }
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    #puts task_uri
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    #puts uri
    @@uri = URI(uri)
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert @@uri.host == URI($investigation[:uri]).host
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    assert @g.has_predicate?(RDF::ISA.hasAccessionID)
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1b/}
  end

  def test_02a_check_policy_file_not_listed
    result = OpenTox::RestClientWrapper.get("#{@@uri}", {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}).split("\n")
    assert result.grep(/user_policies/).size == 0
  end

  def test_03a_check_published_false
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /false/}
  end

  def test_03b_put_published
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :published => "true", :allowReadByGroup => "http://toxbanktest1.opentox.org:8080/toxbank/project/G2"},{ :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    #puts task_uri
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal uri, @@uri.to_s
  end

  def test_03c_check_published_true
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /true/}
  end

  def test_04a_check_summary_searchable_false
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /false/}
  end

  def test_04b_put_summary_searchable
    response = OpenTox::RestClientWrapper.put @@uri.to_s,{ :summarySearchable => "true" },{ :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    #puts task_uri
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal uri, @@uri.to_s
  end

  def test_04c_check_summary_searchable_true
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /true/}
  end

  # get investigation/{id}/metadata in rdf and check content
  def test_05a_check_metadata
    # accept:application/rdf+xml
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    assert @g.has_predicate?(RDF::DC.title)
    assert @g.has_predicate?(RDF::DC.abstract)
    assert @g.has_predicate?(RDF::TB.hasKeyword)
    assert @g.has_predicate?(RDF::TB.hasOwner)
    assert @g.has_predicate?(RDF::TB.isPublished)
    assert @g.has_predicate?(RDF::ISA.hasAccessionID)
    assert @g.has_predicate?(RDF::TB.hasProject)
    assert @g.has_predicate?(RDF::TB.hasOrganisation)
    @g.query(:predicate => RDF::DC.title){|r| assert_match r[2].to_s, /Growth control of the eukaryote cell: a systems biology study in yeast/}
    @g.query(:predicate => RDF::TB.hasOwner){|r| assert_match r[2].to_s.split("/").last, /U271/}
    #@g.query(:predicate => RDF::TB.hasOwner){|r| assert_match r[2].to_s.split("/").last, /U115/}
    @g.query(:predicate => RDF::TB.hasOrganisation){|r| assert_match r[2].to_s.split("/").last, /G176/}
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1/}
    @g.query(:predicate => RDF::TB.hasProject){|r| assert_match r[2].to_s, /G2/}
    @g.query(:predicate => RDF::TB.hasKeyword){|r| assert_match r[2].to_s.split("#").last, /[Epigenetics|CellViabilityAssay|CellMigrationAssays]/}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /true/}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /true/}
    @g.query(:predicate => RDF::ISA.hasStudy){|r| assert_match r[2].to_s.split("/").last, /[S192|S193]/}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match r[2].to_s, /Background Cell growth underlies many key cellular and developmental processes/}
  end

  def test_05b
    # accept:text/turtle
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/turtle", :subjectid => $pi[:subjectid]}
    assert_equal "text/turtle", response.headers[:content_type]
  end

  def test_05c
    # accept:text/plain
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/plain", :subjectid => $pi[:subjectid]}
    assert_match  /^text\/plain/ , response.headers[:content_type]
  end

  # get investigation/{id} as text/uri-list
  def test_06_get_investigation_uri_list
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    assert_equal "text/uri-list", result.headers[:content_type]
  end

  # get investigation/{id} as application/zip
  def test_07_get_investigation_zip
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/zip", :subjectid => $pi[:subjectid]}
    assert_equal "application/zip", result.headers[:content_type]
  end

  # get investigation/{id} as text/tab-separated-values
  def test_08_get_investigation_tab
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/tab-separated-values", :subjectid => $pi[:subjectid]}
    assert_equal "text/tab-separated-values;charset=utf-8", result.headers[:content_type]
  end

  # get investigation/{id} as application/rdf+xml
  def test_09_get_investigation_sparql
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_equal "application/rdf+xml", result.headers[:content_type]
  end

  def test_10_a_update_investigation
    # PUT zip on existing id
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1.zip"
    response = OpenTox::RestClientWrapper.put @@uri.to_s, {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    assert_equal 202, response.code
    task_uri = response.chomp
    puts "update investigation:#{task_uri}"
    task = OpenTox::Task.new task_uri
    task.wait
    # update is finished, check flags 
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_match /<\?xml/, response #PI can get
    assert_raise OpenTox::NotAuthorizedError do
      res = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    end #Guest get nothing
    # update flags
    response = OpenTox::RestClientWrapper.put @@uri.to_s,{ :summarySearchable => "true" },{ :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    puts "update isSS:#{task_uri}"
    task = OpenTox::Task.new task_uri
    task.wait
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_match /<\?xml/, response #PI can get
    res = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /<\?xml/, res #Guest can get if isSS
    # check content
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(res.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1/}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /false/}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /true/} 
    # check investigation data still not reachable as GUEST
    assert_raise OpenTox::NotAuthorizedError do
      res = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    end
    # update flag isP
    response = OpenTox::RestClientWrapper.put @@uri.to_s, {:published => "true"},{:subjectid => $pi[:subjectid]}
    task_uri = response.chomp
    puts "isPublished:#{task_uri}"
    task = OpenTox::Task.new task_uri
    task.wait
    res = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /<\?xml/, res #Guest can get if isP
  end

  # get investigation/{id}/metadata in rdf and check content
  def test_11_check_metadata_again
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    assert @g.has_predicate?(RDF::DC.title)
    assert @g.has_predicate?(RDF::DC.abstract)
    assert @g.has_predicate?(RDF::TB.hasKeyword)
    assert @g.has_predicate?(RDF::TB.hasOwner)
    assert @g.has_predicate?(RDF::TB.isPublished)
    assert @g.has_predicate?(RDF::ISA.hasAccessionID)
    assert @g.has_predicate?(RDF::TB.hasProject)
    assert @g.has_predicate?(RDF::TB.hasOrganisation)
    @g.query(:predicate => RDF::DC.title){|r| assert_match r[2].to_s, /Growth control of the eukaryote cell: a systems biology study in yeast/}
    @g.query(:predicate => RDF::TB.hasOwner){|r| assert_match r[2].to_s.split("/").last, /U271/}
    #@g.query(:predicate => RDF::TB.hasOwner){|r| assert_match r[2].to_s.split("/").last, /U115/}
    @g.query(:predicate => RDF::TB.hasOrganisation){|r| assert_match r[2].to_s.split("/").last, /G176/}
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1/}
    @g.query(:predicate => RDF::TB.hasProject){|r| assert_match r[2].to_s, /G2/}
    @g.query(:predicate => RDF::TB.hasKeyword){|r| assert_match r[2].to_s.split("#").last, /[Epigenetics|CellViabilityAssay|CellMigrationAssays]/}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /true/}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /true/}
    @g.query(:predicate => RDF::ISA.hasStudy){|r| assert_match r[2].to_s.split("/").last, /[S192|S193]/}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match r[2].to_s, /Background Cell growth underlies many key cellular and developmental processes/}
  end

  def test_30_check_owner_policy
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "POST", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "PUT", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "DELETE", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "GET", $pi[:subjectid])
  end

  def test_31_check_policies
    assert_equal Array, OpenTox::Authorization.list_uri_policies(@@uri.to_s, $pi[:subjectid]).class
    assert_equal 2, OpenTox::Authorization.list_uri_policies(@@uri.to_s, $pi[:subjectid]).size
  end

  def test_90_try_to_delete_id_as_guest
    assert_raise OpenTox::NotAuthorizedError do
      OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => @@subjectid}
    end
  end

  def test_91_try_to_delete_id_file_as_guest
    assert_raise OpenTox::NotAuthorizedError do
      OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => @@subjectid}
    end
  end

  def test_92_try_to_update_id_as_guest
    assert_raise OpenTox::NotAuthorizedError do
      OpenTox::RestClientWrapper.put @@uri.to_s, {:published => "true"},{:subjectid => @@subjectid}
    end
  end
  
  # check if uri is in uri-list
  def test_98_get_investigation
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    assert response.index(@@uri.to_s) != nil, "URI: #{@@uri} is not in uri-list"
  end

  # delete investigation/{id}
  def test_99_a_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => $pi[:subjectid]}
    assert_equal 200, result.code
    #assert result.match(/^Investigation [a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12} deleted$/)
    assert !OpenTox::Authorization.uri_has_policy(@@uri.to_s, $pi[:subjectid])
  end

  def test_99_b_check_urilist
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    assert_no_match /#{@@uri.to_s}/, response
  end

end


