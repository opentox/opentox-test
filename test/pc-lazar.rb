=begin
  * File: pc-lazar.rb
  * Purpose: pc-lazar tests
  * Author: Andreas Maunz <andreas@maunz.de>
  * Date: 10/2012
=end

require 'test/unit'
TEST_DIR = File.expand_path(File.dirname(__FILE__))
require File.join(TEST_DIR,"setup.rb")
require File.join(TEST_DIR,"helper.rb")
SHELL_DIR = File.join(TEST_DIR,"shell")

class AlgorithmTest < Test::Unit::TestCase

  def test_a_upload
    mkvar(`bash #{SHELL_DIR}/upload.sh`)
    puts "ds: '#{ENV['ds']}'"
    assert_equal ENV['ds'].uri?, true
  end

  def test_b1_pc_fds
    mkvar(`bash #{SHELL_DIR}/pc_fds.sh`)
    puts "pc_fds: '#{ENV['pc_fds']}'"
    assert_equal ENV['pc_fds'].uri?, true
  end

  def test_b2_lazar_m_pc
    mkvar(`bash #{SHELL_DIR}/lazar_m_pc.sh`)
    puts "lazar_m_pc: '#{ENV['lazar_m_pc']}'"
    assert_equal ENV['lazar_m_pc'].uri?, true
  end

  def test_b3_lazar_p_pc
    mkvar(`bash #{SHELL_DIR}/lazar_p_pc.sh`)
    puts "lazar_p_pc: '#{ENV['lazar_p_pc']}'"
    assert_equal ENV['lazar_p_pc'].uri?, true
  end

end
