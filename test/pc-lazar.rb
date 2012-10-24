=begin
  * File: pc-lazar.rb
  * Purpose: pc-lazar tests
  * Author: Andreas Maunz <andreas@maunz.de>
  * Date: 10/2012
=end

require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)),"setup.rb")
require File.join(File.expand_path(File.dirname(__FILE__)),"helper.rb")

class AlgorithmTest < Test::Unit::TestCase

  def test_a_upload
    mkvar(`bash shell/upload.sh`)
    puts "ds: '#{ENV['ds']}'"
    assert_equal ENV['ds'].uri?, true
  end

  def test_b1_pc_fds
    mkvar(`bash shell/pc_fds.sh`)
    puts "pc_fds: '#{ENV['pc_fds']}'"
    assert_equal ENV['pc_fds'].uri?, true
  end

  def test_b2_lazar_m_pc
    mkvar(`bash shell/lazar_m_pc.sh`)
    puts "lazar_m_pc: '#{ENV['lazar_m_pc']}'"
    assert_equal ENV['lazar_m_pc'].uri?, true
  end

  def test_b3_lazar_p_pc
    mkvar(`bash shell/lazar_p_pc.sh`)
    puts "lazar_p_pc: '#{ENV['lazar_p_pc']}'"
    assert_equal ENV['lazar_p_pc'].uri?, true
  end

end
