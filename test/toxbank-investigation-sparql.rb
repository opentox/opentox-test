require_relative "toxbank-setup.rb"

# Test API extension SPARQL templates 
class TBSPARQLTest < MiniTest::Test

  # login as pi and create a test investigation
  def setup
    OpenTox::RestClientWrapper.subjectid = $pi[:subjectid] # set pi as the logged in user
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

  # initial test to be changed
  def test_01_initial
    response = OpenTox::RestClientWrapper.get "#{@@uri}/sparql/not_existing_template", {}, {:accept => "application/rdf+xml", :subjectid => $pi[:subjectid]}
    assert_equal 200, response.code
  end

  # delete investigation/{id}
  # @note expect code 200
  def teardown
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => $pi[:subjectid]}
    assert_equal 200, result.code
  end

end