require_relative "setup.rb"

begin
  puts "Service URI is: #{$investigation[:uri]}"
rescue
  puts "Configuration Error: $investigation[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end


class StressTest < MiniTest::Unit::TestCase

  # Do multiple POST and check if completed
  def test_01_multiple_upload
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b-tb2.zip"
    response = []; task_uri = []; task =[]
    (0..2).each do |i|
      response[i] = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
      task_uri[i] = response[i].chomp
      task[i] = OpenTox::Task.new task_uri[i]
    end
    (0..2).each do |i|
      task[i].wait
      assert_equal true,  task[i].completed?
      assert_equal "Completed", task[i].hasStatus
      result = OpenTox::RestClientWrapper.delete task[i].resultURI.to_s, {}, {:subjectid => $pi[:subjectid]}
      assert_equal 200, result.code
    end
  end

  # Creates investigation for later Update
  def test_02a_pre_multiple_updates
    @@uri = ""
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1b-tb2.zip"
    response = OpenTox::RestClientWrapper.post $investigation[:uri], {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    task_uri = response.chomp
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    @@uri = URI(uri)  
  end

  # Do multipe update on existing investigation
  def test_02b_multiple_updates
    file = File.join File.dirname(__FILE__), "data/toxbank-investigation/valid", "BII-I-1-tb2.zip"
    response = []; task_uri = []; task =[]
    response[0] = OpenTox::RestClientWrapper.put "#{@@uri}", {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
    assert_equal 202, response[0].code
    task_uri[0] = response[0].chomp
    (1..2).each do |i|
      response[i] = OpenTox::RestClientWrapper.put "#{@@uri}", {:file => File.open(file)}, { :subjectid => $pi[:subjectid] }
      task_uri[i] = response[i].chomp
    end
    (1..2).each do |i|
      #assert_raise OpenTox::LockedError do
        task[i] = OpenTox::Task.new task_uri[i]
        task[i].wait
      #end
      assert_equal false,  task[i].completed?
      assert_equal "Error", task[i].hasStatus
    end
    task[0] = OpenTox::Task.new task_uri[0]
    task[0].wait
    assert_equal true,  task[0].completed?
    assert_equal "Completed", task[0].hasStatus
  end
  
  # Delete Test-investigation
  def test_98_delete_investigation
    result = OpenTox::RestClientWrapper.delete @@uri.to_s, {}, {:subjectid => $pi[:subjectid]}
    assert_equal 200, result.code
  end
  
end
