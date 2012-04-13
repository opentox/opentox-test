require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
#require "./validate-owl.rb"

begin
  @@service_uri = $task[:uri]
rescue
  puts "Configuration Error: $task[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class TaskTest < Test::Unit::TestCase

  def test_all
    all = OpenTox::Task.all(@@service_uri)
    assert_equal Array, all.class
    t = all.last
    assert_equal OpenTox::Task, t.class
    assert_equal RDF::OT1.Task, t[RDF.type]
  end

  def test_create_and_complete
    task = OpenTox::Task.create @@service_uri, :description => "test" do
      sleep 1
      @@service_uri
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.completed?
    assert_equal "Completed", task.hasStatus
    assert_equal @@service_uri, task.resultURI
  end

  def test_create_and_cancel
    task = OpenTox::Task.create @@service_uri do
      sleep 2
      @@service_uri
    end
    assert task.running?
    task.cancel
    assert task.cancelled?
  end

  def test_create_and_fail
    task = OpenTox::Task.create @@service_uri, :description => "test failure", :creator => "http://test.org/fake_creator" do
      sleep 1
      raise "A runtime error occured"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
  end

  def test_create_and_fail_with_opentox_error
    task = OpenTox::Task.create @@service_uri, :description => "test failure", :creator => "http://test.org/fake_creator" do
      sleep 1
      raise OpenTox::Error.new 500, "An OpenTox::Error occured"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
  end

=begin
  # temporarily removed until uri checking from virtual machines has been fixed
  def test_wrong_result_uri
    task = OpenTox::Task.create @@service_uri, :description => "test wrong result uri", :creator => "http://test.org/fake_creator" do
      sleep 1
      "Asasadasd"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
  end
=end

end
