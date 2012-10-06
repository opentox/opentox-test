require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
require File.join(File.expand_path(File.dirname(__FILE__)),".." ,".." ,"toxbank-investigation", "util.rb")

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TBInvestigationBasic < Test::Unit::TestCase
  
  # check response from service without header,
  # @todo TODO or wrong header,
  # @note expect OpenTox::BadRequestError
  def test_01_get_investigations_400
    assert_raise OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, :subjectid => $pi[:subjectid]
    end
  end

  # check response from service with header text/uri-list
  # @todo TODO with header text/plain
  # @todo TODO with header text/turtle
  # @todo TODO with header application/rdf+xml
  # @note expect code 200
  def test_02_get_investigations_200
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, { :accept => 'text/uri-list', :subjectid => $pi[:subjectid] }
    assert_equal "text/uri-list", response.headers[:content_type]
  end

end

class TBInvestigationREST < Test::Unit::TestCase

  RDF::TB  = RDF::Vocabulary.new "http://onto.toxbank.net/api/"
  RDF::ISA = RDF::Vocabulary.new "http://onto.toxbank.net/isa/"


  # check if the userservice is available
  # @note return the guest user URI
  def test_00_pre_get_user_from_userservice
    guesturi = OpenTox::RestClientWrapper.get("http://toxbanktest1.opentox.org:8080/toxbank/user?username=guest", nil, {:Accept => "text/uri-list", :subjectid => $pi[:subjectid]}).sub("\n","")
    assert_equal "http://toxbanktest1.opentox.org:8080/toxbank/user/U2", guesturi
  end
  
  # check post to investigation service without file,
  # @note expect OpenTox::BadRequestError
  def test_01a_post_investigation_400_no_file
    assert_raise OpenTox::BadRequestError do
      response =  OpenTox::RestClientWrapper.post $investigation[:uri], {}, { :subjectid => $pi[:subjectid] }
    end
  end
  
  # post with wrong mime type,
  # @note expect OpenTox::BadRequestError
  def test_01b_wrong_mime_type
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "empty.zup"
    assert_raise OpenTox::BadRequestError do
      response =  OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    end
  end

  # post an empty zip,
  # @note expect OpenTox::BadRequestError
  def test_01c_upload_empty_zip
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "empty.zip" 
    assert_raise OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    end
  end

  # create an investigation by uploading a zip file,
  # @todo TODO create by uploading text/tab-separated-values
  # @todo TODO create by uploading application/vnd.ms-excel
  # @note return metadata as application/rdf+xml,
  #   check for title/AccessionID "BII-I-1b"
  def test_02_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b.zip"
    #response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :allowReadByUser => "http://toxbanktest1.opentox.org:8080/toxbank/user/U2,http://toxbanktest1.opentox.org:8080/toxbank/user/U124"}, { :subjectid => $pi[:subjectid] }
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    #puts task_uri
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    #puts uri
    @@uri = URI(uri)
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert @@uri.host == URI($investigation[:uri]).host
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    assert @g.has_predicate?(RDF::ISA.hasAccessionID)
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1b/}
  end

  # check that policy files not listed in uri-list 
  def test_02a_check_policy_file_not_listed
    result = OpenTox::RestClientWrapper.get("#{@@uri}", {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}).split("\n")
    assert result.grep(/user_policies/).size == 0
  end

  # check for flag "isPublished" is false,
  # @note default behaviour on new investigations
  def test_03a_check_published_false
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /false/}
  end

  # update flag "isPublished",
  # @note try to update with other value than "true" and expect flag value "false",
  #   try to update with value "true" and expect flag value "true",
  #   update policy to allow read by group "G2",
  # @todo TODO try to get data without membership to "G2",
  # @todo TODO try to give inexisting group read policy
  def test_03b_put_published
    res = OpenTox::RestClientWrapper.put @@uri.to_s, { :published => "yes"}, { :subjectid => $pi[:subjectid] }
    task_uri = res.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal uri, @@uri.to_s
    result = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(result.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /false/}
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :published => "true", :allowReadByGroup => "http://toxbanktest1.opentox.org:8080/toxbank/project/G2"},{ :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal uri, @@uri.to_s
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /true/}
  end

  # check flag "isSummarySearchable" is false,
  # @note default behaviour on new investigation
  def test_04a_check_summary_searchable_false
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /false/}
  end

  # update flag "isSummarySearchable" to "true",
  # @note try to update with other value than "true" and expect flag value "false",
  #   try to update with value "true" and expect flag value "true",
  def test_04b_put_summary_searchable
    res = OpenTox::RestClientWrapper.put @@uri.to_s, { :summarySearchable => "yes"}, { :subjectid => $pi[:subjectid] }
    task_uri = res.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal uri, @@uri.to_s
    result = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(result.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isSummarySearchabel){|r| assert_match r[2].to_s, /false/}
    response = OpenTox::RestClientWrapper.put @@uri.to_s,{ :summarySearchable => "true" },{ :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal uri, @@uri.to_s
    data = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(data.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /true/}
  end

  # get investigation/{id}/metadata in rdf+xml 
  # @note check nodes and content: title, abstract, 
  #   hasKeyword, hasOwner, isPublished, isSummarySearchable,
  #   hasAccessionID, hasOrganisation
  # @note accept:application/rdf+xml
  def test_05a_check_metadata
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    assert @g.has_predicate?(RDF::DC.title)
    assert @g.has_predicate?(RDF::DC.abstract)
    assert @g.has_predicate?(RDF::TB.hasKeyword)
    assert @g.has_predicate?(RDF::TB.hasOwner)
    assert @g.has_predicate?(RDF::TB.isPublished)
    assert @g.has_predicate?(RDF::TB.isSummarySearchable)
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

  # get metadata 
  # @note accept:text/turtle
  def test_05b
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/turtle", :subjectid => $pi[:subjectid]}
    assert_equal "text/turtle", response.headers[:content_type]
  end

  # get metadata
  # @note accept:text/plain
  def test_05c
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/plain", :subjectid => $pi[:subjectid]}
    assert_match  /^text\/plain/ , response.headers[:content_type]
  end

  # get investigation/{id}
  # @note accept:text/uri-list
  def test_06_get_investigation_uri_list
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    assert_equal "text/uri-list", result.headers[:content_type]
  end

  # get investigation/{id}
  # @note accept:application/zip
  def test_07_get_investigation_zip
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/zip", :subjectid => $pi[:subjectid]}
    assert_equal "application/zip", result.headers[:content_type]
  end

  # get investigation/{id}
  # @note accept:text/tab-separated-values
  def test_08_get_investigation_tab
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "text/tab-separated-values", :subjectid => $pi[:subjectid]}
    assert_equal "text/tab-separated-values;charset=utf-8", result.headers[:content_type]
  end

  # get investigation/{id}
  # @note accept:application/rdf+xml
  def test_09_get_investigation_sparql
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_equal "application/rdf+xml", result.headers[:content_type]
  end

  # update existing investigation with zip
  # @note check flags are "false" and update them to "true"
  # @todo TODO update existing investigation with single files
  def test_10_a_update_investigation
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1.zip"
    response = OpenTox::RestClientWrapper.put @@uri.to_s, {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    assert_equal 202, response.code
    task_uri = response.chomp
    puts "update investigation:#{task_uri}"
    task = OpenTox::Task.new task_uri
    task.wait
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
  end

  # check flags are working after update
  # @note expect flags are set to "false", 
  #   default behaviour after update without
  #   given param on upload.
  # @note expect Guest user can not get metadata,
  #   expect OpenTox::NotAuthorizedError
  def test_10_b_check_flags_after_update
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_match /<\?xml/, response #PI can get
    assert_raise OpenTox::UnauthorizedError do
      res = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    end #Guest can not get
  end

  # update flag isSummarySearchable
  # @note expect Guest user can get metadata after update
  def test_10_c_update_flag_isSearchable
    response = OpenTox::RestClientWrapper.put @@uri.to_s,{ :summarySearchable => "true" },{ :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    puts "update isSS:#{task_uri}"
    task = OpenTox::Task.new task_uri
    task.wait
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_match /<\?xml/, response #PI can get
    res = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /<\?xml/, res #Guest can get if isSS
  end

  # check title has changed by update
  # @note expect title after update is "BII-I-1"
  def test_10_d_check_if_title_has_changed_by_update
    # check content
    res = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(res.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1/}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /false/}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /true/}
  end

  # check investigation data still not reachable as GUEST
  # @note expect OpenTox::NotAuthorizedError
  def test_10_e_check_investigation_data_still_not_reachable_for_guest
    assert_raise OpenTox::UnauthorizedError do
      res = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    end
  end

  # update flag isPublished
  def test_10_f_update_flag_isPublished
    response = OpenTox::RestClientWrapper.put @@uri.to_s, {:published => "true"},{:subjectid => $pi[:subjectid]}
    task_uri = response.chomp
    puts "isPublished:#{task_uri}"
    task = OpenTox::Task.new task_uri
    task.wait
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    # check owner can get
    res = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_match /<\?xml/, res
  end

  # @note expect data is still not reachable without policy
  def test_10_g_guest_can_not_get
    assert_raise OpenTox::UnauthorizedError do
      res = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    end
  end

  # update policy 
  def test_10_h_update_guest_policy
    response = OpenTox::RestClientWrapper.put @@uri.to_s, {:allowReadByUser => "http://toxbanktest1.opentox.org:8080/toxbank/user/U2"},{:subjectid => $pi[:subjectid]}
    task_uri = response.chomp
    puts "update Policy: #{task_uri}"
    task = OpenTox::Task.new task_uri
    task.wait
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
  end

  # @note data is available with policy
  def test_10_i_guest_can_get
    res = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => @@subjectid}
    assert_match /<\?xml/, res
  end

  # get investigation/{id}/metadata in rdf and check content
  # @see test_05a_check_metadata
  # @note expect same content as in test_05a_check_metadata,
  #   but title has changed
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

  # check the investigation owner's policy
  def test_30_check_owner_policy
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "POST", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "PUT", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "DELETE", $pi[:subjectid])
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "GET", $pi[:subjectid])
    # check for guest policy
    assert_equal true, OpenTox::Authorization.authorize(@@uri.to_s, "GET", @@subjectid)
  end

  # check how many policies,
  # @note expect two policies,
  #   one for owner, one for group
  def test_31_check_policies
    assert_equal Array, OpenTox::Authorization.list_uri_policies(@@uri.to_s, $pi[:subjectid]).class
    assert_equal 3, OpenTox::Authorization.list_uri_policies(@@uri.to_s, $pi[:subjectid]).size
  end

  # check if the UI index responses with 200
  def test_40_check_ui_index
    #puts @@uri.to_s
    response = request_ssl3 "https://www.leadscope.com/dev-toxbank-search/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s)}", "get", $pi[:subjectid]
    assert_match "200", response.code
