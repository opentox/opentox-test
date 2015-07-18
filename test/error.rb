require_relative "setup.rb"

class ErrorTest < MiniTest::Test

  def test_bad_request
    object = OpenTox::Feature.new 
    p object.id
    #TODO
    #assert_raises OpenTox::ResourceNotFoundError do
    assert_raises Mongoid::Errors::DocumentNotFound do
      response = OpenTox::Feature.find(object.id)
    end
  end

  def test_error_methods
    assert_raises OpenTox::ResourceNotFoundError do
      resource_not_found_error "This is a test"
    end
  end

  def test_exception
    assert_raises Exception do
      raise Exception.new "Basic Exception"
    end
  end

  def test_backtick
    assert_raises OpenTox::InternalServerError do
      `this call will not work`
    end
    assert_raises OpenTox::InternalServerError do
      `ls inexisting_directory`
    end
  end

end
