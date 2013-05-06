require_relative "setup.rb"

begin
  puts "Service URI is: #{$task[:uri]}"
rescue
  puts "Configuration Error: $task[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class String 
  def uri?
    uri = URI.parse(self)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end
end

class TaskTest < MiniTest::Unit::TestCase

  def test_01_create_and_complete
    task = OpenTox::Task.run __method__,nil,@@subjectid do
      sleep 1
      $task[:uri]
    end
    assert_equal true,  task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert_equal true,  task.completed?
    assert_equal "Completed", task.hasStatus
    assert_equal $task[:uri], task.resultURI
    refute_empty task.created_at
    refute_empty task.finished_at
  end

  def test_02_all
    all = OpenTox::Task.all
    assert_equal Array, all.class
    t = all.last
    assert_equal OpenTox::Task, t.class
    assert_equal RDF::OT.Task, t[RDF.type]
  end

  def test_03_create_and_cancel
    task = OpenTox::Task.run __method__,nil,@@subjectid do
      sleep 2
      $task[:uri]
    end
    assert_equal true, task.running?
    task.cancel
    assert_equal true,task.cancelled?
    refute_empty task.created_at.to_s
    refute_empty task.finished_at.to_s
  end

  def test_04_create_and_fail
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator",@@subjectid do
      sleep 2
      raise "A runtime error occured"
    end
    assert_equal true, task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
    assert_equal "A runtime error occured", task.error_report[RDF::OT.message]
    assert_equal "500", task.error_report[RDF::OT.statusCode]
    refute_empty task.error_report[RDF::OT.errorCause]
    refute_empty task.created_at
    refute_empty task.finished_at
  end

  def test_05_create_and_fail_with_opentox_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator",@@subjectid do
      sleep 1
      raise OpenTox::Error.new 500, "An OpenTox::Error occured"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
    assert_equal "An OpenTox::Error occured", task.error_report[RDF::OT.message]
    assert_equal "500", task.error_report[RDF::OT.statusCode]
    refute_empty task.error_report[RDF::OT.errorCause]
  end

  def test_06_create_and_fail_with_not_found_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator",@@subjectid do
      sleep 1
      resource_not_found_error "An OpenTox::ResourceNotFoundError occured",  "http://test.org/fake_creator"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
    assert_equal "An OpenTox::ResourceNotFoundError occured", task.error_report[RDF::OT.message]
    assert_equal "OpenTox::ResourceNotFoundError", task.error_report[RDF::OT.errorCode]
    refute_empty task.error_report[RDF::OT.errorCause]
    assert_equal "404", task.error_report[RDF::OT.statusCode]
  end

  def test_07_create_and_fail_with_rest_not_found_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator",@@subjectid do
      sleep 1
      OpenTox::Feature.new.get
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
    refute_empty task.error_report[RDF::OT.errorCause]
    assert_equal "404", task.error_report[RDF::OT.statusCode]
  end

  def test_08_create_and_fail_with_restclientwrapper_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator",@@subjectid do
      sleep 1
      OpenTox::RestClientWrapper.get "invalid uri"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
    refute_empty task.error_report[RDF::OT.errorCause]
    assert_equal "400", task.error_report[RDF::OT.statusCode]
  end

  def test_09_check_resultURIs
    resulturi = "http://resulturi/test/1"
    task = OpenTox::Task.run __method__,nil,@@subjectid do
      sleep 1
      resulturi
    end
    assert_equal "Running", task.hasStatus
    response = OpenTox::RestClientWrapper.get task.uri,nil, {:accept => "text/uri-list"}
    assert_equal 202, response.code
    assert_equal task.uri, response
    assert_equal nil, task.resultURI
    task.wait
    response = OpenTox::RestClientWrapper.get task.uri,nil, {:accept => "text/uri-list"}
    assert_equal 200, response.code
    assert_equal resulturi, response
    assert_equal resulturi, task.resultURI
  end

  def test_10_uri_with_credentials
    task = OpenTox::Task.run __method__,nil,@@subjectid do
      sleep 1
      resource_not_found_error "test", "http://username:password@test.org/fake_uri"
    end
    task.wait
    refute_match %r{username|password},  task.error_report[RDF::OT.actor]
  end

  def test_11_wait_for_error_task
    # testing two uris:
    # ../dataset/test/error_in_task starts a task that produces an internal-error with message 'error_in_task_message'  
    # ../algorithm/test/wait_for_error_in_task starts a task that waits for ../dataset/test/error_in_task
    # TODO: remove test uris from services, e.g. dynamically instantiate Sinatra routes instead
    [ File.join($dataset[:uri],'test/error_in_task'),
      File.join($algorithm[:uri],'test/wait_for_error_in_task')
    ].each do |uri|
        
      task_uri = OpenTox::RestClientWrapper.post uri, nil, {:subjectid => @@subjectid}
      assert(URI.task?(task_uri) ,"no task uri: #{task_uri}")
      task = OpenTox::Task.new task_uri
      
      # test1: wait_for_task, this should abort
      begin
        wait_for_task task_uri
        assert false,"should have thrown an error because there was an error in the task we have waited for"
      rescue => ex
        assert ex.message=~/error_in_task_message/,"orignial task error message ('error_in_task_message') is lost"
      end

      # test2: test if task is set accordingly
      assert task.error?
      assert task.error_report[RDF::OT.message]=~/error_in_task_message/,"orignial task error message ('error_in_task_message') is lost"
    end
  end
  
  def test_12_non_runtime_errors

    [RuntimeError, ThreadError, StopIteration, LocalJumpError, EOFError, IOError, RegexpError, 
     FloatDomainError, ZeroDivisionError, SystemCallError, EncodingError, NoMethodError, NameError, 
     RangeError, KeyError, IndexError, ArgumentError, TypeError].each do |ex|
      
      error_msg = "raising a #{ex}"
      
      task = OpenTox::Task.run __method__,"http://test.org/fake_creator",@@subjectid do
        sleep 2
        raise ex,error_msg
      end
      
      assert task.running?
      assert_equal "Running", task.hasStatus
      task.wait
      assert task.error?
      assert_equal "Error", task.hasStatus
      refute_empty task.error_report[RDF::OT.errorCause]
      assert_match error_msg,task.error_report[RDF::OT.message]
    end
    
  end

end
