require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
#require "./validate-owl.rb"

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
    #task.pull
    puts task.metadata.inspect
    #assert_equal true, task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    #sleep 2
    assert_equal true,  task.completed?
    assert_equal "Completed", task.hasStatus
    assert_equal $task[:uri], task.resultURI
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
    # TODO test error reports
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
    # TODO test error reports
  end

=begin
  # temporarily removed until uri checking from virtual machines has been fixed
  def test_06_wrong_result_uri
    task = OpenTox::Task.create $task[:uri], RDF::DC.description => "test wrong result uri", RDF::DC.creator => "http://test.org/fake_creator" do
      sleep 1
      "http://Asasadasd"
    end
    assert task.running?
    assert_equal "Running", task.hasStatus
    task.wait
    assert task.error?
    assert_equal "Error", task.hasStatus
  end
=end

end
