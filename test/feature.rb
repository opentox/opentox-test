require_relative "setup.rb"

class FeatureTest < MiniTest::Test

  def test_opentox_feature
    @feature = OpenTox::Feature.new
    @feature.title = "tost"
    @feature.save
    assert_equal true, OpenTox::Feature.where(title: "tost").exists?, "#{@feature.id} is not accessible."
    assert_equal true, OpenTox::Feature.where(id: @feature.id).exists?, "#{@feature.id} is not accessible."

    list = OpenTox::Feature.all
    listsize1 = list.length
    assert_equal true, list.collect{|f| f.id}.include?(@feature.id)
    # modify feature
    @feature2 = OpenTox::Feature.find(@feature.id)
    assert_equal "tost", @feature2[:title]
    assert_equal "tost", @feature2.title
    assert_equal 'Feature', @feature2.type

    @feature2[:title] = "feature2"
    @feature2.save
    list = OpenTox::Feature.all 
    listsize2 = list.length
    assert_match "feature2", @feature2.title
    refute_match "tost", @feature2.title
    assert_equal listsize1, listsize2

    id = @feature2.id
    @feature2.delete
    #TODO
    #assert_raises OpenTox::ResourceNotFoundError do
    assert_raises Mongoid::Errors::DocumentNotFound do
      OpenTox::Feature.find(id)
    end
  end

  def test_duplicated_features
    metadata = {
      :title => "feature duplication test",
      :string => true,
      :description => "feature duplication test"
    }
    feature = OpenTox::Feature.find_or_create_by metadata
    dup_feature = OpenTox::Feature.find_or_create_by metadata
    assert !feature.id.nil?, "No Feature ID in #{feature.inspect}"
    assert !feature.id.nil?, "No Feature ID in #{dup_feature.inspect}"
    assert_equal feature.id, dup_feature.id
    feature.delete
    #TODO
    #assert_raises OpenTox::ResourceNotFoundError do
    assert_raises Mongoid::Errors::DocumentNotFound do
      OpenTox::Feature.find(feature.id)
    end
    assert_raises Mongoid::Errors::DocumentNotFound do
      OpenTox::Feature.find(dup_feature.id)
    end
  end

end


