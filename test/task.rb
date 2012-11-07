require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

begin
  puts "Service URI is: #{$task[:uri]}"
rescue
  puts "Configuration Error: $task[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TaskTest < Test::Unit::TestCase

  def test_01_create_and_complete
    task = OpenTox::Task.create $task[:uri], @@subjectid, RDF::DC.description => "test" do
      sleep 1
      $task[:uri]
    end
    assert_equal true,  task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert_equal true,  task.completed?
    assert_equal "Completed", task.hasStatus
    assert_equal $task[:uri], task.resultURI
    assert_not_empty task.created_at
    assert_not_empty task.finished_at
  end

  def test_02_all
    all = OpenTox::Task.all($task[:uri])
    assert_equal Array, all.class
    t = all.last
    assert_equal OpenTox::Task, t.class
    assert_equal RDF::OT.Task, t[RDF.type]
  end

  def test_03_create_and_cancel
    task = OpenTox::Task.create $task[:uri], @@subjectid do
      sleep 2
      $task[:uri]
    end
    assert_equal true, task.running?
    task.cancel
    assert_equal true,task.cancelled?
    assert_not_empty task.created_at
    assert_not_empty task.finished_at
  end

  def test_04_create_and_fail
    task = OpenTox::Task.create $task[:uri], @@subjectid, RDF::DC.description => "test failure", RDF::DC.creator => "http://test.org/fake_creator" do
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
    assert_not_empty task.error_report[RDF::OT.errorCause]
    assert_not_empty task.created_at
    assert_not_empty task.finished_at
  end

  def test_05_create_and_fail_with_opentox_error
    task = OpenTox::Task.create $task[:uri], @@subjectid, RDF::DC.description => "test failure", RDF::DC.creator => "http://test.org/fake_creator" do
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
    assert_not_empty task.error_report[RDF::OT.errorCause]
  end

  def test_06_create_and_fail_with_not_found_error
    task = OpenTox::Task.create $task[:uri], @@subjectid, RDF::DC.description => "test failure", RDF::DC.creator => "http://test.org/fake_creator" do
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
    assert_not_empty task.error_report[RDF::OT.errorCause]
    assert_equal "404", task.error_report[RDF::OT.statusCode]
  end

  def test_07_create_and_fail_with_rest_not_found_error
    task = OpenTox::Task.create $task[:uri], @@subjectid, RDF::DC.description => "test failure", RDF::DC.creator => "http://test.org/fake_creator" do
      sleep 1
      OpenTox::Feature.new.get
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
    assert_not_empty task.error_report[RDF::OT.errorCause]
    assert_equal "404", task.error_report[RDF::OT.statusCode]
  end

  def test_08_create_and_fail_with_restclientwrapper_error
    task = OpenTox::Task.create $task[:uri], @@subjectid, RDF::DC.description => "test failure", RDF::DC.creator => "http://test.org/fake_creator" do
      sleep 1
      OpenTox::RestClientWrapper.get "invalid uri"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
    assert_not_empty task.error_report[RDF::OT.errorCause]
    assert_equal "400", task.error_report[RDF::OT.statusCode]
  end

  def test_09_check_resultURIs
    resulturi = "http://resulturi/test/1"
    task = OpenTox::Task.create $task[:uri], @@subjectid, RDF::DC.description => "test" do
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
    task = OpenTox::Task.create $task[:uri], @@subjectid, RDF::DC.description => "test" do
      sleep 1
      resource_not_found_error "test", "http://username:password@test.org/fake_uri"
    end
    task.wait
    task.get
    assert_no_match %r{username|password},  task.error_report[RDF::OT.actor]
  end

end
