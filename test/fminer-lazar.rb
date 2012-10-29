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
SHELL_DIR = File.join(TEST_DIR,"shell")
DATA_DIR = File.join(TEST_DIR,"data")

class AlgorithmTest < Test::Unit::TestCase

  def test_a_upload
    mkvar(`bash #{SHELL_DIR}/upload.sh`)
    puts "ds: '#{ENV['ds']}'"
    assert_equal ENV['ds'].uri?, true
  end

  def test_b1_lazar_m_bbrc
    mkvar(`bash #{SHELL_DIR}/lazar_m_bbrc.sh`)
    puts "lazar_m_bbrc: '#{ENV['lazar_m_bbrc']}'"
    assert_equal ENV['lazar_m_bbrc'].uri?, true
  end

  def test_b2_lazar_p_bbrc
    mkvar(`bash #{SHELL_DIR}/lazar_p_bbrc.sh`)
    puts "lazar_p_bbrc: #{ENV['lazar_p_bbrc']}`"
    assert_equal ENV['lazar_p_bbrc'].uri?, true
  end

  def test_b3_lazar_ds_bbrc
    mkvar(`bash #{SHELL_DIR}/lazar_ds_bbrc.sh`)
    puts "lazar_ds_bbrc: #{ENV['lazar_ds_bbrc']}`"
    assert_equal ENV['lazar_ds_bbrc'].uri?, true
  end

end
