# TODO: check json specification at https://github.com/opentox-api/api-specification/issues/2

require_relative "setup.rb"

class DatasetTest < MiniTest::Test

=begin

# TODO: and add Egons example
  def test_sdf_with_multiple_features
    @dataset = OpenTox::Dataset.new nil
    @dataset.upload "#{DATA_DIR}/CPDBAS_v5c_1547_29Apr2008part.sdf"
    assert_equal OpenTox::Dataset, @dataset.class
    puts @dataset.features.size
    puts @dataset.compounds.size
    @dataset.delete
  end

# TODO: create unordered example file with working references
# e.g. download from ambit, upload
  def test_create_from_ntriples
    d = OpenTox::Dataset.new nil
    d.upload File.join(DATA_DIR,"hamster_carcinogenicity.ntriples")
    assert_equal OpenTox::Dataset, d.class
    assert_equal "hamster_carcinogenicity.ntriples",  d.title 
    assert_equal 1, d.features.size
    assert_equal 76, d.compounds.size
    assert_equal 76, d.data_entries.size
    d.delete 
    assert_equal false, URI.accessible?(d.uri)
  end
=end
  
  def test_head_id
    d = OpenTox::Dataset.new nil
    d.title = "head test"
    d.put
    response = `curl -Lki -H subjectid:#{OpenTox::RestClientWrapper.subjectid} #{d.uri}`
    assert_match /200/, response
    d.delete
  end

  def test_from_xls
    d = OpenTox::Dataset.new
    d.upload "#{DATA_DIR}/hamster_carcinogenicity.xls"
    assert_equal OpenTox::Dataset, d.class
    assert_equal 1, d.features.size
    assert_equal 85, d.compounds.size
    assert_equal 85, d.data_entries.size
    d.delete 
    #assert_equal false, URI.accessible?(d.uri)
  end

end

class DatasetRestTest < MiniTest::Test

  def test_01_get_uri_list
    result = OpenTox::RestClientWrapper.get $dataset[:uri], {}, { :accept => 'text/uri-list', :subjectid => SUBJECTID }
    assert_equal 200, result.code
  end

  # check if default response header is text/uri-list
  def test_02_get_datasetlist_type
    result = OpenTox::RestClientWrapper.get $dataset[:uri], {}, { :accept => 'text/uri-list', :subjectid => SUBJECTID }
    assert_equal "text/uri-list", result.headers[:content_type]
  end

  # check post to investigation service without file
  def test_10_post_dataset_400_no_file
    #result =  OpenTox::RestClientWrapper.post $dataset[:uri], {}, { :subjectid => $pi[:subjectid] }
    #assert_equal 200, result.code
  end

  def test_11_post_dataset
    response =  OpenTox::RestClientWrapper.post $dataset[:uri], {:file => File.join(File.dirname(__FILE__), "data", "hamster_carcinogenicity.csv") }, { :content_type => "text/csv", :subjectid => $pi[:subjectid] }
    assert_equal 200, response.code
    task_uri = response.chomp
    puts task_uri
    task = OpenTox::Task.new task_uri
    task.wait
    uri = task.resultURI
    puts uri
    @@uri = URI(uri)
  end

end