=begin
    response = OpenTox::RestClientWrapper.put "https://www.leadscope.com/dev-toxbank-search/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s + $pi[:subjectid])}",{},{}
    puts response.to_s
    assert_equal 200, response.code
    n=0
    begin
      response = OpenTox::RestClientWrapper.get "https://www.leadscope.com/dev-toxbank-search/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s + $pi[:subjectid])}",{},{:subjectid => $pi[:subjectid]}
      n+=1
      sleep 1
    end while response.to_s != @@uri.to_s && n < 10
    puts response.to_s
    assert_equal 200, response.code
    #assert_equal @@uri.to_s, response.to_s
    response = OpenTox::RestClientWrapper.delete "https://www.leadscope.com/dev-toxbank-search/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s) + $pi[:subjectid]}",{},{:subjectid => $pi[:subjectid]}
    puts response.to_s
    assert_equal 200, response.code
=end
  end

  # check if @@uri is indexed
  def test_41_investigation_in_index
    #OpenTox::RestClientWrapper.put "https://www.leadscope.com/dev-toxbank-search/search/index/investigation?resourceUri=#{CGI.escape(investigation_uri)}",{},{:subjectid => @subjectid}
  end

  # try to delete investigation as "guest",
  # @note expect OpenTox::UnauthorizedError
  def test_90_try_to_delete_id_as_guest
    assert_raise OpenTox::UnauthorizedError do
      OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => @@subjectid}
    end
  end

  # try to delete single file of investigation as "guest",
  # @note expect OpenTox::UnauthorizedError
  def test_91_try_to_delete_id_file_as_guest
    # TODO insert pat to single file
    assert_raise OpenTox::UnauthorizedError do
      OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => @@subjectid}
    end
  end

  # try to update an investigation as "guest",
  # @note expect OpenTox::UnauthorizedError
  def test_92_try_to_update_id_as_guest
    assert_raise OpenTox::UnauthorizedError do
      OpenTox::RestClientWrapper.put @@uri.to_s, {:published => "true"},{:subjectid => @@subjectid}
    end
  end
  
  # check if uri is in uri-list
  # @note expect investigation uri exist
  def test_98_get_investigation
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    assert response.index(@@uri.to_s) != nil, "URI: #{@@uri} is not in uri-list"
  end

  # delete investigation/{id}
  # @note expect code 200
  def test_99_a_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => $pi[:subjectid]}
    assert_equal 200, result.code
    #assert result.match(/^Investigation [a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12} deleted$/)
    assert !OpenTox::Authorization.uri_has_policy(@@uri.to_s, $pi[:subjectid])
  end

  # check that deleted uri is no longer in uri-list
  # @note expect investigation uri not in uri-list
  def test_99_b_check_urilist
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    assert_no_match /#{@@uri.to_s}/, response
  end

end


