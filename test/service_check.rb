require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")

SERVICES = [$algorithm[:uri], $compound[:uri], $dataset[:uri], $feature[:uri], $model[:uri], $task[:uri], $validation[:uri]]

begin
  puts "Service URIs are:\n"
  SERVICES.each do |service|
    puts service
  end
rescue
  puts "Configuration Error: #{service} is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class ServiceCheck < MiniTest::Test
    
  def test_algorithm
    response = OpenTox::RestClientWrapper.head($algorithm[:uri])
    assert_equal 200, response.code
  end
  
  def test_compound
    response = OpenTox::RestClientWrapper.head($compound[:uri])
    assert_equal 200, response.code
  end
  
  def test_dataset
    response = OpenTox::RestClientWrapper.head($dataset[:uri])
    assert_equal 200, response.code
  end
  
  def test_feature
    response = OpenTox::RestClientWrapper.head($feature[:uri])
    assert_equal 200, response.code
  end
  
  def test_model
    response = OpenTox::RestClientWrapper.head($model[:uri])
    assert_equal 200, response.code
  end
  
  def test_task
    response = OpenTox::RestClientWrapper.head($task[:uri])
    assert_equal 200, response.code
  end
  
  def test_validation
    response = OpenTox::RestClientWrapper.head($validation[:uri])
    assert_equal 200, response.code
  end
end
