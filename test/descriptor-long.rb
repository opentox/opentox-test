require_relative "setup.rb"

begin
  puts "Service URI is: #{$algorithm[:uri]}"
rescue
  puts "Configuration Error: $algorithm[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class DescriptorLongTest < MiniTest::Test

  def test_dataset_all
    dataset = OpenTox::Dataset.new 
    dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.mini.csv")
    d = OpenTox::Algorithm::Descriptor.physchem dataset
    assert_equal dataset.compounds.size, d.data_entries.size
    assert_equal 316, d.data_entries[0].size
    d.delete
  end

end
