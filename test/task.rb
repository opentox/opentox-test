require_relative "setup.rb"
# TODO: fix error reports

class TaskTest < MiniTest::Test

  def assert_task_completed task
    assert_equal 200, task.code
    assert_equal true,  task.completed?
    assert_equal "Completed", task.status
    assert_equal "TEST", task.result
    assert_kind_of Time, task.created_at
    assert_kind_of Time, task.finished_at
    assert true, task.finished_at > task.created_at
  end

  def test_basic
    task = OpenTox::Task.new
    task.completed("TEST")
    assert_task_completed task
  end

  def test_01_create_and_complete
    task = OpenTox::Task.run __method__ do
      sleep 2
      "TEST"
    end
    assert_equal true,  task.running?
    assert_equal "Running", task.status
    assert_equal 202, task.code
    p "running"
    task.wait
    p "completed"
    assert_task_completed task
  end

  def test_02_all
    all = OpenTox::Task.all
    t = all.last
    assert_equal OpenTox::Task, t.class
    assert_equal "Task", t.type
  end

  def test_03_create_and_cancel
    task = OpenTox::Task.run __method__ do
      sleep 2
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
      sleep 2
      raise "A runtime error occured"
    end
    assert_equal true, task.running?
    assert_equal "Running", task.status
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 500, task.code
    assert_equal "Error", task.status
    # assert_equal "A runtime error occured", task.error_report["message"]
    # assert_equal 500, task.error_report["statusCode"]
    # refute_empty task.error_report["errorCause"]
    assert true, task.created_at < task.finished_at
    refute_empty task.created_at.to_s
    refute_empty task.finished_at.to_s
  end

  def test_05_create_and_fail_with_opentox_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 2
      raise OpenTox::Error.new 500, "An OpenTox::Error occured"
    end
    assert task.running?
    assert_equal "Running", task.status
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 500, task.code
    assert_equal "Error", task.status
    #assert_equal "An OpenTox::Error occured", task.error_report["message"]
    #assert_equal 500, task.error_report["statusCode"]
    #refute_empty task.error_report["errorCause"]
  end

  def test_06_create_and_fail_with_not_found_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 2
      resource_not_found_error "An OpenTox::ResourceNotFoundError occured",  "http://test.org/fake_creator"
    end
    assert task.running?
    assert_equal "Running", task.status
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 404, task.code
    assert_equal "Error", task.status
    #assert_equal "An OpenTox::ResourceNotFoundError occured", task.error_report["message"]
    #assert_equal "OpenTox::ResourceNotFoundError", task.error_report["errorCode"]
    #refute_empty task.error_report["errorCause"]
    #assert_equal 404, task.error_report["statusCode"]
  end

  def test_08_create_and_fail_with_restclientwrapper_error
    task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
      sleep 2
      OpenTox::RestClientWrapper.get "invalid uri"
    end
    assert task.running?
    assert_equal "Running", task.status, "Expected Task Running has status: #{task.status} - #{task.id}"
    assert_equal 202, task.code
    task.wait
    assert task.error?
    assert_equal 400, task.code
    assert_equal "Error", task.status
    #refute_empty task.error_report["errorCause"]
    #assert_equal 400, task.error_report["statusCode"]
  end

  def test_09_check_results
    resulturi = "http://resulturi/test/1"
    task = OpenTox::Task.run __method__ do
      sleep 2
      resulturi
    end
    assert_equal "Running", task.status
    assert_equal 202, task.code
    assert_equal nil, task.result
    task.wait
    assert_equal 200, task.code
    assert_equal resulturi, task.result
  end

  def test_10_uri_with_credentials
    task = OpenTox::Task.run __method__,nil do
      sleep 1
      resource_not_found_error "test", "http://username:password@test.org/fake_uri"
    end
    task.wait
    #refute_match %r{username|password},  task.error_report["actor"]
  end


  def test_12_non_runtime_errors

    [RuntimeError, ThreadError, StopIteration, LocalJumpError, EOFError, IOError, RegexpError, 
     FloatDomainError, ZeroDivisionError, SystemCallError, EncodingError, NoMethodError, NameError, 
     RangeError, KeyError, IndexError, ArgumentError, TypeError].each do |ex|
      
      error_msg = "raising a #{ex}"
      
      task = OpenTox::Task.run __method__,"http://test.org/fake_creator" do
        sleep 2
        raise ex,error_msg
      end
      assert task.running?
      assert_equal "Running", task.status
      assert_equal 202, task.code
      task.wait
      assert task.error?
      assert_equal 500, task.code
      assert_equal "Error", task.status
      #refute_empty task.error_report["errorCause"]
      #assert_match error_msg,task.error_report["message"]
    end
    
  end

end
