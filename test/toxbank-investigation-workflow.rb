require_relative "toxbank-setup.rb"
require File.join(File.expand_path(File.dirname(__FILE__)),".." ,".." ,"toxbank-investigation", "util.rb")

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TBInvestigationWorkflow < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!
# Permission Matrix for owner, user1 (with GET permission (e.G.: group-permission) and user2 (no permission)
# Sum    = isSummarySearchable=true
# noSum  = isSummarySearchable=false
# Pub    = isPublished = true
# noPub  = isPublished = false
#                      noPub  noSum         noPub  noSum
#                      noSum   Pub  Pub+Sum noSum   Pub  Pub+Sum
#               owner  user1  user1  user1  user2  user2  user2
# GET             y      n      y      y      n      n      n
# POST,PUT,DEL    y      n      n      n      n      n      n
# /metadata       y      n      y      y      n      n      y
# /protocol       y      n      y      y      n      n      y
# Download        y      n      y      y      n      n      n
# Search          ?      n      n      y      n      n      y

  # define different users
  @@owner = $pi[:subjectid]
  @@user1 = $secondpi[:subjectid]
  @@user2 = $guestid

  def setup
    OpenTox::RestClientWrapper.subjectid = @@owner #set owner as the logged in user
  end

  ## Owner keeps all private
  # create a new investigation by uploading a zip file,
  # Summary is not searchable, not published. { access=custom(owner only) in the GUI }
  def test_01_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => @@owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    @@uri = URI(uri)
  end

  # check if @@uri is not in search-index
  def test_02_investigation_not_in_searchindex
    response = OpenTox::RestClientWrapper.get "#{$search_service[:uri]}/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s)}",{},{:subjectid => @@owner}
    assert_equal 200, response.code
    refute_match /#{@@uri}/, response.to_s
  end

  # check for flag "isPublished" is false,
  # @note default behaviour on new investigations
  def test_03_check_published_false
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@owner}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match /false/, r[2].to_s}
  end

  # check for flag "isSummarySearchable" is false,
  # @note default behaviour on new investigations
  def test_03b_check_searchable_false
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@owner}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match /false/, r[2].to_s}
  end

  # check all permissions for owner
  def test_04a_all_permission
    ["GET","POST","PUT","DELETE"].each do |permission|
      response = OpenTox::Authorization.authorize "#{@@uri}", permission, @@owner
      assert_equal true, response
    end
  end

  # get metadata for owner
  def test_04b_get_metadata_pi
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@owner}
    assert_equal 200, response.code
  end

  # get related protocol uris for owner
  def test_04c_get_protocol_pi
    response = OpenTox::RestClientWrapper.get "#{@@uri}/protocol", {}, {:accept => "application/rdf+xml", :subjectid => @@owner}
    assert_equal 200, response.code
  end

  def test_04d_get_download_owner
    response = OpenTox::RestClientWrapper.get "#{@@uri}", {}, {:accept => "application/zip", :subjectid => @@owner}
    assert_equal 200, response.code
  end

  ## now check permissions for user1
  ## expect nothing allowed
  ##################################

  # no get permission for user1
  def test_05a_no_get_permission
    response = OpenTox::Authorization.authorize "#{@@uri}", "GET", @@user1
    assert_equal false, response
  end

  # do not get metadata for user1
  def test_05b_get_metadata
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@user1}
    end
  end

  # do not get protocol for user1
  def test_05c_get_protocol
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/protocol", {}, {:accept => "application/rdf+xml", :subjectid => @@user1}
    end
  end

  # do not get download for user1
  def test_05d_get_download
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}", {}, {:accept => "application/zip", :subjectid => @@user1}
    end
  end

  # no post/put/delete permission for user1
  def test_05e_no_cud_permission
    ["POST", "PUT", "DELETE"].each do |permission|
      response = OpenTox::Authorization.authorize "#{@@uri}", permission, @@user1
      assert_equal false, response
    end
  end
  
  ## now check permissions for user2
  ## expect nothing allowed
  ##################################

  # do not get for user2
  def test_06a_get_permission
    response = OpenTox::Authorization.authorize "#{@@uri}", "GET", @@user2
    assert_equal false, response
  end

  # do not get metadata for user2
  def test_06b_get_metadata
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@user2}
    end
  end

  # do not get protocol for user2
  def test_06c_get_protocol
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/protocol", {}, {:accept => "application/rdf+xml", :subjectid => @@user2}
    end
  end

  # do not get download for user2
  def test_06d_get_download
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}", {}, {:accept => "application/zip", :subjectid => @@user2}
    end
  end

  # no post/put/delete permission for user2
  def test_06e_no_cud_permission
    ["POST", "PUT", "DELETE"].each do |permission|
      response = OpenTox::Authorization.authorize "#{@@uri}", permission, @@user2
      assert_equal false, response
    end
  end

  # give the investigation a tb-group membership access by policy
  ###############################################################

  def test_08_put_group_access
    @@toxbank_uri = `curl -Lk -X GET -H "Accept:text/uri-list" -H "subjectid:#{@@owner}" #{$user_service[:uri]}/project?search=ToxBank`.chomp.sub("\n","")
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :allowReadByGroup => "#{@@toxbank_uri}"},{ :subjectid => @@owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal uri, @@uri.to_s
  end

  # get permission for user1
  def test_08a_get_permission
    response = OpenTox::Authorization.authorize "#{@@uri}", "GET", @@user1
    assert_equal true, response
  end

  # repeat with permissions for toxbank group
  def test_08b_repeat_05bcd
    test_05b_get_metadata
    test_05c_get_protocol
    test_05d_get_download
    test_05e_no_cud_permission
    test_02_investigation_not_in_searchindex
  end

  ## make publish
  ###############

  def test_09_put_published
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :published => "true"},{ :subjectid => @@owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal uri, @@uri.to_s
  end

  ## check changes for user1
  ##########################

  # allowed
  def test_09a_get_user1
    response = OpenTox::RestClientWrapper.get "#{@@uri}", {}, {:accept => "text/uri-list", :subjectid => @@user1}
    assert_equal 200, response.code
  end
  
  # denied
  def test_09b_put_user1
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.put "#{@@uri}", {}, {:published => "true", :subjectid => @@user1}
    end
  end

  # denied
  def test_09c_post_user1
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.post "#{@@uri}", {}, {:published => "true", :subjectid => @@user1}
    end
  end

  # denied
  def test_09d_delete_user1
    assert_raises OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.delete "#{@@uri}", {}, {:subjectid => @@user1}
    end
  end

  # allowed
  # get metadata for user1
  def test_09e_get_metadata_user1
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@user1}
    assert_equal 200, response.code
  end

  # allowed
  # get related protocol uris for user1
  def test_09f_get_protocol_user1
    response = OpenTox::RestClientWrapper.get "#{@@uri}/protocol", {}, {:accept => "application/rdf+xml", :subjectid => @@user1}
    assert_equal 200, response.code
  end
  
  # allowed
  def test_09g_get_download_user1
    response = OpenTox::RestClientWrapper.get "#{@@uri}", {}, {:accept => "application/zip", :subjectid => @@user1}
    assert_equal 200, response.code
  end

  def test_09h_not_indexed
    test_02_investigation_not_in_searchindex
  end

  ## make searchable
  ##################

  def test_10_put_searchable
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :summarySearchable => "true"},{ :subjectid => @@owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal uri, @@uri.to_s
  end

  def test_11a_repeat_user1_tests
    test_09a_get_user1
    test_09b_put_user1
    test_09c_post_user1
    test_09d_delete_user1
    test_09e_get_metadata_user1
    test_09f_get_protocol_user1
    test_09g_get_download_user1
  end

  def test_11b_is_indexed
    response = OpenTox::RestClientWrapper.get "#{$search_service[:uri]}/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s)}",{},{:subjectid => @@owner}
    assert_equal 200, response.code
    assert_match /#{@@uri}/, response.to_s
  end

  def test_12_remove_group_access
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :allowReadByGroup => ""},{ :subjectid => @@owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal uri, @@uri.to_s
  end

  # searchable + published without GET policy
  def test_13a_repeat_05bcd
    test_05a_no_get_permission
    test_05d_get_download
    test_05e_no_cud_permission
    test_11b_is_indexed
  end

  # get metadata for user1
  def test_13c_get_metadata_user1
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@user1 }
    assert_equal 200, response.code
  end

  # get related protocol uris for user1
  def test_13d_get_protocol_user1
    response = OpenTox::RestClientWrapper.get "#{@@uri}/protocol", {}, {:accept => "application/rdf+xml", :subjectid => @@user1 }
    assert_equal 200, response.code
  end

  def test_20_update_modified_time
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@owner }
    g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| g << s}}
    g.query(:predicate => RDF::DC.modified){|r| @modified_time1 = r[2].to_s}
    t_start = Time.parse(@modified_time1).to_i
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :allowReadByGroup => "#{@@toxbank_uri}"},{ :subjectid => @@owner }
    sleep 2
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@owner }
    g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| g << s}}
    g.query(:predicate => RDF::DC.modified){|r| @modified_time2 = r[2].to_s}
    t_end =  Time.parse(@modified_time2).to_i
    assert t_end > t_start, "modified time is not updated"
  end

  # delete investigation/{id}
  # @note expect code 200
  def test_99_a_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => @@owner}
    assert_equal 200, result.code
    #assert result.match(/^Investigation [a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12} deleted$/)
    assert !OpenTox::Authorization.uri_has_policy(@@uri.to_s)
  end
  
  ## check for user1 and user2 with only isSum=true is set
  ## expect no get { GUI option 'make searchable' during first upload }
  ########################################################

  def test_99_b_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :summarySearchable => "true"}, { :subjectid => @@owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    @@uri = URI(uri)
  end

  # check for flag "isSummarySearchable" is true,
  def test_99_c_check_searchable_true
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@owner}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match /true/, r[2].to_s}
  end

  ## expect no get for user1 and user2
  ####################################

  def test_99_d_repeat_tests
    # user1
    test_05a_no_get_permission
    test_05b_get_metadata
    test_05c_get_protocol
    test_05d_get_download
    test_05e_no_cud_permission
    #user2
    test_06a_get_permission
    test_06b_get_metadata
    test_06c_get_protocol
    test_06d_get_download
    test_06e_no_cud_permission
  end
  
  # delete investigation/{id}
  # @note expect code 200
  def test_99_x_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => @@owner}
    assert_equal 200, result.code
    assert !OpenTox::Authorization.uri_has_policy(@@uri.to_s)
  end

end
