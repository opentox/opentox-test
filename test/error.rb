require_relative "setup.rb"

class ErrorTest < MiniTest::Test

  def test_bad_request
    object = OpenTox::Feature.new 
    assert_raises OpenTox::ResourceNotFoundError do
      response = object.get
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
