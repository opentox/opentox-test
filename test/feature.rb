require_relative "setup.rb"

class FeatureTest < MiniTest::Test

  def test_opentox_feature
    @feature = OpenTox::Feature.new
    @feature[:title] = "tost"
    @feature.save
    assert_equal true, @feature.exists?, "#{@feature.id} is not accessible."

    list = OpenTox::Feature.all 
    listsize1 = list.length
    assert_equal true, list.collect{|f| f.id}.include?(@feature.id)
    # modify feature
    @feature2 = OpenTox::Feature.find(:_id => @feature.id)
    assert_equal "tost", @feature2[:title]
    assert_equal 'Feature', @feature2[:type]

    @feature2[:title] = "feature2"
    @feature2.put
    list = OpenTox::Feature.all 
    listsize2 = list.length
    @feature2.get
    assert_match "feature2", @feature2.title
    refute_match "tost", @feature2.title
    assert_equal listsize1, listsize2

    id = @feature2.id
    @feature2.delete
    assert_nil  OpenTox::Feature.find_id(id), "Feature #{id} is still accessible."
  end

  def test_duplicated_features
    metadata = {
      :title => "feature duplication test",
      :type => ["Feature", "StringFeature"],
      :description => "feature duplication test"
    }
    feature = OpenTox::Feature.find_or_create metadata
    dup_feature = OpenTox::Feature.find_or_create metadata
    assert !feature.id.nil?, "No Feature ID in #{feature.inspect}"
    assert !feature.id.nil?, "No Feature ID in #{dup_feature.inspect}"
    assert_equal feature.id, dup_feature.id
    feature.delete
    assert_nil  OpenTox::Feature.find_id(feature.id), "Feature #{feature.id} is still accessible."
    assert_nil  OpenTox::Feature.find_id(dup_feature.id), "Feature #{dup_feature.id} is still accessible."
  end

end


