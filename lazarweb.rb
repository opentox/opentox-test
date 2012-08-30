require 'rubygems'
require 'test/unit'
require 'capybara/dsl'
require 'capybara-webkit'

Capybara.default_driver = :webkit
Capybara.default_wait_time = 60
Capybara.javascript_driver = :webkit
Capybara.run_server = false

class LazarWebTest < Test::Unit::TestCase
  include Capybara::DSL
  
  @@uri = "http://lazar.in-silico.ch"
  
  def test_00_start
    `Xvfb :1 -screen 0 1024x768x16 -nolisten inet6 &`
    sleep 2
  end

  def test_01a_visit
    visit(@@uri)
    assert page.has_content?('Lazar Toxicity Predictions')
  end

  def test_01b_validate_html
    visit('http://validator.w3.org/')
    within_fieldset('validate-by-uri') do
      fill_in 'uri', :with => @@uri.to_s
    end
    click_on 'Check'
    assert page.has_content?('This document was successfully checked as XHTML 1.0 Transitional!')
  end

  def test_01c_validate_css
    visit('http://jigsaw.w3.org/css-validator/validator.html.en')
    within_fieldset('validate-by-uri') do
      fill_in 'uri', :with => @@uri.to_s
    end
    click_on 'Check'
    assert page.has_content?('Congratulations! No Error Found.')
  end

  def test_02_check_all_links_exists
    visit(@@uri)
    links = ['Prediction', 'help', 'OpenTox', 'issue tracker', 'JME Editor', 'SMILES', 'Predict', 'in silico toxicology gmbh', 'Validation']
    links.each{|l| assert page.has_link?(l)}
  end

  def test_02_workflow
    visit(@@uri)
    page.fill_in('identifier', :with => "NNc1ccccc1")
    check('model37')
    click_on 'Predict'
    assert page.has_content?('Prediction')
    assert page.has_content?('0.762')
    assert page.has_content?('Confidence')
    assert page.has_content?('0.452')
    click_on 'Details'
    assert page.has_content?('LC50_mmol')
    assert page.has_content?('Neighbors')
  end

  def test_99_kill
    Capybara.reset!
    `pidof Xvfb|xargs kill`
  end

end
