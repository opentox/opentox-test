=begin
  * File: pc-lazar.rb
  * Purpose: pc-lazar tests
  * Author: Andreas Maunz <andreas@maunz.de>
  * Date: 10/2012
=end

TEST_DIR = File.expand_path(File.dirname(__FILE__))
require_relative "setup.rb"
#require File.join(TEST_DIR,"setup.rb")
#require File.join(TEST_DIR,"helper.rb")
#SHELL_DIR = File.join(TEST_DIR,"shell")
DATA_DIR = File.join(TEST_DIR,"data")

class PcLazarTest < MiniTest::Unit::TestCase
  i_suck_and_my_tests_are_order_dependent!

  def test_01_upload
    @@dataset = OpenTox::Dataset.new nil, @@subjectid
    @@dataset.upload File.join(DATA_DIR,"hamster_carcinogenicity.csv")
    assert_equal @@dataset.uri.uri?, true
  end

  def test_02_pc_fds
    #task_uri = OpenTox::RestClientWrapper.post File.join(@@dataset.uri, "pc"), {:pc_type => "geometrical"}
    #puts task_uri
    #@pc = wait_for_task(task_uri)
    #puts @pc.uri
    #assert_equal @pc.uri.uri?, true
    #mkvar(`bash #{SHELL_DIR}/pc_fds.sh`)
    #puts "pc_fds: '#{ENV['pc_fds']}'"
    #assert_equal ENV['pc_fds'].uri?, true
  end

  def test_02_lazar_pc_model
    lazar = OpenTox::Algorithm.new File.join($algorithm[:uri],"lazar")
    @@model = lazar.run :dataset_uri => @@dataset.uri, :feature_generation_uri => File.join($algorithm[:uri],"pc-descriptors"), :pc_type => "geometrical"
    assert_equal @@model.uri.uri?, true
    puts @@model.uri
  end

  def test_03_lazar_pc_prediction
    prediction_uri = @@model.run :compound_uri => "#{$compound[:uri]}/InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H"
    prediction = OpenTox::Dataset.new prediction_uri, @@subjectid
    assert_equal prediction.uri.uri?, true
    puts prediction.uri
    #mkvar(`bash #{SHELL_DIR}/lazar_p_pc.sh`)
    #puts "lazar_p_pc: '#{ENV['lazar_p_pc']}'"
    #assert_equal ENV['lazar_p_pc'].uri?, true
  end

end
