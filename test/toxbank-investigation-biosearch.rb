require_relative "toxbank-setup.rb"
require File.join(File.expand_path(File.dirname(__FILE__)),".." ,".." ,"toxbank-investigation", "util.rb")

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TBInvestigationUploadBio < MiniTest::Test
  
  def self.test_order
    :sorted
  end

  # define different users
  $owner = $pi[:subjectid]
  $user1 = $secondpi[:subjectid]
  $user2 = $guestid

  def test_00_select_user
    OpenTox::RestClientWrapper.subjectid = $owner
  end

  # create a new investigation by uploading a zip file,
  # Summary is not searchable, but published. { access=ToxBank group }
  def test_01_post_investigation
    $uri1 = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2_ftp.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    $uri1 = URI(uri)
    # update
    res = OpenTox::RestClientWrapper.put $uri1.to_s, { :published => "true", :allowReadByGroup => "#{$user_service[:uri]}/project/G2"}, { :subjectid => $pi[:subjectid] }
    task_uri = res.chomp
    task = OpenTox::Task.new task_uri
    task.wait
  end

  # create a new investigation by uploading a zip file,
  # Summary is not searchable, but published. { access=ToxBank group }
  def test_02_post_investigation
    $uri2 = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2_ftp.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    $uri2 = URI(uri)
    # update
    res = OpenTox::RestClientWrapper.put $uri2.to_s, { :published => "true"}, { :subjectid => $pi[:subjectid] }
    task_uri = res.chomp
    task = OpenTox::Task.new task_uri
    task.wait
  end

  def test_04_biosearch_owner
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_and_characteristics", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
    result = JSON.parse(response)
    inv_chars = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["propname"]["value"]}:::#{n["propValue"]["value"]}:::#{n["ontouri"]["value"]}"}
    assert inv_chars.include?("#{$uri1}:::Label:::#{$uri1}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri1}:::organism:::#{$uri1}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
    assert inv_chars.include?("#{$uri2}:::Label:::#{$uri2}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri2}:::organism:::#{$uri2}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
  end

  def test_05_biosearch_user1
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_and_characteristics", {}, {:accept => "application/json", :subjectid => $secondpi[:subjectid]}
    assert_equal 200, response.code
    result = JSON.parse(response)
    inv_chars = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["propname"]["value"]}:::#{n["propValue"]["value"]}:::#{n["ontouri"]["value"]}"}
    assert inv_chars.include?("#{$uri1}:::Label:::#{$uri1}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri1}:::organism:::#{$uri1}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
    refute inv_chars.include?("#{$uri2}:::Label:::#{$uri2}/CV2:::http://purl.obolibrary.org/chebi/15956")
    refute inv_chars.include?("#{$uri2}:::organism:::#{$uri2}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
  end
  
  def test_06_biosearch_user2
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_and_characteristics", {}, {:accept => "application/json", :subjectid => $guestid}
    result = JSON.parse(response)
    inv_chars = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["propname"]["value"]}:::#{n["propValue"]["value"]}:::#{n["ontouri"]["value"]}"}
    refute inv_chars.include?("#{$uri1}:::Label:::#{$uri1}/CV2:::http://purl.obolibrary.org/chebi/15956")
    refute inv_chars.include?("#{$uri1}:::organism:::#{$uri1}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
    refute inv_chars.include?("#{$uri2}:::Label:::#{$uri2}/CV2:::http://purl.obolibrary.org/chebi/15956")
    refute inv_chars.include?("#{$uri2}:::organism:::#{$uri2}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
  end

  def test_99_delete
    [$uri1, $uri2].each do |uri|
      response = OpenTox::RestClientWrapper.delete uri.to_s, {}, { :subjectid => $owner }
      assert_equal 200, response.code
    end
  end
end
