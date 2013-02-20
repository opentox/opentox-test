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
  # @note expect OpenTox::BadRequestError
  def test_01_get_investigations_400
    assert_raise OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, { :subjectid => $pi[:subjectid] }
    end
  end

  # give wrong header
  # @note expect OpenTox::BadRequestError
  def test_01_b_wrong_header
    assert_raise OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get $investigation[:uri], {:accept => "text/text"}, { :subjectid => $pi[:subjectid] }
    end
  end

  # check response from service with header text/uri-list, application/rdf+xml
  # @note expect code 200
  def test_02_get_investigations_200
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, { :accept => 'text/uri-list', :subjectid => $pi[:subjectid] }
    assert_equal "text/uri-list", response.headers[:content_type]
    assert_equal 200, response.code
  end

  def test_02b_get_investigations_200
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, { :accept => 'application/rdf+xml', :subjectid => $pi[:subjectid] }
    assert_equal "application/rdf+xml", response.headers[:content_type]
    assert_equal 200, response.code
  end

  # check header from service without accept + subjectid
  # @note expect 200
  def test_03_get_service_header
    response = OpenTox::RestClientWrapper.head($investigation[:uri])
    assert_equal 200, response.code
  end

end

class TBInvestigationREST < Test::Unit::TestCase

  RDF::TB  = RDF::Vocabulary.new "http://onto.toxbank.net/api/"
  RDF::ISA = RDF::Vocabulary.new "http://onto.toxbank.net/isa/"


  # check if the userservice is available
  # @note return the secondpi user URI
  def test_00_pre_get_user_from_userservice
    #guesturi = OpenTox::RestClientWrapper.get("#{$user_service[:uri]}/user?username=guest", nil, {:Accept => "text/uri-list", :subjectid => $pi[:subjectid]}).sub("\n","")
    pi2uri = `curl -Lk -X GET -H "Accept:text/uri-list" -H "subjectid:#{$pi[:subjectid]}" #{$user_service[:uri]}/user?username=#{$secondpi[:name]}`.chomp.sub("\n","")
    assert_equal "#{$secondpi[:uri]}", pi2uri
  end
  
  # check post to investigation service without file,
  # @note expect OpenTox::BadRequestError
  def test_01a_post_investigation_400_no_file
    response =  OpenTox::RestClientWrapper.post $investigation[:uri], {}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    puts "\nno file: #{task.uri} \n"
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
  end
  
  # post with wrong mime type,
  # @note expect OpenTox::BadRequestError
  def test_01b_wrong_mime_type
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "empty.zup"
    response =  OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    puts "wrong mime: #{task.uri} \n"
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
  end

  # post an empty zip,
  # @note expect OpenTox::BadRequestError
  def test_01c_upload_empty_zip
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "empty.zip" 
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    puts "empty file: #{task.uri} \n"
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
  end

  # create an investigation by uploading a zip file,
  # @todo TODO create by uploading text/tab-separated-values
  # @todo TODO create by uploading application/vnd.ms-excel
  # @note return metadata as application/rdf+xml,
  #   check for title/AccessionID "BII-I-1b"
  def test_02_post_investigation
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b-tb2.zip"
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

  # check for uri-list as text/uri-list
  # @note returns all listet investigations in service
  def test_02b_check_for_text_uri_list
    result = OpenTox::RestClientWrapper.get("#{$investigation[:uri]}", {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}).split("\n")
    assert_match /#{@@uri}/, result.to_s
  end

  # check for uri-list as application/rdf+xml
  # @note returns list of user investigations as rdf+xml
  def test_02c_check_for_rdf_uri_list
    result = OpenTox::RestClientWrapper.get("#{$investigation[:uri]}", {}, {:user => "#{$pi[:uri]}", :accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}).split("\n")
    assert_match /#{@@uri}/, result.to_s
  end

  # check for uri-list of a given user as application/json
  # @note returns list of users investigations as json
  def test_02d_check_for_users_investigations
    result = OpenTox::RestClientWrapper.get("#{$investigation[:uri]}", {}, {:user => "#{$pi[:uri]}", :accept => "application/json", :subjectid => $pi[:subjectid]})
    #puts result
    assert_match /#{@@uri}/, result
    assert_match /(\d{10})/, result # quickcheck for timestamp
  end

  # check for uri-list of an inexisting user
  # @note returns nothing if inexisting user
  def test_02e_check_with_inexisting_user
    result = OpenTox::RestClientWrapper.get("#{$investigation[:uri]}", {}, {:user => "#{$user_service[:uri]}/user/U01", :accept => "application/json", :subjectid => $pi[:subjectid]})
    assert_not_match /#{@@uri}/, result.to_s
  end

  # check for uri-list of a secondpi user
  # @note returns nothing because there are no investigations of this user
  def test_02f_check_for_pi2user_uris
    result = OpenTox::RestClientWrapper.get("#{$investigation[:uri]}", {}, {:user => "#{$secondpi[:uri]}", :accept => "application/json", :subjectid => $secondpi[:subjectid]})
    assert_not_match /#{@@uri}/, result.to_s
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
    response = OpenTox::RestClientWrapper.put @@uri.to_s, { :published => "true", :allowReadByGroup => "#{$user_service[:uri]}/project/G2"},{ :subjectid => $pi[:subjectid] }
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
    assert @g.has_predicate?(RDF::DC.modified)
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
    @g.query(:predicate => RDF::DC.modified){|r| @@modified_time = r[2].to_s}
  end

  # get related protocol uris
  # @note returns related protocol uri of a study
  def test_05_b
    response = OpenTox::RestClientWrapper.get "#{@@uri}/protocol", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_match /SEURAT\-Protocol\-245\-1/, response.to_s
  end
  
  # get metadata 
  # @note accept:text/turtle
  def test_05c
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/turtle", :subjectid => $pi[:subjectid]}
    assert_equal "text/turtle", response.headers[:content_type]
  end

  # get metadata
  # @note accept:text/plain
  def test_05d
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "text/plain", :subjectid => $pi[:subjectid]}
    assert_match  /^text\/plain/ , response.headers[:content_type]
  end

  # get a resource as owner
  # @note expect result 
  def test_05e
    metadata = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    @g = RDF::Graph.new
    @@resource = ""
    RDF::Reader.for(:rdfxml).new(metadata.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::ISA.hasStudy){|r| @@resource = r[2].to_s.split("/").last}
    response = OpenTox::RestClientWrapper.get "#{@@uri}/#{@@resource}", {}, {:accept => "text/plain", :subjectid => $pi[:subjectid]}
    puts "\nresource: #{@@resource}"
    assert_match  /Comprehensive high-throughput analyses at the levels of mRNAs|hasProtocol|hasAssay/, response
  end

  # get a resource as guest
  # @note expect no result until investigation is published
  def test_05f
    assert_raise OpenTox::UnauthorizedError do
      response = OpenTox::RestClientWrapper.get "#{@@uri}/#{@@resource}", {}, {:accept => "text/plain", :subjectid => @@subjectid}
    end
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
  def test_09_get_investigation_check_accept_headers
    result = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_equal "application/rdf+xml", result.headers[:content_type]
  end

  # update existing investigation with zip
  # @note check flags are "false" and update them to "true"
  # @todo TODO update existing investigation with single files
  def test_10_a_update_investigation
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2.zip"
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
  # @note expect secondpi user can get metadata after update
  def test_10_c_update_flag_isSearchable
    response = OpenTox::RestClientWrapper.put @@uri.to_s,{ :summarySearchable => "true" },{ :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    puts "update isSS:#{task_uri}"
    task = OpenTox::Task.new task_uri
    task.wait
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    response = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_match /<\?xml/, response #PI can get
    res = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $secondpi[:subjectid]}
    assert_match /<\?xml/, res #secondpi can get if isSS
  end

  # check title has changed by update
  # @note expect title after update is "BII-I-1"
  def test_10_d_check_if_title_has_changed_by_update
    # check content
    res = OpenTox::RestClientWrapper.get "#{@@uri}/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $secondpi[:subjectid]}
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(res.to_s){|r| r.each{|s| @g << s}}
    @g.query(:predicate => RDF::ISA.hasAccessionID){|r| assert_match r[2].to_s, /BII-I-1/}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match r[2].to_s, /false/}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match r[2].to_s, /true/}
  end

  # check investigation data still not reachable as secondpi
  # @note expect OpenTox::NotAuthorizedError
  def test_10_e_check_investigation_data_still_not_reachable_for_pi2
    assert_raise OpenTox::UnauthorizedError do
      res = OpenTox::RestClientWrapper.get @@uri.to_s, {}, {:accept => "application/rdf+xml", :subjectid => $secondpi[:subjectid]}
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
    response = OpenTox::RestClientWrapper.put @@uri.to_s, {:allowReadByUser => "#{$user_service[:uri]}/user/U2"},{:subjectid => $pi[:subjectid]}
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
    @g.query(:predicate => RDF::DC.modified){|r| assert r[2] > @@modified_time.to_s; puts "\nfirst mod: #{@@modified_time} \nsecond mod: #{r[2]}"}
  end

  # upload a investigation as secondpi
  # @note expect only secondpi uris in uri-list
  def test_20_a_post_data
    uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $secondpi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    u = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    uri = URI(u)
    puts "secondpi-> uri: #{uri}"
    puts "pi-> uri: #{@@uri}"
    # pi get uris of secondpi
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, {:user => "#{$user_service[:uri]}/user/U479", :accept => "application/json", :subjectid => $pi[:subjectid]}
    assert_not_match /#{@@uri}/, response
    assert_match /#{uri}/, response
    result = OpenTox::RestClientWrapper.delete uri.to_s, {}, {:subjectid => $secondpi[:subjectid]}
    assert_equal 200, result.code
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
    response = OpenTox::RestClientWrapper.get "#{$search_service[:uri]}/search/index",{},{:subjectid => $pi[:subjectid]}
    #response = request_ssl3 "#{$search_service[:uri]}/search/index", "get", $pi[:subjectid]
    puts response.inspect
    assert_equal 200, response.code
    #response = request_ssl3 "#{$search_service[:uri]}/search/index?resourceUri=#{CGI.escape(@@uri.to_s)}", "put" ,$pi[:subjectid]
    #assert_equal "200", response.code
    n=0
    begin
      #@response = request_ssl3 "#{$search_service[:uri]}/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s)}", "get", $pi[:subjectid]
      @response = OpenTox::RestClientWrapper.get "#{$search_service[:uri]}/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s)}",{},{:subjectid => $pi[:subjectid]}
      n+=1
      puts "\nget uri from index:#{@response.body}"
      sleep 1
    end while @response.body != @@uri.to_s && n < 10
    assert_equal 200, response.code
    assert_equal @@uri.to_s, @response.body
    #response = request_ssl3 "https://toxbanktest2.toxbank.net/toxbank-search/search/index?#{CGI.escape(@@uri.to_s)}", "delete", $pi[:subjectid]
    #assert_equal "200", response.code
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
    # TODO insert path to single file
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

  # check if @@uri is indexed
  def test_99_b_investigation_not_in_index
    #response = request_ssl3 "#{$search_service[:uri]}/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s)}", "get", $pi[:subjectid]
    response = OpenTox::RestClientWrapper.get "#{$search_service[:uri]}/search/index/investigation?resourceUri=#{CGI.escape(@@uri.to_s)}",{},{:subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
    assert_no_match /#{@@uri}/, response.to_s
  end

  # check that deleted uri is no longer in uri-list
  # @note expect investigation uri not in uri-list
  def test_99_c_check_urilist
    response = OpenTox::RestClientWrapper.get $investigation[:uri], {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid]}
    assert_no_match /#{@@uri}/, response.to_s
  end

end

