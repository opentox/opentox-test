require_relative "setup.rb"

class FeatureRestTest < MiniTest::Test
  
  # edit object metadata and compare
  def test_metadata
    # OpenTox::Feature
    # create object, pass additional values
    f = OpenTox::Feature.new nil, SUBJECTID
    f.title = "first"
    f.description = "first test description"
    f.put
    
    # get object to compare first
    f2 = OpenTox::Feature.find f.uri, SUBJECTID
    assert_equal f.title, f2.title
    assert_equal f.description, f2.description

    # edit object and PUT back
    f2.title = "second"
    f2.description = f.description.reverse
    f2.put
    
    # get object to compare again
    f3 = OpenTox::Feature.find f.uri, SUBJECTID
    refute_equal f.title, f3.title
    refute_equal f.description, f3.description
  end
  
  # TODO edit object and compare rdf representation

  
end
