require_relative "setup.rb"

class LazarPcDescriptorTest < MiniTest::Unit::TestCase

  def test_lazar_pc_descriptors
#=begin
    openbabel_descriptors = OpenTox::RestClientWrapper.get(File.join($algorithm[:uri],"descriptor","openbabel"), :content_type => "text/uri-list").split("\n")
    dataset = OpenTox::Dataset.new nil, SUBJECTID
    dataset.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal dataset.uri.uri?, true

    lazar = OpenTox::Algorithm.new File.join($algorithm[:uri],"lazar")
    model_uri = lazar.run :dataset_uri => dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"descriptor"), :descriptor_uris => openbabel_descriptors#, :pc_type => "geometrical"
    puts model_uri
    model = OpenTox::Model.new model_uri, SUBJECTID
    assert_equal model_uri.uri?, true
#=end

    #model = OpenTox::Model.new "http://localhost:8086/model/3c21f9d6-4bb0-48f2-b796-d610efbc3497"
    prediction_uri = model.run :compound_uri => "#{$compound[:uri]}/InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    prediction = OpenTox::Dataset.new prediction_uri, SUBJECTID
    assert_equal prediction.uri.uri?, true
    puts prediction.uri
    #mkvar(`bash #{SHELL_DIR}/lazar_p_pc.sh`)
    #puts "lazar_p_pc: '#{ENV['lazar_p_pc']}'"
    #assert_equal ENV['lazar_p_pc'].uri?, true
  end

end
