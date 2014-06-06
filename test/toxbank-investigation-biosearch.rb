require_relative "toxbank-setup.rb"
require File.join(File.expand_path(File.dirname(__FILE__)),".." ,".." ,"toxbank-investigation", "util.rb")

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TBInvestigationUploadBio < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!


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
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    $uri1 = URI(uri)
    # update
    res = OpenTox::RestClientWrapper.put $uri1.to_s, { :published => "true", :owningPro => "#{$user_service[:uri]}/project/G2"}, { :subjectid => $pi[:subjectid] }
    task_uri = res.chomp
    task = OpenTox::Task.new task_uri
    task.wait
  end

  # create a new investigation by uploading a zip file,
  # Summary is not searchable, but published. { access=ToxBank group }
  def test_02_post_investigation
    $uri2 = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    $uri2 = URI(uri)
    # update
    res = OpenTox::RestClientWrapper.put $uri2.to_s, { :published => "true", :owningPro => "#{$user_service[:uri]}/project/G2"}, { :subjectid => $pi[:subjectid] }
    task_uri = res.chomp
    task = OpenTox::Task.new task_uri
    task.wait
  end

  # create a new investigation by uploading a zip file,
  # Summary is not searchable, but published. { access=ToxBank group }
  def test_03_post_investigation
    $uri3 = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $owner }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    assert_equal "Completed", task.hasStatus, "Task should be completed but is: #{task.hasStatus}. Task URI is #{task_uri} ."
    $uri3 = URI(uri)
    # update
    res = OpenTox::RestClientWrapper.put $uri3.to_s, { :published => "true", :owningPro => "#{$user_service[:uri]}/project/G2"}, { :subjectid => $pi[:subjectid] }
    task_uri = res.chomp
    task = OpenTox::Task.new task_uri
    task.wait
  end

end

class TBInvestigationBioSearch < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!

  def test_01_biosearch_owner
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_and_characteristics", {}, {:accept => "application/json", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
    result = JSON.parse(response)
    inv_chars = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["propname"]["value"]}:::#{n["propValue"]["value"]}:::#{n["ontouri"]["value"]}"}
    assert inv_chars.include?("#{$uri1}:::Label:::#{$uri1}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri1}:::organism:::#{$uri1}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
    assert inv_chars.include?("#{$uri2}:::Label:::#{$uri2}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri2}:::organism:::#{$uri2}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
    assert inv_chars.include?("#{$uri3}:::Label:::#{$uri3}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri3}:::organism:::#{$uri3}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
  end

  def test_02_biosearch_user1
    response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_and_characteristics", {}, {:accept => "application/json", :subjectid => $secondpi[:subjectid]}
    assert_equal 200, response.code
    result = JSON.parse(response)
    inv_chars = result["results"]["bindings"].map{|n| "#{n["investigation"]["value"]}:::#{n["propname"]["value"]}:::#{n["propValue"]["value"]}:::#{n["ontouri"]["value"]}"}
    assert inv_chars.include?("#{$uri1}:::Label:::#{$uri1}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri1}:::organism:::#{$uri1}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
    assert inv_chars.include?("#{$uri2}:::Label:::#{$uri2}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri2}:::organism:::#{$uri2}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
    assert inv_chars.include?("#{$uri3}:::Label:::#{$uri3}/CV2:::http://purl.obolibrary.org/chebi/15956")
    assert inv_chars.include?("#{$uri3}:::organism:::#{$uri3}/CV4:::http://purl.obolibrary.org/obo/NEWT_4932")
  end
  
  def test_03_biosearch_user2
    assert_raises OpenTox::BadRequestError do
      response = OpenTox::RestClientWrapper.get "#{$investigation[:uri]}/sparql/investigation_and_characteristics", {}, {:accept => "application/json", :subjectid => $guestid}
    end
  end

end

class TBInvestigationDelete < MiniTest::Test

  def test_00_delete
    [$uri1, $uri2, $uri3].each do |uri|
      response = OpenTox::RestClientWrapper.delete uri.to_s, {}, { :subjectid => $owner }
      assert_equal 200, response.code
    end
  end

end

