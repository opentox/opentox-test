require 'test/unit'
require 'csv'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
DATA_DIR = File.join(File.dirname(__FILE__),"data")

begin
  puts "Service URI is: #{$dataset[:uri]}"
rescue
  puts "Configuration Error: $dataset[:uri] is not defined in: " + File.join(ENV["HOME"],".opentox","config","test.rb")
  exit
end

class DatasetLargeTest < Test::Unit::TestCase

  def test_01_upload_epafhm
    f = File.join DATA_DIR, "EPAFHM.csv"
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload f
    csv = CSV.read f
    assert_equal csv.size-1, d.compounds.size
    assert_equal csv.first.size-1, d.features.size
    assert_equal csv.size-1, d.data_entries.size
    d.delete
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_02_upload_multicell
    f = File.join DATA_DIR, "multi_cell_call.csv"
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload f
    csv = CSV.read f
    assert_equal csv.size-1, d.compounds.size
    assert_equal csv.first.size-1, d.features.size
    assert_equal true, d.features.first[RDF.type].include?(RDF::OT.NominalFeature)
    assert_equal 1066, d.data_entries.size
    d.delete
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_03_upload_isscan
    f = File.join DATA_DIR, "ISSCAN-multi.csv"
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload f
    csv = CSV.read f
    assert_equal csv.size-1, d.compounds.size
    assert_equal csv.first.size-1, d.features.size
    assert_equal csv.size-1, d.data_entries.size
    d.delete
    assert_equal false, URI.accessible?(d.uri)
  end

  def test_04_simultanous_upload
    threads = []
    3.times do |t|
      threads << Thread.new(t) do |up|
        d = OpenTox::Dataset.new nil, @@subjectid
        d.upload "#{DATA_DIR}/hamster_carcinogenicity.csv"
        assert_equal OpenTox::Dataset, d.class
        assert_equal 1, d.features.size
        assert_equal 85, d.compounds.size
        assert_equal 85, d.data_entries.size
        csv = CSV.read("#{DATA_DIR}/hamster_carcinogenicity.csv")
        csv.shift
        assert_equal csv.collect{|r| r[1]}, d.data_entries.flatten
        d.delete 
        assert_equal false, URI.accessible?(d.uri)
      end
    end
    threads.each {|aThread| aThread.join}
  end

  def test_05_upload_kazius
    f = File.join DATA_DIR, "kazius.csv"
    d = OpenTox::Dataset.new nil, @@subjectid
    d.upload f
    csv = CSV.read f
    assert_equal csv.size-1, d.compounds.size
    assert_equal csv.first.size-1, d.features.size
    assert_equal csv.size-1, d.data_entries.size
    d.delete
    assert_equal false, URI.accessible?(d.uri)
  end

end
