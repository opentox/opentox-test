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

class TaskTest < MiniTest::Test

  def test_01_create_and_complete
    task = OpenTox::Task.run __method__ do
      sleep 5
      $task[:uri]
    end
      p $task[:uri]
    assert_equal true,  task.running?
    assert_equal "Running", task.hasStatus
    assert_equal 202, task.code
    task.wait
    assert_equal 200, task.code
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
    assert_equal "Task", t[:type]
  end

  def test_03_create_and_cancel
    task = OpenTox::Task.run __method__ do
      sleep 5
      $task[:uri]
    end
    assert_equal true, task.running?
    assert_equal 202, task.code
    task.cancel
    assert_equal 503, task.code
    assert_equal true, task.cancelled?
    refute_empty task.created_at.to_s
    refute_empty task.finished_at.to_s
  end

  def test_04_create_and_fail
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 5
      raise "A runtime error occured"
    end
    assert_equal true, task.running?
    assert_equal "Running", task.hasStatus
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 500, task.code
    assert_equal "Error", task.hasStatus
    assert_equal "A runtime error occured", task.error_report["message"]
    assert_equal 500, task.error_report["statusCode"]
    refute_empty task.error_report["errorCause"]
    refute_empty task.created_at
    refute_empty task.finished_at
  end

  def test_05_create_and_fail_with_opentox_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 5
      raise OpenTox::Error.new 500, "An OpenTox::Error occured"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 500, task.code
    assert_equal "Error", task.hasStatus
    assert_equal "An OpenTox::Error occured", task.error_report["message"]
    assert_equal 500, task.error_report["statusCode"]
    refute_empty task.error_report["errorCause"]
  end

  def test_06_create_and_fail_with_not_found_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 5
      resource_not_found_error "An OpenTox::ResourceNotFoundError occured",  "http://test.org/fake_creator"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 404, task.code
    assert_equal "Error", task.hasStatus
    assert_equal "An OpenTox::ResourceNotFoundError occured", task.error_report["message"]
    assert_equal "OpenTox::ResourceNotFoundError", task.error_report["errorCode"]
    refute_empty task.error_report["errorCause"]
    assert_equal 404, task.error_report["statusCode"]
  end

  def test_07_create_and_fail_with_rest_not_found_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 5
      OpenTox::Feature.new.get
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 404, task.code
    assert_equal "Error", task.hasStatus
    refute_empty task.error_report["errorCause"]
    assert_equal 404, task.error_report["statusCode"]
  end

  def test_08_create_and_fail_with_restclientwrapper_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 5
      OpenTox::RestClientWrapper.get "invalid uri"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus, "Expected Task Running has status: #{task.hasStatus} - #{task.uri}"
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 400, task.code
    assert_equal "Error", task.hasStatus
    refute_empty task.error_report["errorCause"]
    assert_equal 400, task.error_report["statusCode"]
  end

  def test_09_check_resultURIs
    resulturi = "http://resulturi/test/1"
    task = OpenTox::Task.run __method__ do
      sleep 5
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
    task = OpenTox::Task.run __method__,nil do
      sleep 1
      resource_not_found_error "test", "http://username:password@test.org/fake_uri"
    end
    task.wait
    refute_match %r{username|password},  task.error_report["actor"]
  end

  def test_11a_plain_errors
    tests = [ { :uri=>File.join($dataset[:uri],'test/plain_error'),
                :error=>OpenTox::BadRequestError,
                :msg=>"plain_bad_request_error",
                :line=>"16" },
              { :uri=>File.join($dataset[:uri],'test/plain_no_ot_error'),
                :error=>OpenTox::InternalServerError,
                :msg=>"undefined method `no_method_for_nil' for nil:NilClass",
                :line=>"20" } ]
    tests.each do |test|
      begin
        OpenTox::RestClientWrapper.get test[:uri]
        assert false,"there should have been an error"
      rescue => ex
        assert ex.is_a?(test[:error]),"error type should be a #{test[:error]}, but is a #{ex.class}"
        assert ex.message=~/#{test[:msg]}/,"message should be #{test[:msg]}, but is #{ex.message}"
        p ex.error_cause
        assert ex.error_cause=~/test.rb:#{test[:line]}/,"code line number test.rb:#{test[:line]} is lost or wrong: #{ex.error_cause}"
        assert ex.uri==test[:uri]
      end
    end
  end

  def test_11_wait_for_error_task
    # testing two uris:
    # ../dataset/test/error_in_task starts a task that produces an internal-error with message 'error_in_task_message'  
    # ../algorithm/test/wait_for_error_in_task starts a task that waits for ../dataset/test/error_in_task
    # TODO: remove test uris from services, e.g. dynamically instantiate Sinatra routes instead
    
    def check_msg(msg,complete)
      assert msg=~/bad_request_error_in_task/,"orignial task error message ('bad_request_error_in_task') is lost: #{msg}"
      assert((msg=~/\\/)==nil,"no backslashes please!")
      assert complete=~/test.rb:9/,"code line number test.rb:9 is lost"
    end
    
    [ File.join($dataset[:uri],'test/error_in_task'),
      File.join($algorithm[:uri],'test/wait_for_error_in_task')
    ].each do |uri|
        
      task_uri = OpenTox::RestClientWrapper.post uri
      assert(URI.task?(task_uri) ,"no task uri: #{task_uri}")
      task = OpenTox::Task.new task_uri
      
      # test1: wait_for_task, this should abort
      begin
        wait_for_task task_uri
        assert false,"should have thrown an error because there was an error in the task we have waited for"
      rescue => ex
        assert ex.is_a?(OpenTox::BadRequestError),"not a bad request error, instead: #{ex.class}"
        check_msg(ex.message,ex.error_cause)
      end

      ## test2: test if task is set accordingly
      assert task.error?
      assert task.error_report["errorCode"]==OpenTox::BadRequestError.to_s,"errorCode should be #{OpenTox::BadRequestError.to_s}, but is #{task.error_report["errorCode"]}"
      check_msg(task.error_report["message"],task.error_report["errorCause"])
    end
  end

  def test_12_non_runtime_errors

    [RuntimeError, ThreadError, StopIteration, LocalJumpError, EOFError, IOError, RegexpError, 
     FloatDomainError, ZeroDivisionError, SystemCallError, EncodingError, NoMethodError, NameError, 
     RangeError, KeyError, IndexError, ArgumentError, TypeError].each do |ex|
      
      error_msg = "raising a #{ex}"
      
      task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
        sleep 5
        raise ex,error_msg
      end
      assert task.running?
      assert_equal "Running", task.hasStatus
      assert_equal 202, task.code
      task.wait
      assert task.error?
      assert_equal 500, task.code
      assert_equal "Error", task.hasStatus
      refute_empty task.error_report["errorCause"]
      assert_match error_msg,task.error_report["message"]
    end
    
  end
=begin
=end

end
