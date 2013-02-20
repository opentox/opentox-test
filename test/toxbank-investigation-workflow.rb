require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
require File.join(File.expand_path(File.dirname(__FILE__)),".." ,".." ,"toxbank-investigation", "util.rb")

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TBInvestigationAA < Test::Unit::TestCase
# Permission Matrix for owner, user1 (with GET permission) and user2 (no permission)
# sum    = isSummarySearchable=true
# nosum  = isSummarySearchable=false
# Publ   = isPublished = true
# noPubl = isPublished = false
#                      noSum   Sum    Pub   noSum   Sum    Pub
#               owner  user1  user1  user1  user2  user2  user2
# GET             y      y      y      y      n      n      n
# POST,PUT,DEL    y      n      n      n      n      n      n
# /metadata       y      n      y      y      n      y      y
# /protocol       y      n      y      y      n      y      y
# Download        y      n      n      y      n      n      n
#

  RDF::TB  = RDF::Vocabulary.new "http://onto.toxbank.net/api/"
  RDF::ISA = RDF::Vocabulary.new "http://onto.toxbank.net/isa/"

  # create a new investigation by uploading a zip file,
  # owner is $pi, Summary is not searchable, access=custom(owner only), not published
  def test_01_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    @@uri = URI(uri)
  end

  # check if @@uri is not in search-index
  def test_02_investigation_not_in_searchindex
    response = OpenTox::RestClientWrapper.get "#{$search_service[:uri]}/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s)}",{},{:subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
    assert_no_match /#{@@uri}/, response.to_s
  end

  # check for flag "isPublished" is false,
  # @note default behaviour on new investigations
  def test_03_check_published_false
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /false/}
  end

  # check all permissions for owner
  def test_04a_all_permission
    response = OpenTox::Authorization.authorize "#{@@uri}", "GET", $pi[:subjectid]
    assert_equal true, response
    response = OpenTox::Authorization.authorize "#{@@uri}", "POST", $pi[:subjectid]
    assert_equal true, response
    response = OpenTox::Authorization.authorize "#{@@uri}", "PUT", $pi[:subjectid]
    assert_equal true, response
    response = OpenTox::Authorization.authorize "#{@@uri}", "DELETE", $pi[:subjectid]
    assert_equal true, response
  end

  # get metadata for owner
  def test_04b_get_metadata_pi
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
  end

  # get related protocol uris for owner
  def test_04c_get_protocol_pi
    response = OpenTox::RestClientWrapper.get "#{@@uri}/protocol", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
  end

  def test_04d_get_download_pi
    response = OpenTox::RestClientWrapper.get "#{@@uri}", {}, {:accept => "application/zip", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
  end

  def test_05a_no_get_permission
    response = OpenTox::Authorization.authorize "#{@@uri}", "GET", $secondpi[:subjectid]
    assert_equal false, response
  end

  # do not get metadata for user1
  def test_05b_get_metadata_secondpi
    assert_raise OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $secondpi[:subjectid]}
    end
  end

  # do not get protocol for user1
  def test_05c_get_protocol_secondpi
    assert_raise OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/protocol", {}, {:accept => "application/rdf+xml", :subjectid => $secondpi[:subjectid]}
    end
  end

  # do not get download for user1
  def test_05d_get_download_secondpi
    assert_raise OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}", {}, {:accept => "application/zip", :subjectid => $secondpi[:subjectid]}
    end
  end

  # delete investigation/{id}
  # @note expect code 200
  def test_99_a_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => $pi[:subjectid]}
    assert_equal 200, result.code
    #assert result.match(/^Investigation [a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12} deleted$/)
    assert !OpenTox::Authorization.uri_has_policy(@@uri.to_s, $pi[:subjectid])
  end

end