=begin
  * File: fminer-lazar.rb
  * Purpose: Fminer-lazar tests
  * Author: Andreas Maunz <andreas@maunz.de>
  * Date: 10/2012
=end

require 'test/unit'
TEST_DIR = File.expand_path(File.dirname(__FILE__))
require File.join(TEST_DIR,"setup.rb")
require File.join(TEST_DIR,"helper.rb")
DATA_DIR = File.join(TEST_DIR,"data")

class AlgorithmTest < Test::Unit::TestCase

  def test_01_upload
    @@dataset = OpenTox::Dataset.new nil, @@subjectid
    @@dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    assert_equal @@dataset.uri.uri?, true
    puts @@dataset.uri
  end

  def test_02_lazar_bbrc_model
    lazar = OpenTox::Algorithm.new File.join($algorithm[:uri],"lazar"), @@subjectid
    model_uri =  lazar.run :dataset_uri => @@dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"fminer","bbrc")
    @@model = OpenTox::Model.new model_uri, @@subjectid
    assert_equal @@model.uri.uri?, true
    puts @@model.uri
  end

  def test_03_lazar_bbrc_compound_prediction
    prediction_uri = @@model.run :compound_uri => "#{$compound[:uri]}/InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    prediction = OpenTox::Dataset.new prediction_uri, @@subjectid
    assert_equal prediction.uri.uri?, true
    puts prediction.uri
  end

  def test_04_lazar_bbrc_dataset_prediction
    # make a dataset prediction
    dataset = OpenTox::Dataset.new nil, @@subjectid
    dataset.upload File.join(DATA_DIR,"EPAFHM.mini.csv")
    assert_equal dataset.uri.uri?, true
    prediction_uri = @@model.run :dataset_uri => dataset.uri
    prediction = OpenTox::Dataset.new prediction_uri, @@subjectid
    assert_equal prediction.uri.uri?, true
    puts prediction.uri
  end

end
