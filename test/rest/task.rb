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

  def test_07_create_and_fail_with_rest_not_found_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 2
      OpenTox::Feature.new.get
    end
    assert task.running?
    assert_equal "Running", task.status
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 404, task.code
    assert_equal "Error", task.status
    #refute_empty task.error_report["errorCause"]
    #assert_equal 404, task.error_report["statusCode"]
  end

  def test_11_wait_for_error_task
    # testing two uris:
    # ../dataset/test/error_in_task starts a task that produces an internal-error with message 'error_in_task_message'  
    # ../algorithm/test/wait_for_error_in_task starts a task that waits for ../dataset/test/error_in_task
    # TODO: remove test uris from services, e.g. dynamically instantiate Sinatra routes instead
    
    def check_msg(msg,complete)
      assert msg=~/bad_request_error_in_task/,"original task error message ('bad_request_error_in_task') is lost: #{msg}"
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
        p ex
        p ex.message
        p ex.error_cause
        check_msg(ex.message,ex.error_cause)
      end

      ## test2: test if task is set accordingly
      assert task.error?
      assert task.error_report["errorCode"]==OpenTox::BadRequestError.to_s,"errorCode should be #{OpenTox::BadRequestError.to_s}, but is #{task.error_report["errorCode"]}"
      check_msg(task.error_report["message"],task.error_report["errorCause"])
    end
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
        assert ex.error_cause=~/test.rb:#{test[:line]}/,"code line number test.rb:#{test[:line]} is lost or wrong: #{ex.error_cause}"
        assert ex.uri==test[:uri]
      end
    end
  end


end
