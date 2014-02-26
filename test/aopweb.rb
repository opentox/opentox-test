require_relative "setup.rb"
#require 'capybara/dsl'
require 'capybara'
require 'capybara-webkit'

Capybara.register_driver :webkit do |app|
  Capybara::Webkit::Driver.new(app).tap{|d| d.browser.ignore_ssl_errors}
end
Capybara.default_driver = :webkit
Capybara.default_wait_time = 20
Capybara.javascript_driver = :webkit
Capybara.run_server = false
Capybara.app_host = 'http://aop.in-silico.ch'

class LazarWebTest < MiniTest::Test
  i_suck_and_my_tests_are_order_dependent!

  include Capybara::DSL

  def test_00_xsetup
    `Xvfb :1 -screen 0 1024x768x16 2>/dev/null &`
    sleep 2
  end

  def test_01_visit
    visit('/')
    assert page.has_content?('PubChem read across')
    assert page.has_content?('This is an experimental version.')
  end
  
  def test_02_inexisting
    visit('/')
    page.fill_in 'name', :with => "blahblah"
    find(:xpath, '/html/body/form/fieldset/input[2]').click
    assert page.has_content?('Could not find a compound with name "blahblah"')
  end

  def test_03_existing
    visit('/')
    page.fill_in 'name', :with => "doxorubicin"
    find(:xpath, '/html/body/form/fieldset/input[2]').click
    sleep 2
    assert page.has_content?('Similar compounds')
  end
  
  def test_99_kill
    `pidof Xvfb|xargs kill`
  end

end
