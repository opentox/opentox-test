require_relative "toxbank-setup.rb"
require File.join(File.expand_path(File.dirname(__FILE__)),".." ,".." ,"toxbank-investigation", "util.rb")

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TBInvestigationNoISADataInvalidPOST < MiniTest::Test
  
  # no file no params
  # @note expect OpenTox::BadRequestError
  def test_nofile_nodata
    puts "\nno data no params"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_match "No file uploaded or parameters given.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."

  end

  ## test types
  # attached file but missing type
  # @note expect OpenTox::BadRequestError
  def test_attached_file_missing_type  
    puts "\nattached file but missing type"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81, #{$user_service[:uri]}/project/G79", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727" }, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_match "Could not parse isatab file in 'unformated.zip'.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # type noData but ftp file in params
  # @note expect OpenTox::BadRequestError
  def test_noData
    puts "\ntype noData but ftp file in params"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:type => "noData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727", :ftpFile => "JIC37_Ethanol_0.07_Internal_1_3.txt"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "Parameter 'ftpData' not expected for type 'noData'.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # attached file but type is noData
  # @note expect OpenTox::BadRequestError
  def test_wrong_type_noData
    puts "\nattached file but type is noData"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "noData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "No file expected for type 'noData'.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # attached file but type is ftpData
  # @note expect OpenTox::BadRequestError
  def test_wrong_type_ftpData
    puts "\nattached file but type is ftpData"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "ftpData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "No file expected for type 'ftpData'.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # unknown inv type
  # @note expect OpenTox::BadRequestError
  def test_unknown_inv_type
    puts "\nunknown inv type"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], { :type => "Data", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :owningPro => "#{$user_service}/project/G81", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "Investigation type 'Data' not supported.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # attached file unknown inv type
  # @note expect OpenTox::BadRequestError
  def test_file_unknown_inv_type
    puts "\nattached file unknown inv type"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], { :file => File.open(file), :type => "Data", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "Investigation type 'Data' not supported.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  ## test parameters
  # missing title
  # @note expect OpenTox::BadRequestError
  def test_attached_file_missing_title  
    puts "\nattached file missing title"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727" }, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_match "Parameter 'title' is required.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # missing abstract
  # @note expect OpenTox::BadRequestError
  def test_attached_file_missing_abstract  
    puts "\nattached file missing abstract"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727" }, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_match "Parameter 'abstract' is required.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end

  # missing owningOrg
  # @note expect OpenTox::BadRequestError
  def test_attached_file_missing_owningOrg
    puts "\nattached file missing owningOrg"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727" }, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "Parameter 'owningOrg' is required.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # missing owningPro
  # @note expect OpenTox::BadRequestError
  def test_attached_file_missing_owningPro
    puts "\nattached file missing owningPro"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727" }, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "Parameter 'owningPro' is required.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # missing authors
  # @note expect OpenTox::BadRequestError
  def test_attached_file_missing_authors
    puts "\nattached file missing authors"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727" }, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "Parameter 'authors' is required.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # missing keywords
  # @note expect OpenTox::BadRequestError
  def test_attached_file_missing_keywords
    puts "\nattached file missing keywords"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479" }, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "Parameter 'keywords' is required.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end


  ## test mime type
  # attached file wrong mime type
  # @note expect OpenTox::BadRequestError
  def test_wrong_mime
    puts "\nattached file wrong mime"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "empty.zup"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "noData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "Mime type text/plain not supported. Please submit data as zip archive (application/zip).", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end

  # test file size

  # unformated data larger 10MB
  # @note expect OpenTox::BadRequestError
  def test_file_larger_10mb
    puts "\nunformated data larger 10MB"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/invalid", "unformated10mb.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "File 'unformated10mb.zip' is to large. Please choose FTP investigation type and upload to your FTP directory first.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end
  
  # invalid param URI
  # @note expect OpenTox::BadRequestError
  def test_invalid_param_uri
    puts "\ninvalid param URI"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/oxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task_uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_equal "'http://www.owl-ontologies.com/oxbank.owl/K727' is not a valid URI.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
  end

end

class TBInvestigationNoISADataValidPOST < MiniTest::Test

  def test_01_post_type_nodata
    puts "\nvalid noData"
    response =  OpenTox::RestClientWrapper.post $investigation[:uri], {:type => "noData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    
    # GET metadata
    response = OpenTox::RestClientWrapper.get uri.to_s+"/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid] }
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    #@g.each{|g| puts g.object}
    @g.query(:predicate => RDF::TB.hasInvType){|r| assert_match /noData/, r[2].to_s}
    @g.query(:predicate => RDF::DC.modified){|r| assert_equal uri.to_s, r[0].to_s}
    expected_owner = ["#{$user_service[:uri]}/user/U271"]
    owner = @g.query(:predicate => RDF::TB.hasOwner).collect{|r| r[2].to_s}
    assert_equal owner, expected_owner
    expected_authors = ["#{$user_service[:uri]}/user/U271", "#{$user_service[:uri]}/user/U479"]
    authors = @g.query(:predicate => RDF::TB.hasAuthor).collect{|r| r[2].to_s}
    assert_equal authors, expected_authors
    expected_keywords = ["http://www.owl-ontologies.com/toxbank.owl/K124", "http://www.owl-ontologies.com/toxbank.owl/K727"]
    keywords = @g.query(:predicate => RDF::TB.hasKeyword).collect{|r| r[2].to_s}
    assert_equal keywords, expected_keywords
    orgs = ["#{$user_service[:uri]}/organisation/G16"]
    expected_orgs = @g.query(:predicate => RDF::TB.hasOrganisation).collect{|r| r[2].to_s}
    assert_equal orgs, expected_orgs
    @g.query(:predicate => RDF::TB.hasProject){|r| assert_match "#{$user_service[:uri]}/project/G81", r[2].to_s}
    @g.query(:predicate => RDF::DC.title){|r| assert_match /New Title/, r[2].to_s}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match /This is a short description/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match /false/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match /false/, r[2].to_s}
    
    # PUT
    response =  OpenTox::RestClientWrapper.put uri, {:type => "noData", :title => "Second Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    
    # GET metadata
    response = OpenTox::RestClientWrapper.get uri.to_s+"/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    #@g.each{|g| puts g.object}
    @g.query(:predicate => RDF::TB.hasInvType){|r| assert_match /noData/, r[2].to_s}
    @g.query(:predicate => RDF::DC.modified){|r| assert_equal uri.to_s, r[0].to_s}
    expected_owner = ["#{$user_service[:uri]}/user/U271"]
    owner = @g.query(:predicate => RDF::TB.hasOwner).collect{|r| r[2].to_s}
    assert_equal owner, expected_owner
    expected_authors = ["#{$user_service[:uri]}/user/U271", "#{$user_service[:uri]}/user/U479"]
    authors = @g.query(:predicate => RDF::TB.hasAuthor).collect{|r| r[2].to_s}
    assert_equal authors, expected_authors
    expected_keywords = ["http://www.owl-ontologies.com/toxbank.owl/K124", "http://www.owl-ontologies.com/toxbank.owl/K727"]
    keywords = @g.query(:predicate => RDF::TB.hasKeyword).collect{|r| r[2].to_s}
    assert_equal keywords, expected_keywords
    orgs = ["#{$user_service[:uri]}/organisation/G16"]
    expected_orgs = @g.query(:predicate => RDF::TB.hasOrganisation).collect{|r| r[2].to_s}
    assert_equal orgs, expected_orgs
    @g.query(:predicate => RDF::DC.title){|r| assert_match /Second Title/, r[2].to_s}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match /This is a short description/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match /false/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match /false/, r[2].to_s}
    
    # DELETE
    response =  OpenTox::RestClientWrapper.delete uri.to_s, {}, { :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
  end

  def test_02_post_type_ftpdata
    puts "\nvalid ftpData"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:type => "ftpData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727", :ftpFile => "subdir/JIC37_Ethanol_0.07_Internal_1_3.txt,JIC37_Ethanol_0.07_Internal_1_3.txt"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    
    # GET metadata
    response = OpenTox::RestClientWrapper.get uri.to_s+"/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    #@g.each{|g| puts g.object}
    @g.query(:predicate => RDF::TB.hasInvType){|r| assert_match /ftpData/, r[2].to_s}
    @g.query(:predicate => RDF::DC.modified){|r| assert_equal uri.to_s, r[0].to_s}
    expected_owner = ["#{$user_service[:uri]}/user/U271"]
    owner = @g.query(:predicate => RDF::TB.hasOwner).collect{|r| r[2].to_s}
    assert_equal owner, expected_owner
    expected_authors = ["#{$user_service[:uri]}/user/U271", "#{$user_service[:uri]}/user/U479"]
    authors = @g.query(:predicate => RDF::TB.hasAuthor).collect{|r| r[2].to_s}
    assert_equal authors, expected_authors
    expected_keywords = ["http://www.owl-ontologies.com/toxbank.owl/K124", "http://www.owl-ontologies.com/toxbank.owl/K727"]
    keywords = @g.query(:predicate => RDF::TB.hasKeyword).collect{|r| r[2].to_s}
    assert_equal keywords, expected_keywords
    orgs = ["#{$user_service[:uri]}/organisation/G16"]
    expected_orgs = @g.query(:predicate => RDF::TB.hasOrganisation).collect{|r| r[2].to_s}
    assert_equal orgs, expected_orgs
    @g.query(:predicate => RDF::DC.title){|r| assert_match /New Title/, r[2].to_s}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match /This is a short description/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match /false/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match /false/, r[2].to_s}
    
    # GET file in uri-list
    response = OpenTox::RestClientWrapper.get uri.to_s, {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid] }
    assert_match /JIC37_Ethanol_0.07_Internal_1_3.txt/, response.to_s
    assert_match /subdir_JIC37_Ethanol_0.07_Internal_1_3.txt/, response.to_s
    
    # GET file
    response = OpenTox::RestClientWrapper.get uri.to_s+"/files/JIC37_Ethanol_0.07_Internal_1_3.txt", {}, { :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
    assert_match /isttest/, response.to_s
    
    response = OpenTox::RestClientWrapper.get uri.to_s+"/files/subdir_JIC37_Ethanol_0.07_Internal_1_3.txt", {}, { :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
    assert_match /isttest subdir/, response.to_s

    # PUT
    response =  OpenTox::RestClientWrapper.put uri, {:type => "ftpData", :title => "Second Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :owningPro => "#{$user_service[:uri]}/project/G81", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727", :ftpFile => "JIC37_Ethanol_0.07_Internal_1_3.txt"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."

    # GET metadata
    response = OpenTox::RestClientWrapper.get uri.to_s+"/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    #@g.each{|g| puts g.object}
    @g.query(:predicate => RDF::TB.hasInvType){|r| assert_match /ftpData/, r[2].to_s}
    @g.query(:predicate => RDF::DC.modified){|r| assert_equal uri.to_s, r[0].to_s}
    expected_owner = ["#{$user_service[:uri]}/user/U271"]
    owner = @g.query(:predicate => RDF::TB.hasOwner).collect{|r| r[2].to_s}
    assert_equal owner, expected_owner
    expected_authors = ["#{$user_service[:uri]}/user/U271", "#{$user_service[:uri]}/user/U479"]
    authors = @g.query(:predicate => RDF::TB.hasAuthor).collect{|r| r[2].to_s}
    assert_equal authors, expected_authors
    expected_keywords = ["http://www.owl-ontologies.com/toxbank.owl/K124", "http://www.owl-ontologies.com/toxbank.owl/K727"]
    keywords = @g.query(:predicate => RDF::TB.hasKeyword).collect{|r| r[2].to_s}
    assert_equal keywords, expected_keywords
    orgs = ["#{$user_service[:uri]}/organisation/G16"]
    expected_orgs = @g.query(:predicate => RDF::TB.hasOrganisation).collect{|r| r[2].to_s}
    assert_equal orgs, expected_orgs
    @g.query(:predicate => RDF::DC.title){|r| assert_match /Second Title/, r[2].to_s}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match /This is a short description/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match /false/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match /false/, r[2].to_s}

    # DELETE
    response =  OpenTox::RestClientWrapper.delete uri.to_s, {}, { :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
  end

  def test_03_post_type_unformattedData
    puts "\nvalid unformattedData"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    
    # GET metadata
    response = OpenTox::RestClientWrapper.get uri.to_s+"/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    #@g.each{|g| puts g.object}
    @g.query(:predicate => RDF::TB.hasInvType){|r| assert_match /unformattedData/, r[2].to_s}
    @g.query(:predicate => RDF::DC.modified){|r| assert_equal uri.to_s, r[0].to_s}
    expected_owner = ["#{$user_service[:uri]}/user/U271"]
    owner = @g.query(:predicate => RDF::TB.hasOwner).collect{|r| r[2].to_s}
    assert_equal owner, expected_owner
    expected_authors = ["#{$user_service[:uri]}/user/U271", "#{$user_service[:uri]}/user/U479"]
    authors = @g.query(:predicate => RDF::TB.hasAuthor).collect{|r| r[2].to_s}
    assert_equal authors, expected_authors
    expected_keywords = ["http://www.owl-ontologies.com/toxbank.owl/K124", "http://www.owl-ontologies.com/toxbank.owl/K727"]
    keywords = @g.query(:predicate => RDF::TB.hasKeyword).collect{|r| r[2].to_s}
    assert_equal keywords, expected_keywords
    orgs = ["#{$user_service[:uri]}/organisation/G16"]
    expected_orgs = @g.query(:predicate => RDF::TB.hasOrganisation).collect{|r| r[2].to_s}
    assert_equal orgs, expected_orgs
    @g.query(:predicate => RDF::DC.title){|r| assert_match /New Title/, r[2].to_s}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match /This is a short description/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match /false/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match /false/, r[2].to_s}
    
    # GET file by uri-list
    response = OpenTox::RestClientWrapper.get uri.to_s, {}, {:accept => "text/uri-list", :subjectid => $pi[:subjectid] }
    assert_match /files\/unformated\.zip/, response.to_s
    
    # PUT
    response =  OpenTox::RestClientWrapper.put uri, {:file => File.open(file), :type => "unformattedData", :title => "Second Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."

    # GET metadata
    response = OpenTox::RestClientWrapper.get uri.to_s+"/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    #@g.each{|g| puts g.object}
    @g.query(:predicate => RDF::TB.hasInvType){|r| assert_match /unformattedData/, r[2].to_s}
    @g.query(:predicate => RDF::DC.modified){|r| assert_equal uri.to_s, r[0].to_s}
    expected_owner = ["#{$user_service[:uri]}/user/U271"]
    owner = @g.query(:predicate => RDF::TB.hasOwner).collect{|r| r[2].to_s}
    assert_equal owner, expected_owner
    expected_authors = ["#{$user_service[:uri]}/user/U271", "#{$user_service[:uri]}/user/U479"]
    authors = @g.query(:predicate => RDF::TB.hasAuthor).collect{|r| r[2].to_s}
    assert_equal authors, expected_authors
    expected_keywords = ["http://www.owl-ontologies.com/toxbank.owl/K124", "http://www.owl-ontologies.com/toxbank.owl/K727"]
    keywords = @g.query(:predicate => RDF::TB.hasKeyword).collect{|r| r[2].to_s}
    assert_equal keywords, expected_keywords
    orgs = ["#{$user_service[:uri]}/organisation/G16"]
    expected_orgs = @g.query(:predicate => RDF::TB.hasOrganisation).collect{|r| r[2].to_s}
    assert_equal orgs, expected_orgs
    @g.query(:predicate => RDF::DC.title){|r| assert_match /Second Title/, r[2].to_s}
    @g.query(:predicate => RDF::DC.abstract){|r| assert_match /This is a short description/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isSummarySearchable){|r| assert_match /false/, r[2].to_s}
    @g.query(:predicate => RDF::TB.isPublished){|r| assert_match /false/, r[2].to_s}
    
    # DELETE
    response =  OpenTox::RestClientWrapper.delete uri.to_s, {}, { :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
  end
  
  def test_post_type_unformattedData_whitespace
    puts "\nvalid unformattedData whitespace"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "un formated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    
    # GET metadata
    response = OpenTox::RestClientWrapper.get uri.to_s+"/metadata", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
    @g = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(response.to_s){|r| r.each{|s| @g << s}}
    #@g.each{|g| puts g.object}
    @g.query(:predicate => RDF::TB.hasInvType){|r| assert_match /unformattedData/, r[2].to_s}
    @g.query(:predicate => RDF::TB.hasDownload){|r| assert_match /#{uri}\/files\/un%20formated\.zip/, r[2].to_s}
    
    # DELETE
    response =  OpenTox::RestClientWrapper.delete uri.to_s, {}, { :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
  end

  def test_post_type_nodata_put_error
    puts "\nvalid noData"
    response =  OpenTox::RestClientWrapper.post $investigation[:uri], {:type => "noData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    @uri = uri
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    
    # PUT missing type
    puts "\nPUT missing type expect error"
    response =  OpenTox::RestClientWrapper.put @uri.to_s, { :title => "Second Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :owningPro => "#{$user_service[:uri]}/project/G81", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_match "No file uploaded or any valid parameter given.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
    # PUT missing title
    response =  OpenTox::RestClientWrapper.put @uri.to_s, { :type => "noData", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :owningPro => "#{$user_service[:uri]}/project/G81", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_match "Parameter 'title' is required.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."


    # DELETE
    response =  OpenTox::RestClientWrapper.delete uri.to_s, {}, { :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
  end

end

class TBInvestigationNoISADataValidPOSTchangeType < MiniTest::Test
  
  def test_change_type
    puts "\ntype noData"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "unformated.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:type => "noData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :owningPro => "#{$user_service[:uri]}/project/G81", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    # check files
    response = OpenTox::RestClientWrapper.get(uri, {}, { :accept=>"text/uri-list", :subjectid => $pi[:subjectid] }).chomp
    assert_equal uri+"/files/"+uri.split("/").last+".nt", response, "uri-list should be equal to #{uri.split("/").last} but is #{response}"
    
    puts "\ntype ftpData"
    response = OpenTox::RestClientWrapper.put uri, {:type => "ftpData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :owningPro => "#{$user_service[:uri]}/project/G81", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727", :ftpFile => "JIC37_Ethanol_0.07_Internal_1_3.txt, JIC37_Ethanol_0.07_Internal_1_4.txt"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    response = OpenTox::RestClientWrapper.get($investigation[:uri], {}, { :accept=>"text/uri-list", :subjectid => $pi[:subjectid] }).split("\n").size
    # check files#TODO check Backend output
    response = OpenTox::RestClientWrapper.get(uri, {}, { :accept=>"text/uri-list", :subjectid => $pi[:subjectid] }).chomp
    assert_match uri+"/files/"+uri.split("/").last+".nt", response, "uri-list should match #{uri+"/files/"+uri.split("/").last+".nt"} but is #{response}"
    assert_match uri+"/files/"+"JIC37_Ethanol_0.07_Internal_1_3.txt", response, "uri-list should match #{uri+"/files/"+"JIC37_Ethanol_0.07_Internal_1_3.txt"} but is #{response}"
    assert_match uri+"/files/"+"JIC37_Ethanol_0.07_Internal_1_4.txt", response, "uri-list should match #{uri+"/files/"+"JIC37_Ethanol_0.07_Internal_1_4.txt"} but is #{response}"
    
    puts "\ntype unformattedData"
    response = OpenTox::RestClientWrapper.put uri, {:file => File.open(file), :type => "unformattedData", :title => "New Title", :abstract => "This is a short description", :owningOrg => "#{$user_service[:uri]}/organisation/G16", :authors => "#{$user_service[:uri]}/user/U271, #{$user_service[:uri]}/user/U479", :owningPro => "#{$user_service[:uri]}/project/G81", :keywords => "http://www.owl-ontologies.com/toxbank.owl/K124, http://www.owl-ontologies.com/toxbank.owl/K727"}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    # check files
    response = OpenTox::RestClientWrapper.get(uri, {}, { :accept=>"text/uri-list", :subjectid => $pi[:subjectid] }).chomp
    assert_match uri+"/files/"+uri.split("/").last+".nt", response, "uri-list should match #{uri+"/files/"+uri.split("/").last+".nt"} but is #{response}"
    assert_match uri+"/files/"+"unformated.zip", response, "uri-list should match #{uri+"/files/"+"unformated.zip"} but is #{response}"
    refute_match uri+"/files/"+"JIC37_Ethanol_0.07_Internal_1_3.txt", response, "uri-list should not match #{uri+"/files/"+"JIC37_Ethanol_0.07_Internal_1_3.txt"} but is #{response}"
    refute_match uri+"/files/"+"JIC37_Ethanol_0.07_Internal_1_4.txt", response, "uri-list should not match #{uri+"/files/"+"JIC37_Ethanol_0.07_Internal_1_4.txt"} but is #{response}"
    
    puts "\ntype isatab"
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2.zip"
    response = OpenTox::RestClientWrapper.put uri, {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    #puts task.uri
    #uri = task.resultURI
    assert_equal "Error", task.hasStatus, "Task should be not completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    assert_match "Unable to edit unformated investigation with ISA-TAB data.", task.error_report[RDF::OT.message], "wrong error: #{task.error_report[RDF::OT.message]}."
    # DELETE
    response =  OpenTox::RestClientWrapper.delete uri, {}, { :subjectid => $pi[:subjectid] }
    assert_equal "200", response.code.to_s
  end

end
