require 'minitest/autorun'
require 'bundler'
Bundler.require
require 'opentox-client'
require File.join(ENV["HOME"],".opentox","config","test.rb")

TEST_DIR = File.expand_path(File.dirname(__FILE__))
DATA_DIR = File.join(TEST_DIR,"data")

@@subjectid = nil
unless $aa[:uri].to_s == ""
  $pi[:subjectid] = OpenTox::Authorization.authenticate($pi[:name], $pi[:password])
  $secondpi[:subjectid] = OpenTox::Authorization.authenticate($secondpi[:name], $secondpi[:password])
  @@subjectid = OpenTox::Authorization.authenticate($aa[:user],$aa[:password])
  unauthorized_error "Failed to authenticate user \"#{$aa[:user]}\"." unless OpenTox::Authorization.is_token_valid(@@subjectid)
end

=begin
class OpenTox::Unit < MiniTest::Unit
  def before_suites
    end
  end

  def after_suites
  end

  def _run_suites(suites, type)
    begin
      before_suites
      super(suites, type)
    ensure
      after_suites
    end
  end

  def _run_suite(suite, type)
    begin
      suite.before_suite
      super(suite, type)
    ensure
      #suite.after_suite
    end
  end
end

class OpenToxMiniTest
  class Unit < MiniTest::Unit

    def before_suites
      # code to run before the first test
      p "Before everything"
    end

    def after_suites
      # code to run after the last test
      p "After everything"
    end

    def _run_suites(suites, type)
      begin
        before_suites
        super(suites, type)
      ensure
        after_suites
      end
    end

    def _run_suite(suite, type)
      begin
        suite.before_suite #if suite.respond_to?(:before_suite)
        super(suite, type)
      ensure
        suite.after_suite if suite.respond_to?(:after_suite)
      end
    end

  end
end

MiniTest::Unit.runner = OpenToxMiniTest::Unit.new
=end


=begin
module OpenTox
  class Test < MiniTest::Test
    #include MiniTest::TestSetupHelper

    def before_suites
      super
      #setup_nested_transactions
      # load any data we want available for all tests
    end

    def after_suites
      #teardown_nested_transactions
      super
    end
  end
end
=end

#MiniTest::Unit.runner = OpenTox::Test.new
